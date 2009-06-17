package Language::P::Toy::Value::Hash;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(hash) );

sub type { 13 }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{hash} ||= {};

    return $self;
}

sub clone {
    my( $self, $level ) = @_;

    my $clone = ref( $self )->new( { hash  => { %{$self->{hash}} },
                                     } );

    if( $level > 0 ) {
        foreach my $entry ( values %{$clone->{hash}} ) {
            $entry = $entry->clone( $level - 1 );
        }
    }

    return $clone;
}

sub localize {
    my( $self ) = @_;

    return __PACKAGE__->new;
}

sub assign {
    my( $self, $other ) = @_;

    # FIXME optimize: don't do it unless necessary
    my $oiter = $other->clone( 1 )->iterator;
    $self->assign_iterator( $oiter );
}

sub assign_iterator {
    my( $self, $iter ) = @_;

    $self->{hash} = {};
    while( $iter->next ) {
        my $k = $iter->item;
        $iter->next;
        my $v = $iter->item;
        $self->{hash}{$k->as_string} = $v;
    }
}

sub get_item_or_undef {
    my( $self, $key ) = @_;

    if( !exists $self->{hash}{$key} ) {
        return $self->{hash}{$key} = Language::P::Toy::Value::Undef->new;
    }

    return $self->{hash}{$key};
}

sub set_item {
    my( $self, $key, $value ) = @_;

    if( !exists $self->{hash}{$key} ) {
        $self->{hash}{$key} = Language::P::Toy::Value::Undef->new;
    }

    $self->{hash}{$key}->assign( $value );
}

sub has_item {
    my( $self, $key ) = @_;

    return exists $self->{hash}{$key};
}

sub iterator {
    my( $self ) = @_;

    return Language::P::Toy::Value::Array->new
               ( { array => [ map { Language::P::Toy::Value::Scalar
                                        ->new_string( $_ ),
                                    $self->{hash}->{$_} }
                                  keys %{$self->hash} ] } )
               ->iterator;
}

1;
