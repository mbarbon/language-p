package Language::P::Generator;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(runtime) );

use Language::P::Opcodes;
use Language::P::Value::StringNumber;
use Language::P::Value::Handle;
use Language::P::Value::ScratchPad;

# HACK
our @bytecode;
our %labels;
our %patch;
our $label_count = 0;

sub _new_label {
    ++$label_count;
    $labels{$label_count} = undef;

    return $label_count;
}

sub _set_label {
    my( $label, $to ) = @_;

    die if $labels{$label};
    $labels{$label} = $to;

    $_->{to} = $to foreach @{$patch{$label} || []};
    delete $patch{$label};
}

sub _to_label {
    my( $label, $op ) = @_;

    return $labels{$label} if $labels{$label};
    push @{$patch{$label} ||= []}, $op;
}

my @codes;

sub push_code {
    my( $self, $code ) = @_;

    push @codes, $code;

    # TODO do not use global
    *bytecode = $code->bytecode;
}

sub pop_code {
    my( $self, $code ) = @_;

    pop @codes;

    # TODO do not use global
    *bytecode = @codes ? $codes[-1]->bytecode : [];
}

sub process {
    my( $self, $tree ) = @_;

#     use Data::Dumper;
#     print Dumper( $tree );
    $self->dispatch( $tree );

    return;
}

sub finished {
    my( $self ) = @_;

    $self->_allocate_lexicals;

    if( $codes[-1]->isa( 'Language::P::Value::Subroutine' ) ) {
        push @bytecode, { function => \&Language::P::Opcodes::o_return };
    } else {
        push @bytecode, { function => \&Language::P::Opcodes::o_end };
    }
}

my %dispatch =
  ( FunctionCall           => '_function_call',
    BinOp                  => '_binary_op',
    Constant               => '_constant',
    Symbol                 => '_symbol',
    LexicalDeclaration     => '_lexical_declaration',
    LexicalSymbol          => '_lexical_declaration',
    List                   => '_list',
    Conditional            => '_cond',
    Block                  => '_block',
    Subroutine             => '_subroutine',
    );

my %dispatch_cond =
  ( FunctionCall   => '_function_call',
    BinOp          => '_binary_op_cond',
    Constant       => '_constant',
    Symbol         => '_symbol',
    List           => '_list',
    );

sub dispatch {
    my( $self, $tree ) = @_;
    ( my $pack = ref $tree ) =~ s/^.*:://;
    my $meth = $dispatch{$pack};

#     use Data::Dumper;
#     print Dumper( $tree );
    Carp::confess( $pack ) unless $meth;

    $self->$meth( $tree );
}

sub dispatch_cond {
    my( $self, $tree, $true, $false ) = @_;
    ( my $pack = ref $tree ) =~ s/^.*:://;
    my $meth = $dispatch_cond{$pack};

#     use Data::Dumper;
#     print Dumper( $tree );
    die $pack unless $meth;

    $self->$meth( $tree, $true, $false );
}

my %reverse_conditionals =
  ( '<'      => '>=',
    '>'      => '<=',
    '<='     => '>',
    '>='     => '<',
    '=='     => '!=',
    '!='     => '==',
    );

my %conditionals =
  ( '<'      => \&Language::P::Opcodes::o_compare_i_lt_int,
    'lt'     => \&Language::P::Opcodes::o_compare_s_lt_int,
    '>'      => \&Language::P::Opcodes::o_compare_i_gt_int,
    'gt'     => \&Language::P::Opcodes::o_compare_s_gt_int,
    '<='     => \&Language::P::Opcodes::o_compare_i_le_int,
    'le'     => \&Language::P::Opcodes::o_compare_s_le_int,
    '>='     => \&Language::P::Opcodes::o_compare_i_ge_int,
    'ge'     => \&Language::P::Opcodes::o_compare_s_ge_int,
    '=='     => \&Language::P::Opcodes::o_compare_i_eq_int,
    'eq'     => \&Language::P::Opcodes::o_compare_s_eq_int,
    '!='     => \&Language::P::Opcodes::o_compare_i_ne_int,
    'ne'     => \&Language::P::Opcodes::o_compare_s_ne_int,
    );

my %short_circuit =
  ( '&&'     => \&Language::P::Opcodes::o_jump_if_false,
    '||'     => \&Language::P::Opcodes::o_jump_if_true,
    );

my %builtins =
  ( print    => \&Language::P::Opcodes::o_print,
    return   => \&Language::P::Opcodes::o_return,
    %short_circuit,
    '+'      => \&Language::P::Opcodes::o_add,
    '*'      => \&Language::P::Opcodes::o_multiply,
    '-'      => \&Language::P::Opcodes::o_subtract,
    '='      => \&Language::P::Opcodes::o_assign,
    '=='     => \&Language::P::Opcodes::o_compare_i_eq_scalar,
    'eq'     => \&Language::P::Opcodes::o_compare_s_eq_scalar,
    '!='     => \&Language::P::Opcodes::o_compare_i_ne_scalar,
    'ne'     => \&Language::P::Opcodes::o_compare_s_ne_scalar,
    );

sub _function_call {
    my( $self, $tree ) = @_;

    push @bytecode, { function => \&Language::P::Opcodes::o_start_call };

    if( $tree->function eq 'print' ) {
        # FIXME HACK, must create a builtin node type
        my $out = Language::P::Value::Handle->new( { handle => \*STDOUT } );
        push @bytecode, { function => \&Language::P::Opcodes::o_constant,
                          value    => $out,
                          },
                        { function => \&Language::P::Opcodes::o_push_scalar };
    }

    foreach my $arg ( @{$tree->arguments} ) {
        $self->dispatch( $arg );
        # FIXME HACK
        push @bytecode, { function => \&Language::P::Opcodes::o_push_scalar },
    }

    if( $builtins{$tree->function} ) {
        push @bytecode, { function => $builtins{$tree->function} };
    } else {
        push @bytecode,
          { function => \&Language::P::Opcodes::o_glob,
            name     => $tree->function,
            create   => 1,
            },
          { function => \&Language::P::Opcodes::o_glob_slot,
            slot     => 'subroutine',
            },
          { function => \&Language::P::Opcodes::o_call,
            };
    }
}

sub _list {
    my( $self, $tree ) = @_;

    push @bytecode, { function => \&Language::P::Opcodes::o_start_list };

    foreach my $arg ( @{$tree->expressions} ) {
        $self->dispatch( $arg );
        # HACK
        push @bytecode, { function => \&Language::P::Opcodes::o_push_scalar },
    }
}

sub _binary_op {
    my( $self, $tree ) = @_;

    die $tree->op unless $builtins{$tree->op};

    if( $short_circuit{$tree->op} ) {
        $self->dispatch( $tree->left );

        my $end = _new_label;

        # jump to $end if evalutating right is not necessary
        push @bytecode,
            { function => \&Language::P::Opcodes::o_dup },
            { function => $short_circuit{$tree->op} };
        _to_label( $end, $bytecode[-1] );

        # evalutates right only if this is the correct return value
        $self->dispatch( $tree->right );

        _set_label( $end, scalar @bytecode );
    } else {
        $self->dispatch( $tree->right );
        $self->dispatch( $tree->left );

        push @bytecode, { function => $builtins{$tree->op} };
    }
}

sub _binary_op_cond {
    my( $self, $tree, $true, $false ) = @_;

    die $tree->op unless $conditionals{$tree->op};

    $self->dispatch( $tree->right );
    $self->dispatch( $tree->left );

    push @bytecode, { function => $conditionals{$tree->op} };
    # jump to $false if false, fall trough if true
    push @bytecode,
        { function => \&Language::P::Opcodes::o_jump_if_eq_immed,,
          value    => 0,
          };
    _to_label( $false, $bytecode[-1] );
}

sub _constant {
    my( $self, $tree ) = @_;
    my $type = $tree->type;
    my $v;

    if( $type eq 'number' ) {
        $v = Language::P::Value::StringNumber->new( { integer => $tree->value } );
    } elsif( $type eq 'string' ) {
        $v = Language::P::Value::StringNumber->new( { string => $tree->value } );
    } else {
        die $type;
    }

    push @bytecode,
        { function => \&Language::P::Opcodes::o_constant,
          value    => $v,
          };
}

my %sigils =
  ( '$' => 'scalar',
    '&' => 'subroutine',
    );

sub _symbol {
    my( $self, $tree ) = @_;

    my $slot = $sigils{$tree->sigil};
    die $tree->sigil unless $slot;

    push @bytecode,
        { function => \&Language::P::Opcodes::o_glob,
          name     => $tree->name,
          create   => 1,
          },
        { function => \&Language::P::Opcodes::o_glob_slot_create,
          slot     => $slot,
          };
}

sub _lexical_declaration {
    my( $self, $tree ) = @_;

    die unless defined $tree->{slot}->{level};
#     use Data::Dumper;
#     print Dumper $tree;
    my $in_pad = $tree->{slot}->{slot}->{in_pad};
    push @bytecode,
        { function => $in_pad ? \&Language::P::Opcodes::o_lexical_pad :
                                \&Language::P::Opcodes::o_lexical,
          lexical  => $tree->{slot}->{slot},
          level    => $tree->{slot}->{level},
          };
}

sub _cond {
    my( $self, $tree ) = @_;

    die if $tree->iftrues->[0]->[0] ne 'if';

    my $end = _new_label;
    foreach my $elsif ( @{$tree->iftrues} ) {
        my( $true, $false ) = ( _new_label, _new_label );
        $self->dispatch_cond( $elsif->[1], $true, $false );
        _set_label( $true, scalar @bytecode );
        $self->dispatch( $elsif->[2] );
        push @bytecode,
            { function => \&Language::P::Opcodes::o_jump,
              };
        _to_label( $end, $bytecode[-1] );
        _set_label( $false, scalar @bytecode );
    }
    if( $tree->iffalse ) {
        $self->dispatch( $tree->iffalse->[2] );
    }
    _set_label( $end, scalar @bytecode );
}

sub _block {
    my( $self, $tree ) = @_;

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }
}

sub _subroutine {
    my( $self, $tree ) = @_;

    my $sub = Language::P::Value::Subroutine->new
                  ( { bytecode => [],
                      name     => $tree->name,
                      } );
    $self->push_code( $sub );

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }

    $self->finished;
    $self->pop_code;

    $self->runtime->symbol_table->set_symbol( $tree->name, '&', $sub );
}

sub _allocate_lexicals {
    my( $self ) = @_;

    my $pad = Language::P::Value::ScratchPad->new;
    my $has_pad;
    foreach my $op ( @bytecode ) {
        next if !$op->{lexical};

#         use Data::Dumper;
#         print Dumper $op;

        # FIXME make the lexical slot an object with accessors
        if( $op->{level} == 0 && $op->{lexical}->{index} == -100 ) {
            if( $op->{lexical}->{in_pad} ) {
                if( !$has_pad ) {
                    $codes[-1]->{lexicals} = $pad;
                    $pad->{outer} = $codes[-1]->{outer};
                    $has_pad = 1;
                }
                $op->{lexical}->{index} = $pad->add_value;
            } else {
                $op->{lexical}->{index} = $codes[-1]->stack_size;
                ++$codes[-1]->{stack_size};
            }
        }

        $op->{in_pad} = $op->{lexical}->{in_pad};
        $op->{index} = $op->{lexical}->{index};
        delete $op->{lexical};
    }
}

1;
