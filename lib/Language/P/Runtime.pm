package Language::P::Runtime;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Value::MainSymbolTable;
use Language::P::ParseTree qw(:all);

__PACKAGE__->mk_ro_accessors( qw(symbol_table _variables) );

our $current;

sub new {
    my( $class, $args ) = @_;

    Carp::confess( "Only one runtime supported" ) if $current;

    my $self = $class->SUPER::new( $args );

    $self->{symbol_table} ||= Language::P::Value::MainSymbolTable->new;
    $self->{_variables} = { osname      => $^O,
                            };

    return $current = $self;
}

sub reset {
    my( $self ) = @_;

    $self->{_stack} = [ [ -1, undef, CXT_VOID ], undef ];
    $self->{_frame} = @{$self->{_stack}};
}

sub run_last_file {
    my( $self, $code ) = @_;

    $self->set_bytecode( $code->bytecode );
    $self->{_stack} = [ [ -1, undef, CXT_VOID ], $code->lexicals ];
    $self->{_frame} = @{$self->{_stack}};
    return $self->run;
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

#     use Data::Dumper;
#     print Dumper( $self->{_bytecode} );

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

#    print "Stack size: $stack_size -> $self->{_frame}\n";

    return $self->{_frame};
}

sub pop_frame {
    my( $self, $size ) = @_;
    my $last_frame = $self->{_stack}->[$self->{_frame}];

#    print "New stack size: $last_frame->[0]\n";

    # TODO unwind

    $#{$self->{_stack}} = $last_frame->[0];
    $self->{_frame} = $last_frame->[1];
}

sub call_return {
    my( $self ) = @_;
    my $rpc = $self->{_stack}->[$self->{_frame} - 2][0];
    my $bytecode = $self->{_stack}->[$self->{_frame} - 2][1];

    $self->set_bytecode( $bytecode );
    $self->pop_frame;

    return $rpc;
}

1;
