package Language::P::Toy::Runtime;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Toy::Value::MainSymbolTable;
use Language::P::ParseTree qw(:all);

__PACKAGE__->mk_ro_accessors( qw(symbol_table _variables) );
__PACKAGE__->mk_accessors( qw(parser) );

our $current;

sub new {
    my( $class, $args ) = @_;

    Carp::confess( "Only one runtime supported" ) if $current;

    my $self = $class->SUPER::new( $args );

    $self->{symbol_table} ||= Language::P::Toy::Value::MainSymbolTable->new;
    $self->{_variables} = { osname      => $^O,
                            };

    return $current = $self;
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
    my( $self, $program, $context ) = @_;

    $context ||= CXT_VOID;
    my $code = $self->parser->parse_file( $program, $context != CXT_VOID );
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
    my( $self, $string, $context, $lexicals, $generator_context ) = @_;
    $context ||= CXT_VOID;

    $self->parser->generator->_eval_context( $generator_context );
    # FIXME propagate runtime package
    my $code = $self->parser->parse_string( $string, 'main',
                                            $context != CXT_VOID, $lexicals );
    $self->make_closure( $code );
    $self->run_last_file( $code, $context );
}

sub compile_regex {
    my( $self, $string ) = @_;
    # FIXME encapsulation
    my $parser = Language::P::Parser::Regex->new
                     ( { runtime     => $self,
                         generator   => $self->parser->generator,
                         interpolate => 1,
                         } );
    my $parsed_rx = $parser->parse_string( $string );
    my $pattern = Language::P::ParseTree::Pattern->new
                      ( { components => $parsed_rx,
                          } );
    my $re = $self->parser->generator->process_regex( $pattern );

    return $re;
}

sub search_file {
    my( $self, $file_str ) = @_;
    my $inc = $self->symbol_table->get_symbol( 'INC', '@', 1 );

    for( my $it = $inc->iterator; $it->next; ) {
        my $path = $it->item->as_string . '/' . $file_str;
        if( -f $path ) {
            return Language::P::Toy::Value::StringNumber->new( { string => $path } );
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

    for(;;) {
        my $op = $self->{_bytecode}->[$self->{_pc}];
        my $pc = $op->{function}->( $op, $self, $self->{_pc} );

        last if $pc < 0;
        $self->{_pc} = $pc;
    }
}

sub stack_copy {
    my( $self ) = @_;

    return @{$self->{_stack}};
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

1;
