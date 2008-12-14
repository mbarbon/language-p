package Language::P::Toy::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_ro_accessors( qw(runtime) );
__PACKAGE__->mk_accessors( qw(_code _pending _block_map _temporary_map
                              _options _generated _intermediate) );

use Language::P::Intermediate::Generator;
use Language::P::Opcodes qw(:all);
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Handle;
use Language::P::Toy::Value::ScratchPad;
use Language::P::Toy::Value::Code;
use Language::P::Toy::Value::Regex;
use Language::P::ParseTree qw(:all);
use Language::P::Keywords qw(:all);

my %sigil_to_slot =
  ( VALUE_SCALAR() => 'scalar',
    VALUE_SUB()    => 'subroutine',
    VALUE_ARRAY()  => 'array',
    VALUE_HANDLE() => 'io',
    );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_options( {} );
    $self->_intermediate( Language::P::Intermediate::Generator->new
                              ( { file_name => 'a.ir',
                                   } ) );

    return $self;
}

sub set_option {
    my( $self, $option, $value ) = @_;

    if( $option eq 'dump-ir' ) {
        $self->_options->{$option} = 1;
        $self->_intermediate->set_option( 'dump-ir' );
    }

    return 0;
}

sub _add {
    my( $self, @bytecode ) = @_;

    push @{$self->_code->bytecode}, @bytecode;
}

sub process {
    my( $self, $tree ) = @_;

    push @{$self->{_pending}}, $tree;

    return;
}

sub add_declaration {
    my( $self, $name ) = @_;

    my $sub = Language::P::Toy::Value::Subroutine::Stub->new
                  ( { name     => $name,
                      } );
    $self->runtime->symbol_table->set_symbol( $name, '&', $sub );
}

my %opcode_map =
  ( OP_GLOBAL()                      => \&_global,
    OP_LEXICAL()                     => \&_lexical,
    OP_LEXICAL_CLEAR()               => \&_lexical_clear,
    OP_CONSTANT_STRING()             => \&_const_string,
    OP_FRESH_STRING()                => \&_fresh_string,
    OP_CONSTANT_INTEGER()            => \&_const_integer,
    OP_CONSTANT_FLOAT()              => \&_const_float,
    OP_CONSTANT_UNDEF()              => \&_const_undef,
    OP_CONSTANT_SUB()                => \&_const_codelike,
    OP_CONSTANT_REGEX()              => \&_const_codelike,
    OP_JUMP_IF_TRUE()                => \&_cond_jump_simple,
    OP_JUMP_IF_FALSE()               => \&_cond_jump_simple,
    OP_JUMP_IF_F_LT()                => \&_cond_jump_simple,
    OP_JUMP_IF_S_LT()                => \&_cond_jump_simple,
    OP_JUMP_IF_F_GT()                => \&_cond_jump_simple,
    OP_JUMP_IF_S_GT()                => \&_cond_jump_simple,
    OP_JUMP_IF_F_LE()                => \&_cond_jump_simple,
    OP_JUMP_IF_S_LE()                => \&_cond_jump_simple,
    OP_JUMP_IF_F_GE()                => \&_cond_jump_simple,
    OP_JUMP_IF_S_GE()                => \&_cond_jump_simple,
    OP_JUMP_IF_F_EQ()                => \&_cond_jump_simple,
    OP_JUMP_IF_S_EQ()                => \&_cond_jump_simple,
    OP_JUMP_IF_F_NE()                => \&_cond_jump_simple,
    OP_JUMP_IF_S_NE()                => \&_cond_jump_simple,
    OP_JUMP_IF_UNDEF()               => \&_cond_jump_simple,
    OP_JUMP()                        => \&_direct_jump,
    OP_TEMPORARY()                   => \&_temporary,
    OP_TEMPORARY_SET()               => \&_temporary_set,
    OP_LOCALIZE_GLOB_SLOT()          => \&_map_slot_index,
    OP_RESTORE_GLOB_SLOT()           => \&_map_slot_index,

    OP_RX_QUANTIFIER()               => \&_rx_quantifier,
    OP_RX_START_GROUP()              => \&_direct_jump,
    OP_RX_TRY()                      => \&_direct_jump,
    );

sub _generate_segment {
    my( $self, $segment, $outer ) = @_;
    my $is_sub = $segment->type == 2;
    my $is_regex = $segment->type == 3;
    my $pad = Language::P::Toy::Value::ScratchPad->new;

    my $code;
    if( $is_sub ) {
        $code = Language::P::Toy::Value::Subroutine->new
                    ( { bytecode => [],
                        name     => $segment->name,
                        lexicals => $pad,
                        outer    => $outer,
                        } );
    } elsif( $is_regex ) {
        $code = Language::P::Toy::Value::Regex->new
                    ( { bytecode   => [],
                        stack_size => 0,
                        } );
    } else {
        $code = Language::P::Toy::Value::Code->new
                    ( { bytecode => [],
                        lexicals => $pad,
                        outer    => $outer,
                        } );
    }

    $self->_generated->{$segment} = $code;

    foreach my $inner ( @{$segment->inner} ) {
        _generate_segment( $self, $inner, $code );
    }

    $self->_code( $code );
    $self->_block_map( {} );
    $self->_temporary_map( {} );

    my @converted;
    foreach my $block ( @{$segment->basic_blocks} ) {
        my @bytecode;
        push @converted, [ $block, \@bytecode ];

        foreach my $ins ( @{$block->bytecode} ) {
            next if $ins->{label};
            my $name = $NUMBER_TO_NAME{$ins->{opcode_n}};

            die "Invalid $ins->{opcode}/$ins->{opcode_n}" unless $name;

            if( my $sub = $opcode_map{$ins->{opcode_n}} ) {
                $sub->( $self, \@bytecode, $ins );
            } else {
                my %p = $ins->{parameters} ? %{$ins->{parameters}} : ();
                $p{slot} = $sigil_to_slot{$p{slot}} if $p{slot};
                push @bytecode, o( $name, %p );
            }
        }
    }

    foreach my $block ( @converted ) {
        my $start = @{$self->_code->bytecode};
        push @{$self->_code->bytecode}, @{$block->[1]};

        foreach my $op ( @{$self->_block_map->{$block->[0]}} ) {
            $op->{to} = $start;
        }
    }

    $self->_allocate_lexicals( $is_sub );

    if( $is_sub ) {
        # could be avoided in most cases, but simplifies code generation
        _add $self,
            o( 'make_list', count => 0 ),
            o( 'return' );
    } else {
        _add $self, o( 'end' );
    }

    $self->runtime->symbol_table->set_symbol( $segment->name, '&', $code )
      if defined $segment->name;

    return $code;
}

sub process_regex {
    my( $self, $regex ) = @_;

    $self->start_code_generation;

    return $self->_process_code_segments
               ( $self->_intermediate->generate_regex( $regex ) );
}

sub finished {
    my( $self ) = @_;
    my $pending = $self->_pending;

    return $self->_process_code_segments
               ( $self->_intermediate->generate_bytecode( $pending ) );
}

sub _process_code_segments {
    my( $self, $code_segments ) = @_;

    $self->_generated( {} );
    foreach my $segment ( @$code_segments ) {
        next if $self->_generated->{$segment};
        _generate_segment( $self, $segment, undef );
    }

    my $res = $self->_generated->{$code_segments->[0]};

    $self->_cleanup;

    return $res;
}

sub _cleanup {
    my( $self ) = @_;

    $self->_pending( [] );
    $self->_code( undef );
    $self->_block_map( undef );
    $self->_temporary_map( undef );
    $self->_generated( undef );
}

sub start_code_generation {
    my( $self ) = @_;

    $self->_pending( [] );
}

sub end_code_generation {
    my( $self ) = @_;
    my $res = $self->finished;

    return $res;
}

sub _global {
    my( $self, $bytecode, $op ) = @_;

    if( $op->{parameters}{slot} == VALUE_GLOB ) {
        push @$bytecode,
             o( 'glob', name => $op->{parameters}{name}, create => 1 );
        return;
    }

    my $slot = $sigil_to_slot{$op->{parameters}{slot}};
    die $op->{parameters}{slot} unless $slot;

    push @$bytecode,
         o( 'glob',             name => $op->{parameters}{name}, create => 1 ),
         o( 'glob_slot_create', slot => $slot );
}

sub _lexical {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $op->{parameters}{lexical}->closed_over ? 'lexical_pad' : 'lexical',
            lexical => $op->{parameters}{lexical},
            level   => $op->{parameters}{level},
            );
}

sub _lexical_clear {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $op->{parameters}{lexical}->closed_over ? 'lexical_pad_clear' : 'lexical_clear',
            lexical => $op->{parameters}{lexical},
            level   => $op->{parameters}{level},
            );
}

sub _const_string {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new
                ( { string => $op->{parameters}[0] } );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _fresh_string {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'fresh_string', value => $op->{parameters}[0] );
}

sub _const_integer {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new
                ( { integer => $op->{parameters}[0] } );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_float {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new
                ( { float => $op->{parameters}[0] } );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_undef {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new;
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_codelike {
    my( $self, $bytecode, $op ) = @_;

    my $sub = $self->_generated->{$op->{parameters}[0]};
    push @$bytecode,
         o( 'constant', value => $sub );
}

sub _temporary_index {
    my( $self, $index ) = @_;
    return $self->_temporary_map->{$index}
        if exists $self->_temporary_map->{$index};
    my $offset = $self->_temporary_map->{$index} = $self->_code->stack_size;
    ++$self->_code->{stack_size};
    return $offset;
}

sub _temporary {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'lexical', index => _temporary_index( $self, $op->{parameters}{index} ) );
}

sub _temporary_set {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'lexical_set', index => _temporary_index( $self, $op->{parameters}{index} ) );
}

sub _map_slot_index {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}},
            name  => $op->{parameters}{name},
            slot  => $sigil_to_slot{$op->{parameters}{slot}},
            index => _temporary_index( $self, $op->{parameters}{index} ),
            );
}

sub _direct_jump {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}} );
    push @{$self->_block_map->{$op->{parameters}{to}}}, $bytecode->[-1];
}

sub _cond_jump_simple {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}} ),
         o( 'jump' );
    push @{$self->_block_map->{$op->{parameters}{true}}}, $bytecode->[-2];
    push @{$self->_block_map->{$op->{parameters}{false}}}, $bytecode->[-1];
}

sub _rx_quantifier {
    my( $self, $bytecode, $op ) = @_;
    my %params = %{$op->{parameters}};
    delete $params{true}; delete $params{false};

    push @$bytecode,
         o( 'rx_quantifier', %params ),
         o( 'jump' );
    push @{$self->_block_map->{$op->{parameters}{true}}}, $bytecode->[-2];
    push @{$self->_block_map->{$op->{parameters}{false}}}, $bytecode->[-1];
}

my %lex_map;

sub _find_add_value {
    my( $pad, $lexical ) = @_;

    return $lex_map{$pad}{$lexical} if exists $lex_map{$pad}{$lexical};
    return $lex_map{$pad}{$lexical} = $pad->add_value( $lexical );
}

sub _uplevel {
    my( $code, $level ) = @_;

    $code = $code->outer foreach 1 .. $level;

    return $code;
}

sub _allocate_lexicals {
    my( $self, $is_sub ) = @_;

    my $pad = $self->_code->lexicals;
    return unless $pad;
    my %map = $lex_map{$pad} ? %{ delete $lex_map{$pad} } : ();
    my %clear;
    my $needs_pad;
    foreach my $op ( @{$self->_code->bytecode} ) {
        next if !$op->{lexical};

        if( !exists $map{$op->{lexical}} ) {
            if(    $op->{lexical}->name eq '_'
                && $op->{lexical}->sigil == VALUE_ARRAY ) {
                $map{$op->{lexical}} = 0; # arguments are always first
            } elsif( $op->{lexical}->closed_over ) {
                my $level = $op->{level};

                if( $level ) {
                    my $code_from = _uplevel( $self->_code, $level );
                    my $pad_from = $code_from->lexicals;
                    my $val = _find_add_value( $pad_from, $op->{lexical} );
                    if( $code_from->is_subroutine ) {
                        foreach my $index ( -$level .. -1 ) {
                            my $inner_code = _uplevel( $self->_code, -$index - 1 );
                            my $outer_code = _uplevel( $inner_code, 1 );
                            my $outer_pad = $outer_code->lexicals;
                            my $inner_pad = $inner_code->lexicals;

                            my $outer_idx = _find_add_value( $outer_pad, $op->{lexical} );
                            my $inner_idx = _find_add_value( $inner_pad, $op->{lexical} );
                            push @{$inner_code->closed},
                                 [$outer_idx, $inner_idx];
                            $map{$op->{lexical}} = $inner_idx
                              if $index == -1;
                        }
                    } else {
                        $map{$op->{lexical}} =
                            $pad->add_value( $op->{lexical},
                                             $pad_from->values->[ $val ] );
                    }
                } else {
                    $map{$op->{lexical}} = _find_add_value( $pad, $op->{lexical} );
                }
            } else {
                $map{$op->{lexical}} = $self->_code->stack_size;
                ++$self->_code->{stack_size};
            }
        }

        if( $op->{lexical}->closed_over ) {
            $needs_pad = 1;
        }
        $op->{index} = $map{$op->{lexical}};
        $clear{$op->{index}} ||= 1 if $op->{lexical}->closed_over && !$op->{level};
        delete $op->{lexical};
        delete $op->{level};
    }

    $self->_code->{closed} = undef unless @{$self->_code->closed};
    if( !$needs_pad ) {
        $self->_code->{lexicals} = undef;
    }
    $pad->{clear} = [ keys %clear ];
}

1;
