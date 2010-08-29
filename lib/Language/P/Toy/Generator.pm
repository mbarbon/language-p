package Language::P::Toy::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_ro_accessors( qw(runtime) );
__PACKAGE__->mk_accessors( qw(_code _pending _block_map _index_map
                              _options _generated _intermediate _processing
                              _eval_context _segment _saved_subs
                              _generated_scopes _data_handle) );

use Language::P::Intermediate::Code qw(:all);
use Language::P::Intermediate::Generator;
use Language::P::Opcodes qw(:all);
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Handle;
use Language::P::Toy::Value::ScratchPad;
use Language::P::Toy::Value::Code;
use Language::P::Toy::Value::Regex;
use Language::P::Constants qw(:all);
use Language::P::Keywords qw(:all);

use constant
  { IDX_TEMPORARY  => 0,
    IDX_LEX_STATE  => 1,
    IDX_REGEX      => 2,
    IDX_MAX        => 2,
    };

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

    $self->_options( {} ) unless $self->_options;
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
    if( $option eq 'dump-bytecode' ) {
        $self->_options->{$option} = 1;
    }

    return 0;
}

sub process {
    my( $self, $tree ) = @_;

    if( $tree->isa( 'Language::P::ParseTree::Use' ) ) {
        # emit the 'use' almost the same way as the corresponding
        # BEGIN block would look if written in Perl
        my $sub_int = $self->_intermediate->generate_use( $tree );

        if( $self->_options->{'dump-bytecode'} ) {
            push @{$self->{_saved_subs} ||= []}, @$sub_int;
        }

        my $sub = _generate_segment( $self, $sub_int->[0] );

        my $args = Language::P::Toy::Value::List->new( $self->runtime );
        $self->runtime->call_subroutine( $sub, CXT_VOID, $args );

        return;
    }
    if( $tree->isa( 'Language::P::ParseTree::NamedSubroutine' ) ) {
        my $sub_int = $self->_intermediate->generate_subroutine( $tree );
        my $sub = _generate_segment( $self, $sub_int->[0] );

        # run right away if it is a begin block
        if( $tree->name eq 'BEGIN' || $tree->name =~ /::BEGIN$/ ) {
            my $args = Language::P::Toy::Value::List->new( $self->runtime );
            $self->runtime->call_subroutine( $sub, CXT_VOID, $args,
                                             $tree->pos_e );
        }

        return;
    }
    if( $tree->isa( 'Language::P::ParseTree::LexicalState' ) ) {
        if( $tree->changed & CHANGED_PACKAGE ) {
            $self->runtime->symbol_table->get_package( $self->runtime,
                                                       $tree->package, 1 );
        }
    }

    push @{$self->{_pending}}, $tree;
}

sub add_declaration {
    my( $self, $name, $prototype ) = @_;

    my $sub = Language::P::Toy::Value::Subroutine::Stub->new
                  ( $self->runtime,
                    { name      => _qualify( $name ),
                      prototype => $prototype,
                      } );
    my $slot = $self->runtime->symbol_table->get_symbol( $self->runtime, $name, '&' );

    if( $slot && $slot->is_defined ) {
        # TODO warn about prototype mismatch
    } elsif( $slot ) {
        # TODO warn about prototype mismatch
        $slot->assign( $self->runtime, $sub );
    } else {
        $self->runtime->symbol_table->set_symbol( $self->runtime, $name, '&', $sub );
    }
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
    OP_LEXICAL_STATE_SET()           => \&_lexical_state_set,
    OP_LEXICAL_STATE_SAVE()          => \&_lexical_state_save,
    OP_LEXICAL_STATE_RESTORE()       => \&_lexical_state_restore,
    OP_TEMPORARY()                   => \&_temporary,
    OP_TEMPORARY_SET()               => \&_temporary_set,
    OP_TEMPORARY_CLEAR()             => \&_temporary_clear,
    OP_LOCALIZE_GLOB_SLOT()          => \&_map_slot_index,
    OP_RESTORE_GLOB_SLOT()           => \&_map_slot_index,
    OP_LOCALIZE_HASH_ELEMENT()       => \&_map_index,
    OP_RESTORE_HASH_ELEMENT()        => \&_map_index,
    OP_LOCALIZE_ARRAY_ELEMENT()      => \&_map_index,
    OP_RESTORE_ARRAY_ELEMENT()       => \&_map_index,
    OP_LOCALIZE_LEXICAL()            => \&_map_lexical_index,
    OP_RESTORE_LEXICAL()             => \&_map_lexical_index,
    OP_LOCALIZE_LEXICAL_PAD()        => \&_map_lexical_index,
    OP_RESTORE_LEXICAL_PAD()         => \&_map_lexical_index,
    OP_END()                         => \&_end,
    OP_STOP()                        => \&_stop,
    OP_DOT_DOT()                     => \&_dot_dot,

    OP_RX_QUANTIFIER()               => \&_rx_quantifier,
    OP_RX_START_GROUP()              => \&_direct_jump,
    OP_RX_TRY()                      => \&_direct_jump,
    OP_RX_STATE_RESTORE()            => \&_rx_state_restore,
    OP_RX_CLASS()                    => \&_rx_class,
    OP_RX_SPECIAL_CLASS()            => \&_rx_special_class,
    OP_MATCH()                       => \&_match,
    OP_REPLACE()                     => \&_replace,
    OP_TRANSLITERATE()               => \&_transliterate,

    OP_DEREFERENCE_ARRAY()           => \&_dereference,
    OP_DEREFERENCE_GLOB()            => \&_dereference,
    OP_DEREFERENCE_HASH()            => \&_dereference,
    OP_DEREFERENCE_SCALAR()          => \&_dereference,
    OP_DEREFERENCE_SUB()             => \&_dereference,
    );

sub _qualify {
    return !defined $_[0] ? undef :
           $_[0] =~ /::/  ? $_[0] :
                            "main::$_[0]";
}

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

sub _generate_block {
    my( $self, $block, $converted ) = @_;
    my $start = @{$self->_code->bytecode};

    my $bytecode = _convert_bytecode( $self, $block->bytecode );
    push @{$self->_code->bytecode}, @$bytecode;

    push @$converted, [ $block, $start ];
}

sub _generate_scope {
    my( $self, $scope_id, $converted ) = @_;

    return if $self->_generated_scopes->{$scope_id};
    $self->_generated_scopes->{$scope_id} = 1;

    my $scope = $self->_segment->scopes->[$scope_id];
    _generate_scope( $self, $scope->{outer}, $converted )
        if $scope->{outer} != -1;
    my $state = $self->_segment->lexical_states->[$scope->{lexical_state}];

    my @exit_bytecode;
    $self->_code->scopes->[$scope_id] =
        { start         => scalar @{$self->_code->bytecode},
          end           => -1,
          flags         => $scope->{flags},
          outer         => $scope->{outer},
          context       => $scope->{context},
          bytecode      => \@exit_bytecode,
          pos_s         => $scope->{pos_s},
          pos_e         => $scope->{pos_e},
          warnings      => $state->{warnings},
          hints         => $state->{hints},
          package       => $state->{package},
          };

    foreach my $chunk ( reverse @{$scope->{bytecode}} ) {
        push @exit_bytecode, @{$self->_convert_bytecode( $chunk )};
    }
    push @exit_bytecode, o( 'end' );

    foreach my $block ( @{$self->_segment->basic_blocks} ) {
        if( $block->scope != $scope_id ) {
            next if $self->_generated_scopes->{$block->scope};
            my $is_inside = 0;
            for( my $s = $block->scope; !$is_inside && $s != -1;
                 $s = $self->_segment->scopes->[$s]->{outer} ) {
                $is_inside = $s == $scope_id;
            }
            _generate_scope( $self, $block->scope, $converted );
        } else {
            _generate_block( $self, $block, $converted );
        }
    }

# XXX scope must end before the 'end' opcode
    $self->_code->scopes->[$scope_id]->{end} = @{$self->_code->bytecode};
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
                        name     => _qualify( $segment->name ),
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
        next if !$inner || $self->_generated->{$inner};
        _generate_segment( $self, $inner );
    }

    $self->_code( $code );
    $self->_block_map( {} );
    $self->_index_map( {} );
    $self->_segment( $segment );
    $self->_generated_scopes( {} );

    my @converted;
    if( $is_regex ) {
        _generate_block( $self, $_, \@converted )
            foreach @{$segment->basic_blocks};
        push @{$self->{_saved_subs} ||= []}, $segment;
    } else {
        _generate_scope( $self, $segment->scopes->[0]->{id}, \@converted );
    }

    foreach my $block ( @converted ) {
        foreach my $op ( @{$self->_block_map->{$block->[0]}} ) {
            $op->{to} = $block->[1];
        }
    }
    $self->_segment( undef );

    $self->_allocate_lexicals( $segment, $code )
      if $segment->lexicals;
    # install into the symbol table; use assignment in case something
    # took a reference
    if( defined $segment->name && $segment->name ne 'BEGIN' ) {
        my $slot = $self->runtime->symbol_table->get_symbol( $self->runtime, $segment->name, '&' );

        # TODO warn redefinition
        $slot->assign( $self->runtime, $code );
    }

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

sub set_data_handle {
    my( $self, $package, $handle ) = @_;

    if( $self->_options->{'dump-bytecode'} ) {
        local $/; # slurp mode
        my $data = readline $handle;

        $self->_data_handle( [ $package, $data ] );
        open $handle, '<', \$data;
    }

    $self->runtime->set_data_handle( $package, $handle );
}

sub finished {
    my( $self ) = @_;
    my $main_int = $self->_intermediate->generate_bytecode( $self->_pending );
    my $data_handle = $self->_data_handle;

    # perform code generation before serializing, for regexes
    my $head = pop @{$self->{_processing}};

    my $res = _generate_segment( $self, $main_int->[0], $head );
    $main_int->[0]->weaken; # allow GC to happen
    $self->_cleanup;

    if( $self->_options->{'dump-bytecode'} && !$main_int->[0]->is_eval ) {
        require Language::P::Intermediate::Transform;
        require Language::P::Intermediate::Serialize;

        my $transform = Language::P::Intermediate::Transform->new;
        my $serialize = Language::P::Intermediate::Serialize->new;
        my $tree = $transform->all_to_tree( [ @$main_int,
                                              @{$self->_saved_subs || []} ] );
        ( my $outfile = $self->_intermediate->file_name ) =~ s/(\.\w+)?$/.pb/;

        $serialize->serialize( $tree, $outfile, $data_handle );
        $tree->[0]->weaken; # allow GC to happen
    }

    return $res;
}

sub _cleanup {
    my( $self ) = @_;

    $self->_pending( [] );
    $self->_code( undef );
    $self->_block_map( undef );
    $self->_index_map( undef );
    $self->_generated( undef );
    $self->_processing( undef );
    $self->_generated_scopes( {} );
    $self->_data_handle( undef );
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

sub _end {
    my( $self, $bytecode, $op ) = @_;

    if( !$self->_code->isa( 'Language::P::Toy::Value::Regex' ) ) {
        # could be avoided in most cases, but simplifies code
        # generation and automatically handles the 'return undef on
        # failure' behaviour of eval
        push @$bytecode,
            o( 'make_list', count => 0, context => CXT_LIST ),
            o( 'return' );
    } else {
        push @$bytecode, o( 'end' );
    }
}

sub _stop {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode, o( 'end' );
}

sub _dot_dot {
    my( $self, $bytecode, $op ) = @_;
    die "Can only generate ranges for now" if $op->{attributes}{context} != CXT_LIST;

    push @$bytecode, o( 'range' );
}

sub _global {
    my( $self, $bytecode, $op ) = @_;

    if( $op->{attributes}{slot} == VALUE_GLOB ) {
        push @$bytecode,
             o( 'glob',
                pos    => $op->{pos},
                name   => $op->{attributes}{name},
                create => !($op->{attributes}{context} & CXT_NOCREATE) );
        return;
    } elsif( $op->{attributes}{slot} == VALUE_STASH ) {
        push @$bytecode,
             o( 'stash',
                pos    => $op->{pos},
                name   => substr( $op->{attributes}{name}, 0, -2 ),
                create => !($op->{attributes}{context} & CXT_NOCREATE) );
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

sub _dereference {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}},
            pos    => $op->{pos},
            create => !($op->{attributes}{context} & CXT_NOCREATE) );
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
                ( $self->runtime, { integer => $op->{attributes}{value} + 0 } );
    push @$bytecode,
         o( 'constant', value => $v );
}

sub _const_float {
    my( $self, $bytecode, $op ) = @_;

    my $v = Language::P::Toy::Value::StringNumber->new
                ( $self->runtime, { float => $op->{attributes}{value} + 0.0 } );
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
    if( $op->{opcode_n} ==  OP_CONSTANT_REGEX ) {
        $sub->{regex_string} = $op->{attributes}{original};
    }
    push @$bytecode,
         o( 'constant', value => $sub );
}

sub _lexical_state_set {
    my( $self, $bytecode, $op ) = @_;
    my $state = $self->_segment->lexical_states->[$op->{attributes}{index}];

    push @$bytecode,
         o( 'lexical_state_set',
            package  => $state->{package},
            hints    => $state->{hints} & 0xff,
            warnings => $state->{warnings},
            );
}

sub _lexical_state_save {
    my( $self, $bytecode, $op ) = @_;
    my $state_id = $op->{attributes}{index};

    push @$bytecode,
         o( 'lexical_state_save',
            index => _temporary_index( $self, IDX_LEX_STATE, $state_id ) );
}

sub _lexical_state_restore {
    my( $self, $bytecode, $op ) = @_;
    my $state_id = $op->{attributes}{index};

    push @$bytecode,
         o( 'lexical_state_restore',
            index => _temporary_index( $self, IDX_LEX_STATE, $state_id ) );
}

sub _temporary_index {
    my( $self, $type, $index ) = @_;
    return $self->_index_map->{$type}{$index}
        if exists $self->_index_map->{$type}{$index};
    my $offset = $self->_index_map->{$type}{$index} = $self->_code->stack_size;
    ++$self->_code->{stack_size};
    return $offset;
}

sub _temporary {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'lexical', index => _temporary_index( $self, IDX_TEMPORARY, $op->{attributes}{index} ) );
}

sub _temporary_set {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'lexical_set', index => _temporary_index( $self, IDX_TEMPORARY, $op->{attributes}{index} ) );
}

sub _temporary_clear {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'lexical_clear', index => _temporary_index( $self, IDX_TEMPORARY, $op->{attributes}{index} ) );
}

sub _map_index {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}},
            index => _temporary_index( $self, IDX_TEMPORARY, $op->{attributes}{index} ),
            );
}

sub _map_slot_index {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}},
            name  => $op->{attributes}{name},
            slot  => $sigil_to_slot{$op->{attributes}{slot}},
            index => _temporary_index( $self, IDX_TEMPORARY, $op->{attributes}{index} ),
            );
}

sub _map_lexical_index {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( $NUMBER_TO_NAME{$op->{opcode_n}},
            index   => _temporary_index( $self, IDX_TEMPORARY, $op->{attributes}{index} ),
            lexical => $op->{attributes}{lexical},
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

sub _match {
    my( $self, $bytecode, $op ) = @_;
    my %params = $op->{attributes} ? %{$op->{attributes}} : ();
    $params{pos} = $op->{pos} if $op->{pos};
    $params{index} = _temporary_index( $self, IDX_REGEX, $op->{attributes}{index} );

    push @$bytecode,
         o( ( $params{flags} & FLAG_RX_GLOBAL ) ? 'rx_match_global' :
                                                  'rx_match', %params );
}

sub _replace {
    my( $self, $bytecode, $op ) = @_;
    my %params = %{$op->{attributes}};
    delete $params{to};
    $params{pos} = $op->{pos} if $op->{pos};
    $params{index} = _temporary_index( $self, IDX_REGEX, $op->{attributes}{index} );

    push @$bytecode,
         o( ( $params{flags} & FLAG_RX_GLOBAL ) ? 'rx_replace_global' :
                                                  'rx_replace', %params );
    push @{$self->_block_map->{$op->{attributes}{to}}}, $bytecode->[-1];
}


sub _transliterate {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'rx_transliterate',
            match       => join( '', @{$op->{attributes}{match}} ),
            replacement => join( '', @{$op->{attributes}{replacement}} ),
            flags       => $op->{attributes}{flags} );
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

sub _rx_state_restore {
    my( $self, $bytecode, $op ) = @_;

    push @$bytecode,
         o( 'rx_state_restore', index => _temporary_index( $self, IDX_REGEX, $op->{attributes}{index} ) );
}

# quick and dirty, and adequate for the Toy runtime
my %element_map =
  ( WORDS      => '\\w',
    NOT_WORDS  => '\\W',
    DIGITS     => '\\d',
    NOT_DIGITS => '\\D',
    SPACES     => '\\s',
    NOT_SPACES => '\\S',
    alpha      => '[[:alpha:]]',
    alnum      => '[[:alnum:]]',
    ascii      => '[[:ascii:]]',
    blank      => '[[:blank:]]',
    cntrl      => '[[:cntrl:]]',
    digit      => '[[:digit:]]',
    graph      => '[[:graph:]]',
    lower      => '[[:lower:]]',
    print      => '[[:print:]]',
    punct      => '[[:punct:]]',
    space      => '[[:space:]]',
    upper      => '[[:upper:]]',
    word       => '[[:word:]]',
    xdigit     => '[[:xdigit:]]',
    );

sub _rx_class {
    my( $self, $bytecode, $op ) = @_;
    my $elements = '';
    my @special;

    foreach my $e ( @{$op->{attributes}{elements}} ) {
        if( $e->{opcode_n} == OP_RX_EXACT ) {
            $elements .= $e->{attributes}{string};
        } elsif( $e->{opcode_n} == OP_RX_EXACT_I ) {
            $elements .= lc $e->{attributes}{string} .
                         uc $e->{attributes}{string};
        } elsif( $e->{opcode_n} == OP_RX_RANGE ) {
            $elements .= join '', $e->{attributes}{start} ..
                                  $e->{attributes}{end};
        } else {
            die $e->{attributes}{type}
                unless exists $element_map{$e->{attributes}{type}};
            my $c = $element_map{$e->{attributes}{type}};
            push @special, qr/$c/;
        }
    }

    push @$bytecode,
         o( 'rx_class', elements => $elements, special => \@special );
}

sub _rx_special_class {
    my( $self, $bytecode, $op ) = @_;

    die $op->{attributes}{type}
        unless exists $element_map{$op->{attributes}{type}};

    my $c = $element_map{$op->{attributes}{type}};
    push @$bytecode,
         o( 'rx_class', elements => '', special => [ qr/$c/ ] );
}

sub _allocate_lexicals {
    my( $self, $ir_code, $toy_code ) = @_;
    my $pad = $toy_code->lexicals;
    my $needs_pad = 0;

    foreach my $lex_info ( values %{$ir_code->lexicals->{map}} ) {
        unless( $lex_info->{in_pad} ) {
            $toy_code->lexical_init->[$lex_info->{index}] =
              $lex_info->{sigil};
            next;
        }
        $needs_pad ||= 1;
        if( $lex_info->{from_main} ) {
            my $main_pad = $self->_processing->[-$lex_info->{level} - 1]->lexicals;
            $main_pad->add_value_index( $self->runtime, $lex_info, $lex_info->{outer_index} );
            $pad->add_value_index( $self->runtime, $lex_info, $lex_info->{index},
                                   $main_pad->values->[$lex_info->{outer_index}] );
        } else {
            $pad->add_value_index( $self->runtime, $lex_info, $lex_info->{index} );
            push @{$toy_code->{closed}},
                 [$lex_info->{outer_index}, $lex_info->{index}]
                   if $lex_info->{outer_index} >= 0;
            if( $lex_info->{declaration} ) {
                push @{$pad->{clear}{indices}}, $lex_info->{index};
                if( $lex_info->{sigil} == VALUE_SCALAR ) {
                    push @{$pad->{clear}{scalar}}, $lex_info->{index};
                } elsif( $lex_info->{sigil} == VALUE_ARRAY ) {
                    push @{$pad->{clear}{array}}, $lex_info->{index};
                } elsif( $lex_info->{sigil} == VALUE_HASH ) {
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
