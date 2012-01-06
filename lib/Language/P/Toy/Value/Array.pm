package Language::P::Toy::Value::Array;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Any);

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

sub localize_element {
    my( $self, $runtime, $index ) = @_;
    my $value = $self->get_item_or_undef( $runtime, $index, 0 );
    my $new = Language::P::Toy::Value::Undef->new( $runtime );

    # no need to check boundaries after get_item_or_undef
    $self->{array}->[$index] = $new;

    return $value;
}

sub assign { assign_array( @_ ) }

sub assign_array {
    my( $self, $runtime, $other ) = @_;

    # FIXME multiple dispatch
    if( $other->isa( 'Language::P::Toy::Value::Scalar' ) ) {
        $self->{array} = [ $other->clone( $runtime, 1 ) ];

        return 1;
    } else {
        # must clone the rvalue either here or in assign_iterator
        my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
        return $self->assign_iterator( $runtime, $oiter );
    }
}

sub assign_iterator {
    my( $self, $runtime, $iter ) = @_;

    $self->{array} = [];
    while( $iter && $iter->next ) {
        push @{$self->{array}}, $iter->item;
    }

    return scalar @{$self->{array}};
}

sub push_value {
    my( $self, $runtime, @values ) = @_;

    push @{$self->{array}}, @values;
}

sub push_list {
    my( $self, $runtime, $list ) = @_;

    push @{$self->{array}}, map $_->clone( $runtime, 0 ), @{$list->array};

    return Language::P::Toy::Value::StringNumber->new
               ( $runtime, { integer => scalar @{$self->array} } );
}

sub push_flatten {
    my( $self, $runtime, @values ) = @_;

    foreach my $value ( @values ) {
        if(    $value->isa( 'Language::P::Toy::Value::Array' )
            || $value->isa( 'Language::P::Toy::Value::Range' )
            || $value->isa( 'Language::P::Toy::Value::Hash' ) ) {
            for( my $it = $value->iterator( $runtime ); $it->next( $runtime ); ) {
                push @{$self->{array}}, $it->item( $runtime );
            }
        } else {
            push @{$self->{array}}, $value;
        }
    }

    return;
}

sub pop_value {
    my( $self, $runtime ) = @_;

    return pop @{$self->{array}};
}

sub unshift_list {
    my( $self, $runtime, $list ) = @_;

    unshift @{$self->{array}}, map $_->clone( $runtime, 0 ), @{$list->array};

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

    Carp::confess( "Array index out of range ($index > $#{$self->{array}})" )
        if $index < 0 || $index > $#{$self->{array}};

    return $self->{array}->[$index];
}

sub restore_item {
    my( $self, $runtime, $index, $value ) = @_;

    Carp::confess( "Array index out of range ($index > $#{$self->{array}})" )
        if $index < 0 || $index > $#{$self->{array}};

    $self->{array}->[$index] = $value;
}

sub get_item_or_undef {
    my( $self, $runtime, $index, $create ) = @_;

    if( $index < 0 && -$index > $self->get_count ) {
        if( $create == 2 ) {
            return Language::P::Toy::Value::Array::Element->new( $runtime, $self, $index );
        } elsif( $create == 1 ) {
            my $message = sprintf "Modification of non-creatable array value attempted, subscript %d", $index;
            my $exc = Language::P::Toy::Exception->new
                          ( { message  => $message,
                              } );

            $runtime->throw_exception( $exc, 1 );
        } else {
            return Language::P::Toy::Value::Undef->new( $runtime );
        }
    }

    if( $index > $#{$self->{array}} ) {
        if( $create == 2 ) {
            return Language::P::Toy::Value::Array::Element->new( $runtime, $self, $index );
        } elsif( $create == 1 ) {
            push @{$self->{array}}, Language::P::Toy::Value::Undef->new( $runtime )
              foreach 1 .. $index - $#{$self->{array}};
        } else {
            return Language::P::Toy::Value::Undef->new( $runtime );
        }
    }

    return $self->{array}->[$index];
}

sub slice {
    my( $self, $runtime, $indices, $create ) = @_;
    my @res;

    for( my $iter = $indices->iterator; $iter->next; ) {
        my $index = $iter->item->as_integer;

        push @res, $self->get_item_or_undef( $runtime, $index, $create );
    }

    return Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
}

sub exists {
    my( $self, $runtime, $index ) = @_;

    return Language::P::Toy::Value::Scalar->new_boolean( $runtime, $index > $#{$self->{array}} );
}

sub delete_item {
    my( $self, $runtime, $index ) = @_;
    my $value = delete $self->{array}[$index];

    $value ||= Language::P::Toy::Value::Undef->new( $runtime );

    return Language::P::Toy::Value::List->new( $runtime,
                                               { array => [ $value ] } );
}

sub delete_slice {
    my( $self, $runtime, $indices ) = @_;
    my @res;

    for( my $iter = $indices->iterator; $iter->next; ) {
        my $index = $iter->item->as_integer( $runtime );
        my $value = delete $self->{array}[$index];

        $value ||= Language::P::Toy::Value::Undef->new( $runtime );

        push @res, $value;
    }

    return Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
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

sub is_defined {
    my( $self, $runtime ) = @_;

    return scalar @{$self->{array}} ? 1 : 0;
}

sub as_string {
    my( $self, $runtime ) = @_;

    return $self->get_count( $runtime );
}

sub as_integer {
    my( $self, $runtime ) = @_;

    return $self->get_count( $runtime );
}

sub as_float {
    my( $self, $runtime ) = @_;

    return $self->get_count( $runtime );
}

package Language::P::Toy::Value::Array::Iterator;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Any);

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

package Language::P::Toy::Value::Array::Element;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(array index) );

sub new {
    my( $class, $runtime, $array, $index ) = @_;
    my $self = $class->SUPER::new( $runtime,
                                   { array => $array,
                                     index => $index,
                                     } );
}

sub _get {
    my( $self, $runtime ) = @_;

    return $self->array->get_item_or_undef( $runtime, $self->index, 0 );
}

sub _set {
    my( $self, $runtime, $other ) = @_;

    return $self->array->get_item_or_undef( $runtime, $self->index, 1 )->assign( $runtime, $other );
}

1;
