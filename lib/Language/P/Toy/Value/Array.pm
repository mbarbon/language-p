package Language::P::Toy::Value::Array;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(array) );

sub type { 2 }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{array} ||= [];

    return $self;
}

sub clone {
    my( $self, $runtime, $level ) = @_;

    my $clone = ref( $self )->new( $runtime,
                                   { array  => [ @{$self->{array}} ],
                                     } );

    if( $level > 0 ) {
        foreach my $entry ( @{$clone->{array}} ) {
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

    # FIXME multiple dispatch
    if( $other->isa( 'Language::P::Toy::Value::Scalar' ) ) {
        $self->{array} = [ $other->clone( $runtime, 1 ) ];
    } else {
        # FIXME optimize: don't do it unless necessary
        my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
        $self->assign_iterator( $runtime, $oiter );
    }
}

sub assign_iterator {
    my( $self, $runtime, $iter ) = @_;

    $self->{array} = [];
    while( $iter->next ) {
        push @{$self->{array}}, $iter->item;
    }
}

sub push_value {
    my( $self, $runtime, @values ) = @_;

    push @{$self->{array}}, @values;
}

sub push_list {
    my( $self, $runtime, $list ) = @_;

    push @{$self->{array}}, @{$list->array};

    return Language::P::Toy::Value::StringNumber->new
               ( $runtime, { integer => scalar @{$self->array} } );
}

sub pop_value {
    my( $self, $runtime ) = @_;

    return pop @{$self->{array}};
}

sub unshift_list {
    my( $self, $runtime, $list ) = @_;

    unshift @{$self->{array}}, @{$list->array};

    return Language::P::Toy::Value::StringNumber->new
               ( $runtime, { integer => scalar @{$self->array} } );
}

sub shift_value {
    my( $self, $runtime ) = @_;

    return shift @{$self->{array}};
}

sub iterator {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Array::Iterator->new( $runtime, $self );
}

sub iterator_from {
    my( $self, $runtime, $index ) = @_;

    return Language::P::Toy::Value::Array::Iterator->new( $runtime, $self, $index );
}

sub get_item {
    my( $self, $runtime, $index ) = @_;

    Carp::confess "Array index out of range ($index > $#{$self->{array}})"
        if $index < 0 || $index > $#{$self->{array}};

    return $self->{array}->[$index];
}

sub get_item_or_undef {
    my( $self, $runtime, $index ) = @_;

    if( $index > $#{$self->{array}} ) {
        push @{$self->{array}}, Language::P::Toy::Value::Undef->new( $runtime )
          foreach 1 .. $index - $#{$self->{array}};
    }

    return $self->{array}->[$index];
}

sub exists {
    my( $self, $runtime, $index ) = @_;

    return Language::P::Toy::Value::Scalar->new_boolean( $runtime, $index > $#{$self->{array}} );
}

sub get_count {
    my( $self, $runtime ) = @_;

    return scalar @{$self->{array}};
}

sub as_scalar {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::StringNumber->new( $runtime, { integer => $self->get_count( $runtime ) } );
}

sub as_boolean_int {
    my( $self, $runtime ) = @_;

    return $self->get_count( $runtime ) ? 1 : 0;
}

package Language::P::Toy::Value::Array::Iterator;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(array index) );

sub type { 3 }

sub new {
    my( $class, $runtime, $array, $index ) = @_;
    my $self = $class->SUPER::new( $runtime,
                                   { array => $array,
                                     index => ( $index || 0 ) - 1,
                                     } );
}

sub next {
    my( $self, $runtime ) = @_;
    return 0 if $self->{index} >= $self->{array}->get_count( $runtime ) - 1;

    ++$self->{index};

    return 1;
}

sub item {
    my( $self, $runtime ) = @_;

    return $self->{array}->get_item( $runtime, $self->{index} );
}

1;
