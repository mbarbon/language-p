package Language::P::Parser::Lexicals;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(outer names is_subroutine
                                 all_in_pad) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{names} ||= {};

    return $self;
}

sub _find_name {
    my( $self, $name, $crossed_sub ) = @_;

    return ( $crossed_sub, $self->names->{$name} )
        if exists $self->names->{$name};
    return _find_name( $self->outer, $name,
                       $crossed_sub + $self->is_subroutine ) if $self->outer;
    return ( 0, undef );
}

sub find_name {
    my( $self, $name ) = @_;

    return _find_name( $self, $name, 0 );
}

sub add_name {
    my( $self, $sigil, $name ) = @_;

    my $s = $self->names->{$sigil . $name} =
                { in_pad => $self->all_in_pad ? 1 : 0,
                  name   => $name,
                  sigil  => $sigil,
                  };

    return ( 0, $s );
}

sub keep_in_pad {
    my( $self, $name ) = @_;

    my $slot = $self->find_name( $name );
    die "Missing name '$name'" unless $slot;

    $slot->{in_pad} = 1;
}

sub keep_all_in_pad {
    my( $self ) = @_;

    foreach my $slot ( values %{$self->names} ) {
        $slot->{in_pad} = 1;
    }
    $self->outer->keep_all_in_pad if $self->outer;
}

1;
