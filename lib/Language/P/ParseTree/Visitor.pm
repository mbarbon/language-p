package Language::P::ParseTree::Visitor;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    return $self;
}

sub _superclasses {
    my( $class ) = @_;

    no strict 'refs';
    return @{$class . '::ISA'};
}

sub _find_method {
    my( $self, $map, $class ) = @_;
    my $method = $map->{$class};
    return $method if $method;

    my @bases = _superclasses( $class );
    while( !$method && @bases ) {
        my $base = shift @bases;
        $method = $map->{$base};
        push @bases, _superclasses( $base );
    }

    if( !$method && $map->{DEFAULT} ) {
        $method = $map->{$class} = $map->{DEFAULT}
    }

    Carp::confess "No method for '$class'" unless $method;

    # use the map as a cache to speed-up lookup
    return $map->{$class} = $method;
}

sub visit {
    my( $self, $tree, @args ) = @_;
    my $method = _find_method( $self, $self->method_map, ref( $tree ) );

    return $self->$method( $tree, @args );
}

sub visit_map {
    my( $self, $map, $tree, @args ) = @_;
    my $method = _find_method( $self, $map, ref( $tree ) );

    return $self->$method( $tree, @args );
}

1;
