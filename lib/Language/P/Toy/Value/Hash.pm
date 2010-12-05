package Language::P::Toy::Value::Hash;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(hash) );

sub type { 13 }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{hash} ||= {};
    $self->{iterator} ||= undef;

    return $self;
}

sub clone {
    my( $self, $runtime, $level ) = @_;

    my $clone = ref( $self )->new( $runtime,
                                   { hash  => { %{$self->{hash}} },
                                     } );

    if( $level > 0 ) {
        foreach my $entry ( values %{$clone->{hash}} ) {
            $entry = $entry->clone( $runtime, $level - 1 );
        }
    }

    return $clone;
}

sub as_boolean_int {
    my( $self, $runtime ) = @_;

    return %{$self->{hash}} ? 1 : 0;
}

sub is_defined {
    my( $self, $runtime ) = @_;

    return scalar %{$self->{hash}} ? 1 : 0;
}

sub localize {
    my( $self, $runtime ) = @_;

    return __PACKAGE__->new( $runtime );
}

sub localize_element {
    my( $self, $runtime, $key ) = @_;
    # if there is no key, it is ok to return undef
    my $value = $self->{hash}->{$key};
    my $new = Language::P::Toy::Value::Undef->new( $runtime );

    $self->{hash}->{$key} = $new;

    return $value;
}

sub assign { assign_array( @_ ) }

sub assign_array {
    my( $self, $runtime, $other ) = @_;

    # FIXME optimize: don't do it unless necessary
    my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
    return $self->assign_iterator( $runtime, $oiter );
}

sub assign_iterator {
    my( $self, $runtime, $iter ) = @_;

    $self->{hash} = {};
    while( $iter && $iter->next ) {
        my $k = $iter->item;
        $iter->next;
        my $v = $iter->item;
        $self->{hash}{$k->as_string( $runtime )} = $v;
    }

    return 2 * keys %{$self->{hash}};
}

sub restore_item {
    my( $self, $runtime, $key, $value ) = @_;

    if( !defined $value ) {
        delete $self->{hash}->{$key};
    } else {
        $self->{hash}->{$key} = $value;
    }
}

sub get_item_or_undef {
    my( $self, $runtime, $key, $create ) = @_;

    if( !exists $self->{hash}{$key} ) {
        if( $create ) {
            return $self->{hash}{$key} =
                       Language::P::Toy::Value::Undef->new( $runtime );
        } else {
            return Language::P::Toy::Value::Undef->new( $runtime );
        }
    }

    return $self->{hash}{$key};
}

sub slice {
    my( $self, $runtime, $keys, $create ) = @_;
    my @res;

    for( my $iter = $keys->iterator; $iter->next; ) {
        my $key = $iter->item->as_string;

        push @res, $self->get_item_or_undef( $runtime, $key, $create );
    }

    return Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
}

sub set_item {
    my( $self, $runtime, $key, $value ) = @_;

    if( !exists $self->{hash}{$key} ) {
        $self->{hash}{$key} = Language::P::Toy::Value::Undef->new( $runtime );
    }

    $self->{hash}{$key}->assign( $runtime, $value );
}

sub has_item {
    my( $self, $runtime, $key ) = @_;

    return exists $self->{hash}{$key};
}

sub exists {
    my( $self, $runtime, $key ) = @_;

    return Language::P::Toy::Value::Scalar->new_boolean( $runtime, exists $self->{hash}{$key} );
}

sub delete_item {
    my( $self, $runtime, $key ) = @_;
    my $value = delete $self->{hash}{$key};

    $value ||= Language::P::Toy::Value::Undef->new( $runtime );

    return Language::P::Toy::Value::List->new( $runtime,
                                               { array => [ $value ] } );
}

sub delete_slice {
    my( $self, $runtime, $indices ) = @_;
    my @res;

    for( my $iter = $indices->iterator; $iter->next; ) {
        my $key = $iter->item->as_string( $runtime );
        my $value = delete $self->{hash}{$key};

        $value ||= Language::P::Toy::Value::Undef->new( $runtime );

        push @res, $value;
    }

    return Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
}

sub iterator {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Array->new
               ( $runtime,
                 { array => [ map { Language::P::Toy::Value::Scalar
                                        ->new_string( $runtime, $_ ),
                                    $self->{hash}->{$_} }
                                  keys %{$self->hash} ] } )
               ->iterator( $runtime );
}

sub key_iterator {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Array->new
               ( $runtime,
                 { array => [ map { Language::P::Toy::Value::Scalar
                                        ->new_string( $runtime, $_ ) }
                                  keys %{$self->hash} ] } )
               ->iterator( $runtime );
}

sub value_iterator {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Array->new
               ( $runtime,
                 { array => [ map { $self->{hash}->{$_} }
                                  keys %{$self->hash} ] } )
               ->iterator( $runtime );
}

sub start_iteration {
    my( $self, $runtime ) = @_;
    $self->{iterator} = $self->key_iterator( $runtime );
}

sub next_key {
    my( $self, $runtime ) = @_;
    $self->start_iteration unless $self->{iterator};

    if( !$self->{iterator}->next( $runtime ) ) {
        $self->{iterator} = undef;

        return undef;
    }

    return $self->{iterator}->item( $runtime );
}

1;
