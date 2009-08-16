package Language::P::Toy::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_ro_accessors( qw(runtime) );
__PACKAGE__->mk_accessors( qw(_code _pending _block_map _temporary_map
                              _options _generated _intermediate _processing
                              _eval_context _segment) );

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
    VALUE_HASH()   => 'hash',
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

sub safe_instance {
    my( $self ) = @_;

    return $self unless $self->is_generating;
    return ref( $self )->new
               ( { _options => { %{$self->{_options}},
                                 # performed by caller
                                 'dump-ir' => 0,
                                 },
                   runtime  => $self->runtime,
                   } );
}

sub set_option {
    my( $self, $option, $value ) = @_;

    if( $option eq 'dump-ir' ) {
        $self->_options->{$option} = 1;
        $self->_intermediate->set_option( 'dump-ir' );
    }

    return 0;
}

sub process {
    my( $self, $tree ) = @_;

    if( $tree->isa( 'Language::P::ParseTree::Use' ) ) {
        # emit the 'use' almost the same way as the corresponding
        # BEGIN block would look if written in Perl
        my $sub_int = $self->_intermediate->generate_use( $tree );
        my $sub = _generate_segment( $self, $sub_int->[0] );

        my $args = Language::P::Toy::Value::List->new( $self->runtime );
        $self->runtime->call_subroutine( $sub, CXT_VOID, $args );

        return;
    }
    if( $tree->isa( 'Language::P::ParseTree::NamedSubroutine' ) ) {
        my $sub_int = $self->_intermediate->generate_subroutine( $tree );
        my $sub = _generate_segment( $self, $sub_int->[0] );

        # run right away if it is a begin block
        if( $tree->name eq 'BEGIN' ) {
            my $args = Language::P::Toy::Value::List->new( $self->runtime );
            $self->runtime->call_subroutine( $sub, CXT_VOID, $args );
        }

        return;
    }

    push @{$self->{_pending}}, $tree;
}

sub add_declaration {
    my( $self, $name, $prototype ) = @_;

    my $sub = Language::P::Toy::Value::Subroutine::Stub->new
                  ( $self->runtime,
                    { name      => $name,
                      prototype => $prototype,
                      } );
    $self->runtime->symbol_table->set_symbol( $self->runtime, $name, '&', $sub );
}

my %opcode_map =
  ( OP_GLOBAL()                      => \&_global,
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
    OP_JUMP_IF_NULL()                => \&_cond_jump_simple,
    OP_JUMP()                        => \&_direct_jump,
    OP_TEMPORARY()                   => \&_temporary,
    OP_TEMPORARY_SET()               => \&_temporary_set,
    OP_LOCALIZE_GLOB_SLOT()          => \&_map_slot_index,
    OP_RESTORE_GLOB_SLOT()           => \&_map_slot_index,
    OP_SCOPE_ENTER()                 => \&_scope_enter,
    OP_SCOPE_LEAVE()                 => \&_scope_leave,
    OP_END()                         => \&_end,

    OP_RX_QUANTIFIER()               => \&_rx_quantifier,
    OP_RX_START_GROUP()              => \&_direct_jump,
    OP_RX_TRY()                      => \&_direct_jump,
    );

sub _convert_bytecode {
    my( $self, $bytecode ) = @_;
    my @bytecode;

    foreach my $ins ( @$bytecode ) {
        next if $ins->{label};
        my $name = $NUMBER_TO_NAME{$ins->{opcode_n}};

        die "Invalid $ins->{opcode}/$ins->{opcode_n}" unless $name;

        if( my $sub = $opcode_map{$ins->{opcode_n}} ) {
            $sub->( $self, \@bytecode, $ins );
        } else {
            my %p = $ins->{attributes} ? %{$ins->{attributes}} : ();
            $p{slot} = $sigil_to_slot{$p{slot}} if $p{slot};
            $p{pos} = $ins->{pos} if $ins->{pos};
            push @bytecode, o( $name, %p );
        }
    }

    return \@bytecode;
}

sub _generate_segment {
    my( $self, $segment, $target ) = @_;
    my $is_sub = $segment->is_sub;
    my $is_regex = $segment->is_regex;
    my $pad = Language::P::Toy::Value::ScratchPad->new( $self->runtime );

    my $code = $target;
    if( $is_sub && !$code ) {
        $code = Language::P::Toy::Value::Subroutine->new
                    ( $self->runtime,
                      { bytecode => [],
                        name     => $segment->name,
                        lexicals => $pad,
                        prototype=> $segment->prototype,
                        } );
    } elsif( $is_regex && !$code ) {
        $code = Language::P::Toy::Value::Regex->new
                    ( $self->runtime,
                      { bytecode   => [],
                        stack_size => 0,
                        } );
    } elsif( !$code ) {
        $code = Language::P::Toy::Value::Code->new
                    ( $self->runtime,
                      { bytecode => [],
                        lexicals => $pad,
                        } );
    }
    push @{$self->{_processing}}, $code;

    # Toy subroutine start with stack_size = 1 (for args), and so does
    # the IR code segment
    $code->{stack_size} +=   $segment->lexicals->{max_stack}
                           - ( $code->is_subroutine ? 1 : 0 )
        if $segment->lexicals;

    $self->_generated->{$segment} = $code;

    foreach my $inner ( @{$segment->inner} ) {
        next unless $inner;
        _generate_segment( $self, $inner );
    }

    $self->_code( $code );
    $self->_block_map( {} );
    $self->_temporary_map( {} );
    $self->_segment( $segment );

    my @converted;
    foreach my $block ( @{$segment->basic_blocks} ) {
        my $bytecode = _convert_bytecode( $self, $block->bytecode );
        push @converted, [ $block, $bytecode ];
    }

    foreach my $block ( @converted ) {
        my $start = @{$self->_code->bytecode};
        push @{$self->_code->bytecode}, @{$block->[1]};

        foreach my $op ( @{$self->_block_map->{$block->[0]}} ) {
            $op->{to} = $start;
        }
    }
    $self->_segment( undef );

    $self->_allocate_lexicals( $segment, $code )
      if $segment->lexicals;
    $self->runtime->symbol_table->set_symbol( $self->runtime, $segment->name, '&', $code )
      if defined $segment->name;
    pop @{$self->{_processing}};

    return $code;
}

sub process_regex {
    my( $self, $regex ) = @_;

    $self->start_code_generation;
    my $regex_int = $self->_intermediate->generate_regex( $regex );
    my $res = _generate_segment( $self, $regex_int->[0] );
    $self->_cleanup;

    return $res;
}

sub finished {
    my( $self ) = @_;
    my $main_int = $self->_intermediate->generate_bytecode( $self->_pending );
    my $head = pop @{$self->{_processing}};
    my $res = _generate_segment( $self, $main_int->[0], $head );
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
    $self->_processing( undef );
}

sub start_code_generation {
    my( $self, $args ) = @_;
    my( $outer_toy, $outer_int );
    if( my $cxt = $self->_eval_context ) {
        $outer_toy = $cxt->[1];
        $outer_int = $self->_intermediate
                          ->create_eval_context( $cxt->[0], $cxt->[2] );
    }
    my $code = Language::P::Toy::Value::Code->new
                   ( $self->runtime,
                     { bytecode => [],
                       lexicals => Language::P::Toy::Value::ScratchPad->new
                                       ( $self->runtime ),
                       } );
    $self->{_processing} = [ $outer_toy, $code ];

    $self->_generated( {} );
    $self->_intermediate->file_name( $args->{file_name} )
      if $args && $args->{file_name};
    $self->_intermediate->create_main( $outer_int, $outer_int ? 1 : 0 );
    $self->_pending( [] );
}

sub end_code_generation {
    my( $self ) = @_;
    my $res = $self->finished;

    return $res;
}

sub is_generating { return $_[0]->_processing ? 1 : 0 }

sub _scope_enter {
    my( $self, $bytecode, $op ) = @_;
    my $id = $op->{attributes}{scope};
    my $scope = $self->_segment->scopes->[$id];

    my @exit_bytecode;
    foreach my $chunk ( reverse @{$scope->{bytecode}} ) {
        push @exit_bytecode, @{$self->_convert_bytecode( $chunk )};
    }
    push @exit_bytecode, o( 'end' );

    $self->_code->scopes->[$id] =
        { start    => scalar @$bytecode,
          end      => -1,
          flags    => $scope->{flags},
          outer    => $scope->{outer},
          bytecode => \@exit_bytecode,
          };
}

sub _scope_leave {
    my( $self, $bytecode, $op ) = @_;
    my $id = $op->{attributes}{scope};

    $self->_code->scopes->[$id]{end} = scalar @$bytecode;
}

sub _end {
    my( $self, $bytecode, $op ) = @_;

    if( !$self->_code->isa( 'Language::P::Toy::Value::Regex' ) ) {
        # could be avoided in most cases, but simplifies code
        # generation and automatically handles the 'return undef on
        # failure' behaviour of eval
        push @$bytecode,
            o( 'make_list', count => 0 ),
            o( 'return' );
    } else {
        push @$bytecode, o( 'end' );
    }
}

sub _global {
    my( $self, $bytecode, $op ) = @_;

    if( $op->{attributes}{slot} == VALUE_GLOB ) {
        push @$bytecode,
             o( 'glob',
                pos    => $op->{pos},
                name   => $op->{attributes}{name},
                create => 1 );
        return;
    }

    my $slot = $sigil_to_slot{$op->{attributes}{slot}};
    die $op->{attributes}{slot} unless $slot;

    push @$bytecode,
         o( 'glob',
            pos    => $op->{pos},
            name   => $op->{attributes}{name},
            create => 1 ),
         o( 'glob_slot_create',
            pos    => $op->{pos},
            slot   => $slot );
}

sub _const_string {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::Scalar->new_string
                ( $self->runtime, $op->{attributes}{value} );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _fresh_string {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'fresh_string', value => $op->{attributes}{value} );
}

sub _const_integer {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new
                ( $self->runtime, { integer => $op->{attributes}{value} } );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_float {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new
                ( $self->runtime, { float => $op->{attributes}{value} } );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_undef {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::Undef->new( $self->runtime );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_codelike {
    my( $self, $bytecode, $op ) = @_;

    my $sub = $self->_generated->{$op->{attributes}{value}};
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
         o( 'lexical', index => _temporary_index( $self, $op->{attributes}{index} ) );
}

sub _temporary_set {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'lexical_set', index => _temporary_index( $self, $op->{attributes}{index} ) );
}

sub _map_slot_index {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}},
            name  => $op->{attributes}{name},
            slot  => $sigil_to_slot{$op->{attributes}{slot}},
            index => _temporary_index( $self, $op->{attributes}{index} ),
            );
}

sub _direct_jump {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}} );
    push @{$self->_block_map->{$op->{attributes}{to}}}, $bytecode->[-1];
}

sub _cond_jump_simple {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}}, pos => $op->{pos} ),
         o( 'jump' );
    push @{$self->_block_map->{$op->{attributes}{true}}}, $bytecode->[-2];
    push @{$self->_block_map->{$op->{attributes}{false}}}, $bytecode->[-1];
}

sub _rx_quantifier {
    my( $self, $bytecode, $op ) = @_;
    my %params = %{$op->{attributes}};
    delete $params{true}; delete $params{false};

    push @$bytecode,
         o( 'rx_quantifier', %params ),
         o( 'jump' );
    push @{$self->_block_map->{$op->{attributes}{true}}}, $bytecode->[-2];
    push @{$self->_block_map->{$op->{attributes}{false}}}, $bytecode->[-1];
}

sub _allocate_lexicals {
    my( $self, $ir_code, $toy_code ) = @_;
    my $pad = $toy_code->lexicals;
    my $needs_pad = 0;

    foreach my $lex_info ( values %{$ir_code->lexicals->{map}} ) {
        unless( $lex_info->{in_pad} ) {
            $toy_code->lexical_init->[$lex_info->{index}] =
              $lex_info->{lexical}->sigil;
            next;
        }
        $needs_pad ||= 1;
        if( $lex_info->{from_main} ) {
            my $main_pad = $self->_processing->[-$lex_info->{level} - 1]->lexicals;
            $main_pad->add_value_index( $self->runtime, $lex_info->{lexical}, $lex_info->{outer_index} );
            $pad->add_value_index( $self->runtime, $lex_info->{lexical}, $lex_info->{index},
                                   $main_pad->values->[$lex_info->{outer_index}] );
        } else {
            $pad->add_value_index( $self->runtime, $lex_info->{lexical}, $lex_info->{index} );
            push @{$toy_code->{closed}},
                 [$lex_info->{outer_index}, $lex_info->{index}]
                   if $lex_info->{outer_index} >= 0;
            if( $lex_info->{declaration} ) {
                push @{$pad->{clear}{indices}}, $lex_info->{index};
                if( $lex_info->{lexical}->sigil == VALUE_SCALAR ) {
                    push @{$pad->{clear}{scalar}}, $lex_info->{index};
                } elsif( $lex_info->{lexical}->sigil == VALUE_ARRAY ) {
                    push @{$pad->{clear}{array}}, $lex_info->{index};
                } elsif( $lex_info->{lexical}->sigil == VALUE_HASH ) {
                    push @{$pad->{clear}{hash}}, $lex_info->{index};
                }
            }
        }
    }
    if( !$needs_pad ) {
        $toy_code->{lexicals} = undef;
    }
    $toy_code->{closed} = undef unless @{$toy_code->closed};
}

1;
