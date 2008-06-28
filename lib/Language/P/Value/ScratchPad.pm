package Language::P::Value::ScratchPad;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

use Language::P::Value::StringNumber;

__PACKAGE__->mk_ro_accessors( qw(outer names values is_subroutine
                                 all_in_pad) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{values} ||= [];
    $self->{names} ||= {};

    return $self;
}

sub new_scope {
    my( $self, $outer_scope ) = @_;

    # FIXME lexical initialization
    my @values = map { Language::P::Value::StringNumber->new }
                     0 .. $#{$self->values};
    return ref( $self )->new( { outer  => $outer_scope,
                                values => \@values,
                                } );
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
                { index  => -100, # filled in at scope close
                  in_pad => $self->all_in_pad ? 1 : 0,
                  sigil  => $sigil,
                  };
    # allocate at compile time if necessary
    if( $self->all_in_pad ) {
        $s->{index} = $self->add_value( $sigil );
    }

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

sub close_scope {
    my( $self ) = @_;

    # move to stack values not in pad
}

sub add_value {
    my( $self, $sigil ) = @_;

    # FIXME lexical initialization
    push @{$self->values}, Language::P::Value::StringNumber->new;

    return $#{$self->values};
}

1;
