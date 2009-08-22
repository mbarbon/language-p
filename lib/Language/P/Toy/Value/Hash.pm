package Language::P::Toy::Value::Hash;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(hash) );

sub type { 13 }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{hash} ||= {};

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

sub localize {
    my( $self, $runtime ) = @_;

    return __PACKAGE__->new( $runtime );
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    # FIXME optimize: don't do it unless necessary
    my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
    $self->assign_iterator( $runtime, $oiter );
}

sub assign_iterator {
    my( $self, $runtime, $iter ) = @_;

    $self->{hash} = {};
    while( $iter->next ) {
        my $k = $iter->item;
        $iter->next;
        my $v = $iter->item;
        $self->{hash}{$k->as_string( $runtime )} = $v;
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
    my( $self, $runtime, $keys ) = @_;
    my @res;

    for( my $iter = $keys->iterator; $iter->next; ) {
        my $key = $iter->item->as_string;

        if( !exists $self->{hash}{$key} ) {
            push @res, Language::P::Toy::Value::Undef->new( $runtime );
        } else {
            push @res, $self->{hash}{$key};
        }
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

1;
