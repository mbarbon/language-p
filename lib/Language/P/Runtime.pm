package Language::P::Runtime;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Value::SymbolTable;

__PACKAGE__->mk_ro_accessors( qw(symbol_table) );
__PACKAGE__->mk_ro_accessors( qw(_stack _pc _bytecode _frame) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{symbol_table} ||= Language::P::Value::SymbolTable->new;

    return $self;
}

sub reset {
    my( $self ) = @_;

    $self->{_stack} = [];
    $self->{_frame} = @{$self->{_stack}};
}

sub run_last_file {
    my( $self, $code ) = @_;

    $self->reset;
    $self->set_bytecode( $code->bytecode );
    $self->{_stack} = [ $code->lexicals ];
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

    return if $self->_pc < 0;

#     use Data::Dumper;
#     print Dumper( $self->_bytecode );

    for(;;) {
        my $op = $self->_bytecode->[$self->_pc];
        my $pc = $op->{function}->( $op, $self, $self->_pc );

        last if $pc < 0;
        $self->{_pc} = $pc;
    }
}

sub stack_copy {
    my( $self ) = @_;

    return @{$self->_stack};
}

sub push_frame {
    my( $self, $size ) = @_;
    my $last_frame = $self->_frame;
    my $stack_size = $#{$self->_stack};

    $#{$self->{_stack}} = $self->{_frame} = $stack_size + 1 + $size + 1;
    $self->{_stack}->[-1] = [ $stack_size, $last_frame ];

#    print "Stack size: $stack_size -> $self->{_frame}\n";

    return $self->_frame;
}

sub pop_frame {
    my( $self, $size ) = @_;
    my $last_frame = $self->_stack->[$self->_frame];

#    print "New stack size: $last_frame->[0]\n";

    # TODO unwind

    $#{$self->_stack} = $last_frame->[0];
    $self->{_frame} = $last_frame->[1];
}

1;
