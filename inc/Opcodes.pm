package Opcodes;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(write_opcodes write_perl_serializer parse_opdesc write_toy_opclasses group_opcode_numbers group_opcode_attributes);

use Language::P::Constants qw(:all);
use Language::P::Parser::KeywordList;
use Language::P::Keywords;
use Language::P::Parser::OpcodeList;
use Data::Dumper;

sub write_toy_opclasses {
    my( $file ) = @ARGV;

    my %op = %{Language::P::Parser::OpcodeList::parse_opdesc()};
    my %classes = %{Language::P::Parser::OpcodeList::group_opcode_numbers( \%op )};

    open my $out, '>', $file;

    print $out <<'EOT';
package Language::P::Assembly;

use Language::P::Opcodes qw(:all);

sub i {
    my $op = $_[0]->{opcode_n} || -1;

    if( 0 ) {
        # helps code generation
EOT

    while( my( $k, $v ) = each %classes ) {
        printf $out <<'EOT',
    } elsif( %s ) {
        return Language::P::Instruction::%s->new( $_[0] );
EOT
        join( ' || ', map "\$op == $_", @$v ), $k;
    }

    print $out <<'EOT';
    }

    return Language::P::Instruction::Base->new( $_[0] );
}

package Language::P::Instruction::Base;

use parent qw(Language::P::Instruction);

sub     context { $_[0]->{attributes}{context} }
sub     parameters { $_[0]->{parameters} }
sub set_parameters { $_[0]->{parameters} = $_[1] }
sub     arg_count  { $_[0]->{attributes}{arg_count} }
sub     pos        { $_[0]->{pos} }
sub is_jump { 0 }

sub clone {
    my( $self ) = @_;
    my $new_op = Language::P::Assembly::opcode_n( $self->{opcode_n} );

    $new_op->{pos} = $self->{pos} if $self->{pos};
    $new_op->{parameters} = [ @{$self->{paramaters}} ] if $self->{parameters};
    $new_op->{attributes} = { %{$self->{attributes}} } if $self->{attributes};

    return $new_op;
}

EOT

    my %emitted;

    while( my( $k, $v ) = each %op ) {
        my( $attrs, $class ) = ( $v->[3][0], $v->[5] );
        next unless $class && !$emitted{$class};
        $emitted{$class} = 1;

        printf $out <<'EOT',
package Language::P::Instruction::%s;

@Language::P::Instruction::%s::ISA = qw(Language::P::Instruction::Base);

EOT
          $class, $class;

        for( my $i = 0; $i < @$attrs; $i += 2) {
            if(    $attrs->[$i] ne 'context'
                && $attrs->[$i] ne 'arg_count'
                && $attrs->[$i] ne 'class' ) {
                printf $out <<'EOT',
sub     %s { $_[0]->{attributes}{%s} }
sub set_%s { $_[0]->{attributes}{%s} = $_[1] }

EOT
                  $attrs->[$i], $attrs->[$i], $attrs->[$i], $attrs->[$i];
            }
        }
    }

    print $out <<'EOT';

# TODO refactor jump opcode handling

package Language::P::Instruction::Jump;

sub set_false { $_[0]->{attributes}{false} = $_[1] }
sub     false { $_[0]->{attributes}{false} }
sub set_true { $_[0]->{attributes}{true} = $_[1] }
sub     true { $_[0]->{attributes}{true} }
sub is_jump  { 1 }

package Language::P::Instruction::Phi;

@Language::P::Instruction::Phi::ISA = qw(Language::P::Instruction::GetSet);

package Language::P::Instruction::RegexQuantifier;

sub     false { $_[0]->{attributes}{false} }
sub     true { $_[0]->{attributes}{true} }

1;
EOT
}

sub write_opcodes {
    my( $file ) = @ARGV;

    my %op = %{Language::P::Parser::OpcodeList::parse_opdesc()};
    my %kw = %{(Language::P::Parser::KeywordList::parse_table())[0]};
    my %op_key_map;

    open my $out, '>', $file;

    printf $out <<'EOT';
package Language::P::Opcodes;

use Exporter 'import';
use Language::P::Keywords qw(:all);

our @OPERATIONS;
BEGIN {
    @OPERATIONS = ( qw(
EOT

    foreach my $k ( sort keys %op ) {
        print $out "$k\n";
    }

    printf $out <<'EOT';
    ) );
}

our @EXPORT = ( qw(%%KEYWORD_TO_OP %%OP_TO_KEYWORD %%NUMBER_TO_NAME @OPERATIONS
                   %%OP_ATTRIBUTES %%PROTOTYPE), @OPERATIONS );
our %%EXPORT_TAGS =
  ( all => \@EXPORT,
    );

use constant +
  { FLAG_UNARY    => 1,
    FLAG_VARIADIC => 2,
EOT

    my $index = 1;
    foreach my $k ( sort keys %op ) {
        print $out <<EOT;
    $k => $index,
EOT
        ++$index;
    }

    printf $out <<'EOT';
    };

our %%NUMBER_TO_NAME =
  (
EOT

    while( my( $k, $v ) = each %op ) {
        printf $out <<'EOT', $k, $v->[0];
    %s() => '%s',
EOT
    }

    printf $out <<'EOT';
    );

our %%KEYWORD_TO_OP =
  (
EOT

    foreach my $k ( sort @OVERRIDABLES, @BUILTINS ) {
        ( my $o = $k ) =~ s/KEY_/OP_/;
        $o =~ s/^OP_(PUSH|POP|SHIFT|UNSHIFT)/OP_ARRAY_$1/;
        $op_key_map{$o} = $k;
        printf $out <<'EOT', $k, $o;
    %s() => %s(),
EOT
    }

    printf $out <<'EOT';
    );

our %%OP_TO_KEYWORD = reverse %%KEYWORD_TO_OP;

our %%OP_ATTRIBUTES =
  (
EOT

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    while( my( $k, $v ) = each %op ) {
        my $named = Dumper( $v->[3][1] );
        printf $out <<'EOT',
    %s() =>
      { in_args    => %d,
        out_args   => %d,
        named      => %s,
        flags      => %d,
        },
EOT
            $k, $v->[1], $v->[2], $named, $v->[4];
    }

    my( $any, $topic, $mkglob ) =
      ( PROTO_ANY, PROTO_DEFAULT_ARG, PROTO_MAKE_GLOB );

    printf $out <<'EOT', $any;
    );

our %%PROTOTYPE =
  (
    OP_DO_FILE() =>
        [  1,  1, 0, %d ],
EOT

    foreach my $ft ( grep /^OP_FT/, keys %op ) {
        printf $out <<'EOT', $ft, $topic, $mkglob;
    %s() =>
        [ 1, 1, %d, %d ],
EOT
    }

    my %attrs = map { $_->[1] => $_ } values %kw;

    while( my( $op, $key ) = each %op_key_map ) {
        my $attr = $attrs{$key} or die "Unknown builtin '$key'";
        my $cxt = join ', ', @{$attr->[5]};

        printf $out <<'EOT',
    %s() =>
        [ %d, %d, %d, %s ],
EOT
            $op, $attr->[2], $attr->[3], $attr->[4], $cxt;
    }

    printf $out <<'EOT',
    );

our %%CONTEXT =
  (
    OP_DO_FILE() =>
        [ %d ],
    OP_RETURN() =>
        [ %d ],
    OP_DYNAMIC_GOTO() =>
        [ %d ],
    OP_DEFINED() =>
        [ %d ],
EOT
        CXT_SCALAR, CXT_CALLER, CXT_SCALAR, CXT_SCALAR|CXT_NOCREATE;

    foreach my $ft ( grep /^OP_FT/, keys %op ) {
        printf $out <<'EOT', $ft, CXT_SCALAR;
    %s() =>
        [ %d ],
EOT
    }

    while( my( $op, $key ) = each %op_key_map ) {
        next if    $op eq 'OP_DO_FILE'
                || $op eq 'OP_RETURN'
                || $op eq 'OP_DYNAMIC_GOTO'
                || $op eq 'OP_DEFINED';
        my $attr = $attrs{$key} or die "Unknown builtin '$key'";
        my @cxt;
        foreach my $a ( @{$attr->[5]} ) {
            if(    $a == PROTO_ARRAY || $a == PROTO_MAKE_ARRAY
                || $a == ( PROTO_MAKE_ARRAY|PROTO_REFERENCE ) ) {
                push @cxt, CXT_LIST;
            } elsif(    $a == PROTO_HASH || $a == PROTO_MAKE_HASH
                     || $a == ( PROTO_MAKE_HASH|PROTO_REFERENCE ) ) {
                push @cxt, CXT_LIST;
            } elsif( $a & PROTO_REFERENCE ) {
                push @cxt, CXT_SCALAR;
            } else {
                push @cxt, CXT_SCALAR;
            }
        }
        my $cxt = join ', ', @cxt;

        printf $out <<'EOT',
    %s() =>
        [ %s ],
EOT
            $op, $cxt;
    }

    printf $out <<'EOT';
    );

1;
EOT

}

sub write_perl_serializer {
    my( $file ) = @ARGV;

    my %op = %{Language::P::Parser::OpcodeList::parse_opdesc()};

    open my $out, '>', $file;

    print $out <<'EOT';
package Language::P::Intermediate::Serialize;

use strict;
use warnings;

sub _write_op {
    my( $self, $out, $op ) = @_;
    my $opn = $op->{opcode_n};

    print $out pack 'v', $opn;
    _write_pos( $self, $out, $op->pos );

    if( 0 ) {
        # simplifies code generation below
    }
EOT

    while( my( $k, $v ) = each %op ) {
        my $attrs = $v->[3][0];
        next unless @$attrs;

        print $out sprintf <<'EOT', $k;
    elsif( $opn == %s ) {
EOT

        for( my $i = 0; $i < @$attrs; $i += 2 ) {
            my $type = $attrs->[$i + 1];
            my $name = $attrs->[$i];
            next if $name eq 'arg_count';
            if( $type eq 's' ) {
                print $out sprintf <<'EOT', $name;
        _write_string( $out, $op->{attributes}{%s} );
EOT
            } elsif( $type eq 'su' ) {
                print $out sprintf <<'EOT', $name;
        _write_string_undef( $out, $op->{attributes}{%s} );
EOT
            } elsif( $type eq 'i' || $type eq 'i4' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'V', $op->{attributes}{%s};
EOT
            } elsif( $type eq 'f' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'd', $op->{attributes}{%s};
EOT
            } elsif( $type eq 'i1' || $type eq 'i_sigil' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'C', $op->{attributes}{%s};
EOT
            } elsif( $type eq 'b' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'V', $self->{bb_map}{$op->{attributes}{%s}};
EOT
            } elsif( $type eq 'c' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'V', $self->{sub_map}{$op->{attributes}{%s}};
EOT
            } elsif( $type eq 'ls' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'V', $self->{li_map}{$op->{attributes}{%s} . '|0'};
EOT
            } elsif( $type eq 'lp' ) {
                print $out sprintf <<'EOT', $name;
        print $out pack 'V', $self->{li_map}{$op->{attributes}{%s} . '|1'};
EOT
            }
        }

        print $out <<'EOT';
    }
EOT

    }

    print $out <<'EOT';

    if( $op->{parameters} ) {
        print $out pack 'V', scalar @{$op->{parameters}};
        _write_op( $self, $out, $_ ) foreach @{$op->{parameters}};
    } else {
        print $out pack 'V', 0;
    }
}

1;
EOT

}

1;
