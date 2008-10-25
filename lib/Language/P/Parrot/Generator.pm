package Language::P::Parrot::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_accessors( qw(file_name) );
__PACKAGE__->mk_ro_accessors( qw(parrot _out) );

use Language::P::ParseTree qw(:all);

my %method_map =
  ( DEFAULT                                          => '_confess',
    'Language::P::ParseTree::BuiltinIndirect'        => '_indirect',
    'Language::P::ParseTree::Constant'               => '_constant',
    'Language::P::ParseTree::BinOp'                  => '_binary_op',
    'Language::P::ParseTree::UnOp'                   => '_unary_op',
    'Language::P::ParseTree::List'                   => '_list',
    'Language::P::ParseTree::Symbol'                 => '_symbol',
    'Language::P::ParseTree::QuotedString'           => '_quoted_string',
    'Language::P::ParseTree::Ternary'                => '_ternary',
    );

my %method_map_cond =
  ( 'Language::P::ParseTree::BinOp'                  => '_binary_op_cond',
    'DEFAULT'                                        => '_anything_cond',
    );

# use negation, because we want to jump if false
my %conditionals =
  ( OP_NUM_LT() => 'ge_num',
    OP_STR_LT() => 'ge_str',
    OP_NUM_GT() => 'le_num',
    OP_STR_GT() => 'le_str',
    OP_NUM_LE() => 'gt_num',
    OP_STR_LE() => 'gt_str',
    OP_NUM_GE() => 'lt_num',
    OP_STR_GE() => 'lt_str',
    OP_NUM_EQ() => 'ne_num',
    OP_STR_EQ() => 'ne_str',
    OP_NUM_NE() => 'eq_num',
    OP_STR_NE() => 'eq_str',
    );

my %short_circuit =
  ( OP_LOG_AND() => 0,
    OP_LOG_OR()  => 1,
    );

my %unary =
  ( OP_MINUS()           => '',
    OP_LOG_NOT()         => '',
    OP_REFERENCE()       => '',
    VALUE_SCALAR()       => '',
    VALUE_ARRAY_LENGTH() => '',
    OP_BACKTICK()        => '',
    );

my $local = 0;
sub _local_name { sprintf "loc%d", ++$local }
my $constant = 0;
sub _const_name { sprintf "const%d", ++$constant }
my $label = 0;
sub _label_name { sprintf "lbl%d", ++$label }

sub method_map { \%method_map }

sub _confess {
    my( $self, $tree ) = @_;

    Carp::confess( ref( $tree ) );
}

# FIXME
my $on_load = '';

sub start_code_generation {
    my( $self ) = @_;

    open my $out, '| ' . $self->parrot . ' -L support/parrot --output-pbc -o ' .
                         $self->file_name . ' -' or die $!;
    $self->{_out} = $out;
#    $self->{_out} = \*STDOUT;

    print {$self->_out} ".HLL 'P5', ''\n";
    print {$self->_out} ".loadlib 'support/parrot/runtime/p5runtime.pbc'\n";
    print {$self->_out} ".HLL_map 'Integer', 'P5Integer'\n";
    print {$self->_out} ".HLL_map 'String', 'P5String'\n";
    print {$self->_out} ".sub main :main\n";
    $on_load .= "  load_bytecode 'support/parrot/runtime/p5runtime.pbc'\n";
    $on_load .= "  .local pmc sym\n";
}

sub end_code_generation {
    my( $self ) = @_;

    print {$self->_out} ".end\n";
    print {$self->_out} ".sub on_load :init :load\n";
    print {$self->_out} $on_load;
    print {$self->_out} ".end\n";

    close $self->_out;

    return $self->file_name;
}

sub process {
    my( $self, $tree ) = @_;

#     use Data::Dumper;
#     print Dumper $tree;

    $self->visit( $tree );
}

sub _indirect {
    my( $self, $tree ) = @_;

    my @names = map $self->visit( $_ ), @{$tree->arguments || []};

    if( $tree->function eq 'print' ) {
        foreach my $name ( @names ) {
            print {$self->_out} "  print $name\n";
        }
    }
}

sub _constant {
    my( $self, $tree ) = @_;

    if( $tree->is_string ) {
        my $const = _const_name;
        my $str = $tree->value;
        $str =~ s/([^\x20-\x7f])/sprintf "\\x%02x", ord $1/eg;
        printf {$self->_out} "  .local pmc %s\n", $const;
        printf {$self->_out} "  %s = new 'P5String'\n", $const;
        printf {$self->_out} "  set %s, \"%s\"\n", $const, $str;
#        printf "  .const string %s = \"%s\"\n", $const, $str;

        return $const;
    } elsif( $tree->is_number ) {
        my $const = _const_name;
        my $int = $tree->value;
        printf {$self->_out} "  .local pmc %s\n", $const;
        printf {$self->_out} "  %s = new 'P5Integer'\n", $const;
        printf {$self->_out} "  set %s, %s\n", $const, $int;
#        printf "  .const int %s = %s\n", $const, $int;

        return $const;
    }
}

sub _unary_op {
    my( $self, $tree ) = @_;

    my $v = $self->visit( $tree->left );

    if( $tree->op == VALUE_ARRAY_LENGTH ) {
        my( $res, $int ) = ( _local_name, _local_name );
        printf {$self->_out} "  .local pmc %s\n", $res;
        printf {$self->_out} "  .local int %s\n", $int;
        printf {$self->_out} "  %s = %s\n", $int, $v;
        printf {$self->_out} "  %s = %s - 1\n", $int, $int;
        printf {$self->_out} "  %s = new 'P5Integer'\n", $res;
        printf {$self->_out} "  %s = %s\n", $res, $int;

        return $res;
    } else {
        die $tree->op;
    }
}

sub _binary_op {
    my( $self, $tree ) = @_;

    if(    $tree->op == OP_ASSIGN
        && $tree->left->isa( 'Language::P::ParseTree::List' )
        ) {
        my $l = $self->visit( $tree->left );
        my $r = $self->visit( $tree->right );

        printf {$self->_out} "  assign %s, %s\n", $l, $r;
    } else {
        my $l = $self->visit( $tree->left );
        my $r = $self->visit( $tree->right );

        printf {$self->_out} "  assign %s, %s\n", $l, $r;

        return $r;
    }
}

sub _binary_op_cond {
    my( $self, $tree, $true, $false ) = @_;

    if( !exists $conditionals{$tree->op} ) {
        _anything_cond( $self, $tree, $true, $false );

        return;
    }

    my $l = $self->visit( $tree->left );
    my $r = $self->visit( $tree->right );

    # jump to $false if false, fall trough if true
    printf {$self->_out} " %s %s, %s, %s\n", $conditionals{$tree->op},
                         $l, $r, $false;
}

sub _anything_cond {
    my( $self, $tree, $true, $false ) = @_;

    my $v = $self->visit( $tree );
    # jump to $false if false, fall trough if true
    printf {$self->_out} "  unless %s goto %s\n", $v, $false;
}

sub _list {
    my( $self, $tree ) = @_;

    my $thelist = _local_name;
    printf {$self->_out} "  .local pmc %s\n", $thelist;
    printf {$self->_out} "  %s = new 'P5List'\n", $thelist;

    my @v;
    foreach my $arg ( @{$tree->expressions} ) {
        push @v, $self->visit( $arg );
    }

    printf {$self->_out} "  push %s, %s\n", $thelist, $_ foreach @v;

    return $thelist;
}

# FIXME
my %created;

sub _symbol {
    my( $self, $tree ) = @_;

    my $symbol = _local_name;
    printf {$self->_out} "  .local pmc %s\n", $symbol;
    printf {$self->_out} "  %s = get_root_global ['main'], '%s'\n", $symbol, $tree->name;

    if( !$created{$tree->name} ) {
        $created{$tree->name} = 1;
        my $goto_ok = _label_name;
        $on_load .= sprintf "  sym = get_root_global ['main'], '%s'\n", $tree->name;
        $on_load .= sprintf "  unless_null sym, %s\n", $goto_ok;
        $on_load .= sprintf "  sym = new 'P5Undef'\n";
        $on_load .= sprintf "  set_root_global ['main'], '%s', sym\n", $tree->name;
        $on_load .= sprintf "%s:\n", $goto_ok;
    }

    return $symbol;
}

sub _quoted_string {
    my( $self, $tree ) = @_;

    if( @{$tree->components} == 1 ) {
        my $temp = $self->visit( $tree->components->[0] );
        my( $ret, $tmp ) = ( _local_name, _local_name );

        die "XXXX";

        return $ret;
    }

    my $res = _local_name;
    printf {$self->_out} "  .local pmc %s\n", $res;
    printf {$self->_out} "  %s = new 'P5String'\n", $res;

    foreach my $e ( @{$tree->components} ) {
        my $ev = $self->visit( $e );
        printf {$self->_out} "  concat %s, %s\n", $res, $ev;
    }

    return $res;
}

sub _ternary {
    my( $self, $tree ) = @_;

    my $res = _local_name;
    printf {$self->_out} "  .local pmc %s\n", $res;
    my( $end, $true, $false ) = ( _label_name, _label_name, _label_name );
    $self->visit_map( \%method_map_cond, $tree->condition, $true, $false );
    printf {$self->_out} "%s:\n", $true;
    my $t = $self->visit( $tree->iftrue );
    printf {$self->_out} "  %s = %s\n", $res, $t;
    printf {$self->_out} "  goto %s\n", $end;
    printf {$self->_out} "%s:\n", $false;
    my $f = $self->visit( $tree->iffalse );
    printf {$self->_out} "  %s = %s\n", $res, $f;
    printf {$self->_out} "%s:\n", $end;

    return $res;
}

1;
