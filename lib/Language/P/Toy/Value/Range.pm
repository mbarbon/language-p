package Language::P::Toy::Value::Range;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(start end current) );

sub type { 17 }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{start} = $self->{start}->as_integer( $runtime );
    $self->{end} = $self->{end}->as_integer( $runtime );
    $self->{current} = $self->{start} - 1;

    return $self;
}

sub clone {
    my( $self, $runtime, $level ) = @_;

    return $self;
}

sub iterator {
    my( $self, $runtime ) = @_;

    return $self;
}

sub next {
    my( $self, $runtime ) = @_;
    ++$self->{current};
    return $self->{current} <= $self->{end} ? 1 : 0;
}

sub item {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Scalar->new_integer
               ( $runtime, $self->{current} );
}

1;
