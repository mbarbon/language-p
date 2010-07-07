package Language::P::Toy::Runtime;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Toy::Value::MainSymbolTable;
use Language::P::Constants qw(:all);
use Language::P::Parser qw(:all);

__PACKAGE__->mk_ro_accessors( qw(symbol_table _variables _parser) );
__PACKAGE__->mk_accessors( qw(parser) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{symbol_table} ||= Language::P::Toy::Value::MainSymbolTable->new( $self );
    $self->{_variables} = { osname      => $^O,
                            hints       => 0,
                            };
    $self->{_frame} = -1;
    $self->{_stack} = [];
    $self->{_eval_count} = 0;

    return $self;
}

sub set_option {
    my( $self, $option, $value ) = @_;

    $self->parser->set_option( $option, $value );
}

sub reset {
    my( $self ) = @_;

    $self->{_stack} = [ [ -2, undef, CXT_VOID, undef, {} ], undef ];
    $self->{_frame} = @{$self->{_stack}};
    $self->{_last_match} =
      { captures        => [],
        string_captures => [],
        };
}

sub set_data_handle {
    my( $self, $package, $handle ) = @_;
    my $data = $self->symbol_table->get_package( $self, $package )
                    ->get_symbol( $self, 'DATA', '*', 1 );

    $data->set_slot( $self, 'io', Language::P::Toy::Value::Handle->new
                                      ( $self, { handle => $handle } ) );
}

sub run_last_file {
    my( $self, $code, $context ) = @_;
    # FIXME duplicates Language::P::Toy::Value::Code::call
    my $frame = $self->push_frame( $code->stack_size + 3 );
    my $stack = $self->{_stack};
    $stack->[$frame - 2] = [ -2, $self->{_bytecode}, $context, $self->{_code}, $self->{_lex}, undef ];
    $stack->[$frame - 1] = $code->lexicals || 'no_pad';
    $self->set_bytecode( $code->bytecode );
    $self->{_pc} = 0;
    $self->{_code} = $code;
    $self->{_lex} =
        { package  => 'main',
          hints    => 0,
          warnings => undef,
          };

    $self->run;
}

sub _before_parse {
    my( $self, $program_name ) = @_;

    $self->{_code} = undef;
    $self->{_bytecode} = undef;
    $self->{_pc} = 0;
    $self->{_lex} =
        { package  => 'main',
          hints    => 0,
          warnings => undef,
          };
}

sub _after_parse {
    my( $self, $program_name ) = @_;

    $self->{_code} = undef;
    $self->{_bytecode} = undef;
    $self->{_pc} = 0;
    $self->{_lex} = undef;
}

sub run_file {
    my( $self, $program, $is_main, $context ) = @_;

    $context ||= CXT_VOID;
    my $parser = $self->parser->safe_instance;
    $self->_before_parse( $program ) if $is_main;
    my $code = do {
        local $self->{_parser} = $parser;
        my $flags =   PARSE_ADD_RETURN
                    | ( $is_main             ? PARSE_MAIN : 0 );
        local $self->{_variables}{hints} = 0;
        local $self->{_variables}{warnings} = "";
        $parser->parse_file( $program, $flags );
    };
    $self->_after_parse( $program ) if $is_main;
    $self->run_last_file( $code, $context );
}

sub run_string {
    my( $self, $program, $program_name, $is_main, $context ) = @_;

    $context ||= CXT_VOID;
    my $parser = $self->parser->safe_instance;
    $self->_before_parse( $program_name ) if $is_main;
    my $code = do {
        local $self->{_parser} = $parser;
        my $flags =   ( $context != CXT_VOID ? PARSE_ADD_RETURN : 0 )
                    | ( $is_main             ? PARSE_MAIN : 0 );
        local $self->{_variables}{hints} = 0;
        local $self->{_variables}{warnings} = "";
        $parser->parse_string( $program, $flags, $program_name );
    };
    $self->_after_parse( $program ) if $is_main;
    $self->run_last_file( $code, $context );
}

# maybe put in teh code object
sub make_closure {
    my( $self, $code ) = @_;

    if( my $closed_values = $code->closed ) {
        my $outer_pad = $self->{_stack}->[$self->{_frame} - 1];
        my $pad = $code->lexicals;

        foreach my $from_to ( @$closed_values ) {
            $pad->values->[$from_to->[1]] = $outer_pad->values->[$from_to->[0]];
        }
    }
}

sub eval_string {
    my( $self, $string, $context, $lexical_state, $generator_context ) = @_;
    $context ||= CXT_VOID;

    my $parser = $self->parser->safe_instance;
    my $eval_name = sprintf "(eval %d)", ++$self->{_eval_count};
    my $code = eval {
        local $self->{_parser} = $parser;
        $parser->generator->_eval_context( $generator_context );
        my $flags = $context != CXT_VOID ? PARSE_ADD_RETURN : 0;
        $parser->parse_string( $string, $flags, $eval_name, $lexical_state );
    };
    if( my $e = $@ ) {
        if( $e->isa( 'Language::P::Exception' ) ) {
            $self->set_exception( $e );
            $self->return_undef( $context );
            return;
        } else {
            die;
        }
    }
    $self->make_closure( $code );
    $self->run_last_file( $code, $context );
}

sub compile_regex {
    my( $self, $string, $flags ) = @_;
    # FIXME encapsulation
    my $generator = $self->parser->generator->safe_instance;
    my $parser = Language::P::Parser::Regex->new
                     ( { runtime     => $self,
                         generator   => $generator,
                         interpolate => 1,
                         flags       => $flags,
                         } );
    my $parsed_rx = $parser->parse_string( $string );
    my $pattern = Language::P::ParseTree::Pattern->new
                      ( { components => $parsed_rx,
                          flags      => $flags,
                          } );
    my $re = $generator->process_regex( $pattern );

    return $re;
}

sub search_file {
    my( $self, $file_str ) = @_;
    my $inc = $self->symbol_table->get_symbol( $self, 'INC', '@', 1 );

    for( my $it = $inc->iterator( $self ); $it->next( $self ); ) {
        my $path = $it->item->as_string( $self ) . '/' . $file_str;
        if( -f $path ) {
            return Language::P::Toy::Value::StringNumber->new( $self, { string => $path } );
        }
    }

    my $info = $self->current_frame_info;
    my $message = sprintf 'Can\'t locate %s in @INC', $file_str;

    Language::P::Toy::Exception->throw
        ( message  => $message,
          position => [ $info->{file}, $info->{line} ],
          );
}

sub call_subroutine {
    my( $self, $code, $context, $args, $pos ) = @_;

    push @{$self->{_stack}}, $args;
    $code->call( $self, -2, $context );
    # TODO allow setting hints and warnings as well?
    local $self->{_stack}->[$self->{_frame} - 2][5] = $pos if $pos;
    $self->run;
}

sub set_bytecode {
    my( $self, $bytecode ) = @_;

    $self->{_pc} = 0;
    $self->{_bytecode} = $bytecode;
}

sub run_bytecode {
    my( $self, $bytecode ) = @_;

    $self->set_bytecode( $bytecode );
    $self->run;
}

sub run {
    my( $self ) = @_;

    return if $self->{_pc} < 0;

    eval {
        for(;;) {
            my $op = $self->{_bytecode}->[$self->{_pc}];
            my $pc = $op->{function}->( $op, $self, $self->{_pc} );

            last if $pc < 0;
            $self->{_pc} = $pc;
        }
    };
    if( my $e = $@ ) {
        if( ref( $e ) && $e->isa( 'Language::P::Exception' ) ) {
            $self->{_pc} = $self->throw_exception( $e );
            goto &run;
        } else {
            die $e;
        }
    }
}

sub stack_copy {
    my( $self ) = @_;

    return @{$self->{_stack}};
}

sub current_frame_info {
    my( $self ) = @_;
    my $op = $self->{_bytecode}[$self->{_pc}];

    return { file       => $op->{pos}[0],
             line       => $op->{pos}[1],
             code       => $self->{_code},
             code_name  => $self->{_code}->name,
             context    => $self->{_stack}[$self->{_frame} - 2][2],
             package    => $self->{_lex}{package},
             hints      => $self->{_lex}{hints},
             warnings   => $self->{_lex}{warnings},
             flags      => $self->{_code}->scopes->[0]->{flags},
             };
}

sub _frame_info {
    my( $self, $frame ) = @_;
    my $stack = $self->{_stack};

    my $op = $stack->[$frame - 2][1][$stack->[$frame - 2][0]];
    my $lex = $stack->[$frame - 2][4];
    my $code = $stack->[$frame - 2][3];
    my $pos = $stack->[$frame - 2][5] || $op->{pos};

    return { file       => $pos->[0],
             line       => $pos->[1],
             code       => $code,
             code_name  => $code && $code->name,
             context    => $stack->[$frame - 2][2],
             package    => $lex->{package},
             hints      => $lex->{hints},
             warnings   => $lex->{warnings},
             flags      => $code && $code->scopes->[0]->{flags},
             };
}

sub frame_info {
    my( $self, $level ) = @_;
    my $frame = $self->{_frame};
    my $stack = $self->{_stack};

    for( ; $frame >= 0 && $level; --$level ) {
        $frame = $stack->[$frame]->[1];
    }
    if( $frame < 0 ) {
        return undef;
    }

    return _frame_info( $self, $frame );
}

sub _find_eval_scope {
    my( $code, $pc, $level ) = @_;
    my $scope;

    foreach my $s ( @{$code->scopes} ) {
        if( $s->{start} <= $pc && $s->{end} > $pc ) {
            $scope = $s;
        }
    }

    while( $scope ) {
        if( $scope->{flags} & 2 ) {
            if( $level == 0 ) {
                return ( $scope, 0 );
            }
            --$level;
        }

        last if $scope->{outer} < 0;
        $scope = $code->scopes->[$scope->{outer}];
    }

    return ( undef, $level );
}

sub frame_info_caller {
    my( $self, $level ) = @_;
    my $frame = $self->{_frame};
    my $code = $self->{_code};
    my $pc = $self->{_pc};
    my( $eval_scope, $outer );

    UNWIND: for( ; $frame >= 0; --$level) {
        ( $eval_scope, $level ) = _find_eval_scope( $code, $pc, $level );

        last if $eval_scope;

        $outer = 1;
        $pc = $self->{_stack}->[$frame - 2][0];
        last if $level == 0;
        $code = $self->{_stack}->[$frame - 2][3];
        $frame = $self->{_stack}->[$frame][1];
    }

    my $info;
    if( $outer ) {
        $info = _frame_info( $self, $frame );
        $info->{code_name} = $code->name;

        ( $eval_scope ) = _find_eval_scope( $code, $pc, 0 );
    } else {
        $info = $self->current_frame_info;
    }

    return undef if $frame <= 2 && !$eval_scope;

    if( $eval_scope ) {
        my $eval_cxt = CXT_CALLER;
        my $scope = $eval_scope;
        while( $eval_cxt == CXT_CALLER ) {
            $eval_cxt = $scope->{context} if $scope->{flags} & 2;
            last if $scope->{outer} < 0;
            $scope = $code->scopes->[$scope->{outer}];
        }

        $info->{file} = $eval_scope->{pos_s}[0];
        $info->{line} = $eval_scope->{pos_s}[1];
        $info->{flags} = $eval_scope->{flags};
        $info->{context} = $eval_cxt if $eval_cxt && $eval_cxt != CXT_CALLER;
        $info->{code_name} = '(eval)';
        $info->{hints} = $eval_scope->{hints};
        $info->{warnings} = $eval_scope->{warnings};
        $info->{package} = $eval_scope->{package};
    }

    return $info;
}

sub push_frame {
    my( $self, $size ) = @_;
    my $last_frame = $self->{_frame};
    my $stack_size = $#{$self->{_stack}};

    $#{$self->{_stack}} = $self->{_frame} = $stack_size + $size + 1;
    $self->{_stack}->[$self->{_frame}] = [ $stack_size, $last_frame ];

    return $self->{_frame};
}

sub pop_frame {
    my( $self ) = @_;
    my $last_frame = $self->{_stack}->[$self->{_frame}];

    $#{$self->{_stack}} = $last_frame->[0];
    $self->{_frame} = $last_frame->[1];
}

sub call_return {
    my( $self ) = @_;
    my $rpc = $self->{_stack}->[$self->{_frame} - 2][0];
    my $bytecode = $self->{_stack}->[$self->{_frame} - 2][1];

    $self->set_bytecode( $bytecode );
    $self->{_code} = $self->{_stack}->[$self->{_frame} - 2][3];
    $self->{_lex} = $self->{_stack}->[$self->{_frame} - 2][4];
    $self->pop_frame;

    return $rpc;
}

sub return_undef {
    my( $self, $context ) = @_;
    my $undef = Language::P::Toy::Value::Undef->new( $self );

    if ( $context == CXT_SCALAR ) {
        push @{$self->{_stack}}, $undef;
    } else {
        push @{$self->{_stack}},
          Language::P::Toy::Value::List->new
              ( $self, { array => [ $undef ] } );
    }
}

sub set_exception {
    my( $self, $exc ) = @_;

    my $scalar = Language::P::Toy::Value::Scalar->new_string
                     ( $self, $exc->full_message );
    $self->symbol_table->set_symbol( $self, '@', '$', $scalar );
}

sub throw_exception {
    my( $self, $exc, $fill_position ) = @_;

    for(; $self->{_frame} > 0;) {
        my $info = $self->current_frame_info;
        my $scope;

        if( $fill_position ) {
            $exc->position( [ $info->{file}, $info->{line} ] );
            $fill_position = 0;
        }

        foreach my $s ( @{$info->{code}->scopes} ) {
            if( $s->{start} <= $self->{_pc} && $s->{end} > $self->{_pc} ) {
                $scope = $s;
            }
        }

        while( $scope ) {
            eval {
                # TODO catch exceptions during stack unwinding
                local $self->{_pc};
                local $self->{_bytecode};

                $self->run_bytecode( $scope->{bytecode} );
            };
            die "Exception during stack unwind: $@" if $@;

            if( $scope->{flags} & 2 ) {
                $self->set_exception( $exc );
                # no need to add an undef return value for eval EXPR:
                # exception code lands on the dummy return at the end
                # of the generated segment
                $self->return_undef( $scope->{context} )
                    if $scope->{flags} == 2;

                return $scope->{end};
            }

            last if $scope->{outer} < 0;
            $scope = $info->{code}->scopes->[$scope->{outer}];
        }

        my $rpc = $self->call_return;
        last if $rpc < 0; # main scope of script/required module
        $self->{_pc} = $rpc + 1;
    }

    die $exc;
}

sub exit_subroutine {
    my( $self ) = @_;

    my $info = $self->current_frame_info;
    my $scope;

    foreach my $s ( @{$info->{code}->scopes} ) {
        if( $s->{start} <= $self->{_pc} && $s->{end} > $self->{_pc} ) {
            $scope = $s;
        }
    }

    while( $scope ) {
        eval {
            # TODO catch exceptions during stack unwinding
            local $self->{_pc};
            local $self->{_bytecode};

            $self->run_bytecode( $scope->{bytecode} );
        };
        die "Exception during stack unwind: $@" if $@;

        last if $scope->{outer} < 0;
        $scope = $info->{code}->scopes->[$scope->{outer}];
    }
}

sub get_symbol {
    my( $self, $name, $sigil ) = @_;

    return $self->symbol_table->get_symbol( $self, $name, $sigil );
}

sub get_package {
    my( $self, $name ) = @_;

    return $self->symbol_table->get_package( $self, $name );
}

sub is_declared {
    my( $self, $name, $sigil ) = @_;
    my $glob = $self->symbol_table->get_symbol( $self, $name, '*', 0 );

    return $glob && ( $glob->imported & ( 1 << $sigil - 1 ) );
}

sub set_hints {
    my( $self, $value ) = @_;

    $self->{_variables}{hints} = $value->as_integer;
    $self->{_parser}->set_hints( $self->{_variables}{hints} )
      if $self->{_parser};
}

sub get_hints {
    my( $self ) = @_;

    return Language::P::Toy::Value::Scalar->new_integer
               ( $self, $_[0]->{_variables}{hints} );
}

sub set_warnings {
    my( $self, $value ) = @_;

    $self->{_variables}{warnings} = $value->as_string;
    $self->{_parser}->set_warnings( $self->{_variables}{warnings} )
      if $self->{_parser};
}

sub get_warnings {
    my( $self ) = @_;

    return Language::P::Toy::Value::Scalar->new_string
               ( $self, $_[0]->{_variables}{warnings} );
}

sub warning {
    my( $self, $file, $line, $message ) = @_;

    if( substr( $message, -1 ) eq "\n" ) {
        print STDERR $message;
    } else {
        print STDERR $message, ' at ', $file, ' line ', $line, "\n";
    }
}

sub warning_if {
    my( $self, $category, $file, $line, $message ) = @_;

    return unless defined $self->{_variables}{warnings};
    my $offset = $warnings::Offsets{$category};
    my $offset_all = $warnings::Offsets{$category};
    return unless vec($self->{_variables}{warnings}, $offset, 1) ||
                  vec($self->{_variables}{warnings}, $offset_all, 1) ;
    $self->warning( $file, $line, $message );
}

sub set_last_match {
    my( $self, $match ) = @_;

    $self->{_last_match} = $match;
}

sub get_last_match {
    my( $self ) = @_;

    return $self->{_last_match};
}

sub wrap_method {
    {
        package Language::P::Toy::Value::WrappedSub;

        sub prototype { Language::P::Constants::PROTO_DEFAULT }
        sub call { shift->( @_ ) }
    }

    my( $self, $receiver, $method ) = @_;

    my $sub = sub {
        my( $self, $runtime, $pc, $context ) = @_;
        my $args = pop @{$runtime->{_stack}};

        $receiver->$method( $runtime, $pc, $context, $args );
        push @{$runtime->{_stack}},
             Language::P::Toy::Value::List->new( $runtime );

        return $pc + 1;
    };
    bless $sub, 'Language::P::Toy::Value::WrappedSub';

    return $sub;
}

sub add_overload {
    my( $self, $runtime, $pc, $context, $args ) = @_;
    my $pack = $args->get_item( $runtime, 0 )->as_string( $runtime );
    my $list = $args->get_item( $runtime, 1 )->reference;
    my %val;

    for( my $iter = $list->iterator( $runtime ); $iter->next; ) {
        my $key = $iter->item->as_string( $runtime );
        $iter->next;
        my $code = $iter->item;

        $val{$key} = $code;
    }

    my $stash = $runtime->symbol_table->get_package( $runtime, $pack, 0 );
    $stash->{overload} = \%val;
}

1;
