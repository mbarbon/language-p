package Language::P::Toy::Runtime;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Toy::Value::MainSymbolTable;
use Language::P::ParseTree qw(:all);
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

    return $self;
}

sub set_option {
    my( $self, $option, $value ) = @_;

    $self->parser->set_option( $option, $value );
}

sub reset {
    my( $self ) = @_;

    $self->{_stack} = [ [ -2, undef, CXT_VOID ], undef ];
    $self->{_frame} = @{$self->{_stack}};
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
    my $frame = $self->push_frame( $code->stack_size + 2 );
    my $stack = $self->{_stack};
    $stack->[$frame - 2] = [ -2, $self->{_bytecode}, $context, $self->{_code} ];
    $stack->[$frame - 1] = $code->lexicals || 'no_pad';
    $self->set_bytecode( $code->bytecode );
    $self->{_pc} = 0;
    $self->{_code} = $code;

    $self->run;
}

sub run_file {
    my( $self, $program, $is_main, $context ) = @_;

    $context ||= CXT_VOID;
    my $parser = $self->parser->safe_instance;
    my $code = do {
        local $self->{_parser} = $parser;
        my $flags =   ( $context != CXT_VOID ? PARSE_ADD_RETURN : 0 )
                    | ( $is_main             ? PARSE_MAIN : 0 );
        $parser->parse_file( $program, $flags );
    };
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
    my $code = do {
        local $self->{_parser} = $parser;
        $parser->generator->_eval_context( $generator_context );
        my $flags = $context != CXT_VOID ? PARSE_ADD_RETURN : 0;
        $parser->parse_string( $string, $flags, $lexical_state );
    };
    $self->make_closure( $code );
    $self->run_last_file( $code, $context );
}

sub compile_regex {
    my( $self, $string ) = @_;
    # FIXME encapsulation
    my $generator = $self->parser->generator->safe_instance;
    my $parser = Language::P::Parser::Regex->new
                     ( { runtime     => $self,
                         generator   => $generator,
                         interpolate => 1,
                         } );
    my $parsed_rx = $parser->parse_string( $string );
    my $pattern = Language::P::ParseTree::Pattern->new
                      ( { components => $parsed_rx,
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

    die "Can't find '$file_str'";
}

sub call_subroutine {
    my( $self, $code, $context, $args ) = @_;

    push @{$self->{_stack}}, $args;
    $code->call( $self, -2, $context );
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
        if( $e->isa( 'Language::P::Exception' ) ) {
            $self->{_pc} = $self->throw_exception( $e );
            goto &run;
        } else {
            die;
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

    return { file => $op->{pos}[0],
             line => $op->{pos}[1],
             code => $self->{_code},
             };
}

sub frame_info {
    my( $self, $level ) = @_;
    my $frame = $self->{_frame};
    my $stack = $self->{_stack};

    for( ; $level; --$level ) {
        $frame = $stack->[$frame]->[1];
    }
    my $op = $stack->[$frame - 2][1][$stack->[$frame - 2][0]];

    return { file => $op->{pos}[0],
             line => $op->{pos}[1],
             code => $stack->[$frame - 2][3],
             };
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
    my( $self, $size ) = @_;
    my $last_frame = $self->{_stack}->[$self->{_frame}];

    # TODO unwind

    $#{$self->{_stack}} = $last_frame->[0];
    $self->{_frame} = $last_frame->[1];
}

sub call_return {
    my( $self ) = @_;
    my $rpc = $self->{_stack}->[$self->{_frame} - 2][0];
    my $bytecode = $self->{_stack}->[$self->{_frame} - 2][1];

    $self->set_bytecode( $bytecode );
    $self->{_code} = $self->{_stack}->[$self->{_frame} - 2][3];
    $self->pop_frame;

    return $rpc;
}

sub throw_exception {
    my( $self, $exc ) = @_;

    for(;;) {
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

            if( $scope->{flags} & 2 ) {
                my $scalar = Language::P::Toy::Value::Scalar->new_string
                                 ( $self, $exc->full_message );
                $self->symbol_table->set_symbol( $self, '@', '$', $scalar );
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

sub get_symbol {
    my( $self, $name, $sigil ) = @_;

    return $self->symbol_table->get_symbol( $self, $name, $sigil );
}

sub get_package {
    my( $self, $name ) = @_;

    return $self->symbol_table->get_package( $self, $name );
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

    return Language::P::Toy::Value->new_integer
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

1;
