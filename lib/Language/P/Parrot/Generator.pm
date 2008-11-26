package Language::P::Parrot::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_accessors( qw(file_name) );
__PACKAGE__->mk_ro_accessors( qw(parrot _body _onload _body_segments
                                 _lexical_map _global_allocated) );

use Language::P::ParseTree qw(:all);
use Language::P::Assembly qw(:all);

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
    'Language::P::ParseTree::NamedSubroutine'        => '_named_subroutine',
    'Language::P::ParseTree::LexicalDeclaration'     => '_lexical_declaration',
    'Language::P::ParseTree::LexicalSymbol'          => '_lexical_symbol',
    'Language::P::ParseTree::Conditional'            => '_cond',
    'Language::P::ParseTree::Block'                  => '_block',
    'Language::P::ParseTree::Builtin'                => '_builtin',
    'Language::P::ParseTree::FunctionCall'           => '_function_call',
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

my %unary_op =
  ( OP_MINUS()           => '',
    OP_LOG_NOT()         => '',
    OP_REFERENCE()       => '',
    VALUE_SCALAR()       => '',
    VALUE_ARRAY_LENGTH() => '',
    OP_BACKTICK()        => '',
    );

my %binary_op =
  ( OP_SUBTRACT()        => 'sub',
    OP_ADD()             => 'add',
    );

my %builtins =
  ( return               => 'magic',
    );

my $local = 0;
sub _local_name { sprintf "loc%d", ++$local }
my $constant = 0;
sub _const_name { sprintf "const%d", ++$constant }
my $label = 0;
sub _label_name { sprintf "lbl%d", ++$label }
sub local_pmc { literal( sprintf '  .local pmc %s', $_[0] ) }

sub method_map { \%method_map }

sub _confess {
    my( $self, $tree ) = @_;

    Carp::confess( ref( $tree ) );
}

sub _add {
    my( $self, @insns ) = @_;

    push @{$self->{_body}}, @insns;
}

sub start_code_generation {
    my( $self ) = @_;

    $self->{_body} = [];
    $self->{_onload} = [];
    $self->{_body_segments} = [ $self->{_body} ];
    $self->{_lexical_map} = {};
    $self->{_global_allocated} = {};

    _add $self,
         literal( ".HLL 'P5'" ),
         literal( ".loadlib 'support/parrot/runtime/p5runtime.pbc'" ),
         literal( ".include 'support/parrot/runtime/p5macros.pir'" ),
         literal( ".HLL_map 'Integer' = 'P5Integer'" ),
         literal( ".HLL_map 'String' = 'P5String'" ),
         literal( ".namespace ['main']" ),
         literal( ".sub main :main" );
    push @{$self->_onload},
         literal( "  load_bytecode 'support/parrot/runtime/p5runtime.pbc'" ),
         literal( "  .local pmc sym" );
}

sub end_code_generation {
    my( $self ) = @_;

    open my $out, '| ' . $self->parrot . ' -L support/parrot --output-pbc -o ' .
                         $self->file_name . ' -' or die $!;
    _add $self, literal( '.end' );

    foreach my $sub ( @{$self->_body_segments} ) {
        print $out $_->as_string foreach @$sub;
    }

    print $out ".sub on_load :init :load\n";
    print $out $_->as_string foreach @{$self->_onload};
    print $out ".end\n";

    close $out;

    return $self->file_name;
}

sub add_declaration {
    my( $self, $name ) = @_;

    # needs to pass-through to a Toy runtime when bootstrapping
}

sub process {
    my( $self, $tree ) = @_;

    $self->visit( $tree );
}

sub _indirect {
    my( $self, $tree ) = @_;

    my @names = map $self->visit( $_ ), @{$tree->arguments || []};

    if( $tree->function eq 'print' ) {
        foreach my $name ( @names ) {
            _add $self,
                 opcode( 'print', $name );
        }
    }
}

sub _constant {
    my( $self, $tree ) = @_;

    if( $tree->is_string ) {
        my $const = _const_name;
        my $str = $tree->value;
        $str =~ s/([^\x20-\x7f])/sprintf "\\x%02x", ord $1/eg;
        _add $self,
             local_pmc( $const ),
             literal( sprintf '  .make_string(%s, "%s")', $const, $str );

        return $const;
    } elsif( $tree->is_number ) {
        my $const = _const_name;
        my $int = $tree->value;
        _add $self,
             local_pmc( $const ),
             literal( sprintf '  .make_integer(%s, %s)', $const, $int );

        return $const;
    }
}

sub _unary_op {
    my( $self, $tree ) = @_;

    my $v = $self->visit( $tree->left );

    if( $tree->op == VALUE_ARRAY_LENGTH ) {
        my( $res, $int ) = ( _local_name, _local_name );
        _add $self,
             local_pmc( $res ),
             literal( sprintf '  .local int %s', $int ),
             opcode( 'set', $int, $v ),
             opcode( 'sub', $int, $int, 1 ),
             literal( sprintf '  .make_integer(%s, %s)', $res, $int );

        return $res;
    } else {
        die $tree->op;
    }
}

sub _binary_op {
    my( $self, $tree ) = @_;

    if( $tree->op == OP_ASSIGN ) {
        my $l = $self->visit( $tree->left );
        my $r = $self->visit( $tree->right );

        _add $self, opcode( 'assign', $l, $r );

        return $l;
    } else {
        die "No op for " . $tree->op unless $binary_op{$tree->op};

        my( $res, $resr ) = ( _local_name, _local_name );
        my $l = $self->visit( $tree->left );
        my $r = $self->visit( $tree->right );

        _add $self,
             local_pmc( $res ),
             local_pmc( $resr ),
             opcode( $binary_op{$tree->op}, $res, $l, $r ),
             opcode( 'new', $resr, "'Ref'" ),
             opcode( 'assign', $resr, $res );

        return $resr;
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
    _add $self, opcode( $conditionals{$tree->op}, $l, $r, $false );
}

sub _anything_cond {
    my( $self, $tree, $true, $false ) = @_;

    my $v = $self->visit( $tree );
    # jump to $false if false, fall trough if true
    _add $self, opcode( 'unless', $v, $false );
}

sub _list {
    my( $self, $tree ) = @_;

    return _make_list( $self, $tree->expressions );
}

sub _make_list {
    my( $self, $expressions ) = @_;

    my $thelist = _local_name;
    _add $self,
         local_pmc( $thelist ),
         opcode( 'new', $thelist, '"P5List"' );

    my @v;
    foreach my $arg ( @$expressions ) {
        push @v, $self->visit( $arg );
    }

    _add $self, opcode( 'push', $thelist, $_ ) foreach @v;

    return $thelist;
}

sub _add_global {
    my( $self, $name, $bytecode ) = @_;
    my $qname = sprintf "'%s'", $name;

    my $goto_ok = _label_name;
    push @{$self->_onload},
         opcode( 'get_root_global', 'sym', '["main"]', $qname ),
         opcode( 'unless_null', 'sym', $goto_ok ),
         @$bytecode,
         opcode( 'set_root_global', '["main"]', $qname, 'sym' ),
         label( $goto_ok );
}

sub _symbol {
    my( $self, $tree ) = @_;

    my $symbol = _local_name;
    my $qname = sprintf "'%s'", $tree->name;
    _add $self,
         local_pmc( $symbol ),
         opcode( 'get_root_global', $symbol, '["main"]', $qname );

    if( !$self->_global_allocated->{$tree->name} && $tree->sigil != VALUE_SUB ) {
        $self->_global_allocated->{$tree->name} = 1;
        _add_global( $self, $tree->name,
                     [ literal( '  .make_undef(sym)' ) ] );
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
    _add $self,
         local_pmc( $res ),
         literal( sprintf '  .make_string(%s, "")', $res );

    foreach my $e ( @{$tree->components} ) {
        my $ev = $self->visit( $e );
        _add $self, opcode( 'concat', $res, $ev );
    }

    return $res;
}

sub _ternary {
    my( $self, $tree ) = @_;

    my $res = _local_name;
    _add $self, local_pmc( $res );
    my( $end, $true, $false ) = ( _label_name, _label_name, _label_name );
    $self->visit_map( \%method_map_cond, $tree->condition, $true, $false );
    _add $self, label( $true );
    my $t = $self->visit( $tree->iftrue );
    _add $self,
         opcode( 'set', $res, $t ),
         opcode( 'goto', $end ),
         label( $false );
    my $f = $self->visit( $tree->iffalse );
    _add $self,
         opcode( 'set', $res, $f ),
         label( $end );

    return $res;
}

sub _named_subroutine {
    my( $self, $tree ) = @_;
    my $old_body = $self->{_body};
    push @{$self->_body_segments}, ( $self->{_body} = [] );

    _add $self,
         literal( sprintf '.sub %s :outer(main)', $tree->name ),
         literal( '  .param pmc args' ); # XXX :slurpy

    foreach my $line ( @{$tree->lines} ) {
        $self->visit( $line );
    }

    _add $self,
         literal( '.end' );

    $self->{_body} = $old_body;

    my $cs = _const_name;
    _add_global( $self, $tree->name,
                 [ literal( sprintf '  .const "Sub" %s = "%s"', $cs,
                            $tree->name ),
                   opcode( 'set', 'sym', $cs ),
                   ] );
}

sub _lexical_symbol {
    my( $self, $tree ) = @_;

    die "No closures yet" if $tree->declaration->closed_over;
    unless( $self->_lexical_map->{$tree->declaration} ) {
        # params array
        if( $tree->declaration->name eq '_' ) {
            $self->_lexical_map->{$tree->declaration} = 'args';
        } else {
            die "Can't have symbol without declaration";
        }
    }

    return $self->_lexical_map->{$tree->declaration};
}

sub _lexical_declaration {
    my( $self, $tree ) = @_;

    die "No closures yet" if $tree->closed_over;
    my $res = _local_name;

    _add $self,
         literal( "  # $res = " . $tree->name ),
         local_pmc( $res ),
         literal( sprintf '  .make_undef(%s)', $res );

    $self->_lexical_map->{$tree} = $res;

    return $res;
}

sub _block {
    my( $self, $tree ) = @_;

    foreach my $line ( @{$tree->lines} ) {
        $self->visit( $line );
    }
}

sub _cond {
    my( $self, $tree ) = @_;

    my $end_cond = _label_name;
    foreach my $elsif ( @{$tree->iftrues} ) {
        my $is_unless = $elsif->block_type eq 'unless';
        my( $then_block, $else_block ) = ( _label_name, _label_name );
        $self->visit_map( \%method_map_cond, $elsif->condition,
                          $is_unless ? ( $else_block, $then_block ) :
                                       ( $then_block, $else_block ) );
        _add $self, label( $then_block );
        $self->visit( $elsif->block );
        _add $self,
             opcode( 'goto', $end_cond ),
             label( $else_block );
    }
    if( $tree->iffalse ) {
        $self->visit( $tree->iffalse->block );
    }
    _add $self, label( $end_cond );
}

sub _builtin {
    my( $self, $tree ) = @_;

    if( $tree->function eq 'undef' && !$tree->arguments ) {
#         _emit_label( $self, $tree );
#         push @bytecode, o( 'constant',
#                            value => Language::P::Toy::Value::StringNumber->new );
#     } elsif( $builtins_no_list{$tree->function} ) {
#         _emit_label( $self, $tree );
#         foreach my $arg ( @{$tree->arguments || []} ) {
#             $self->dispatch( $arg );
#         }

#         push @bytecode, o( $builtins_no_list{$tree->function} );
    } else {
        return _function_call( $self, $tree );
    }
}

sub _function_call {
    my( $self, $tree ) = @_;
#     _emit_label( $self, $tree );

#     push @bytecode, o( 'start_list' );

    my $args = _make_list( $self, $tree->arguments || [] );

#     push @bytecode, o( 'end_list' );

    Carp::confess( "Unknown '" . $tree->function . "'" )
        unless ref( $tree->function ) || $builtins{$tree->function};

    my $res = _local_name;
    _add $self, local_pmc( $res );
    if( ref( $tree->function ) ) {
        my $f = $self->visit( $tree->function );
        _add $self,
             literal( '  .begin_call' ),
             literal( sprintf '    .set_arg %s', $args ), # XXX :flat
             literal( sprintf '    .call %s', $f ),
             literal( sprintf '    .result %s', $res ),
             literal( '  .end_call' );
    } else {
        if( $tree->function eq 'return' ) {
            my( $int, $nonzero, $end ) = ( _local_name, _label_name,
                                           _label_name );

            _add $self,
                 literal( sprintf '  .local int %s', $int ),
                 opcode( 'elements', $int, $args ),
                 opcode( 'ne', $int, 0, $nonzero ),
                 literal( sprintf '  .make_undef(%s)', $args ),
                 opcode( 'goto', $end ),
                 label( $nonzero ),
                 opcode( 'set', $args, "$args\[0\]" ),
                 label( $end ),
                 literal( sprintf '  .return (%s)', $args );
            return;
        }
        die;
#         push @bytecode, o( $builtins{$tree->function} );
    }

    return $res;
}

1;
