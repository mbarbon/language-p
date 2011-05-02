package Language::P::Toy::Value::LvalueList;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Array);

__PACKAGE__->mk_ro_accessors( qw() );

sub type { 18 }

sub assign_array {
    my( $self, $runtime, $other ) = @_;

    # FIXME multiple dispatch
    if( $other->isa( 'Language::P::Toy::Value::Scalar' ) ) {
        my $iter = $self->lvalue_iterator( $runtime );

        if( $iter->next ) {
            $iter->item->assign( $runtime, $other );
        }
        while( $iter->next( $runtime ) ) {
            $iter->item->assign_iterator( $runtime, undef );
        }

        return 1;
    } else {
        my $count = 0;

        # must clone the rvalue either here or in assign_iterator
        my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
        for( my $iter = $self->lvalue_iterator( $runtime ); $iter->next( $runtime ); ) {
            $count += $iter->item->assign_iterator( $runtime, $oiter );
        }

        return $count;
    }
}

sub as_scalar {
    my( $self, $runtime ) = @_;

    return @{$self->{array}} ? $self->{array}[-1]->as_scalar( $runtime ) :
                               Language::P::Toy::Value::Undef->new( $runtime );
}

sub slice {
    my( $self, $runtime, $indices ) = @_;
    $self->_to_list( $runtime );

    return $self->slice( $runtime, $indices );
}

sub iterator {
    my( $self, $runtime ) = @_;
    $self->_to_list( $runtime );

    return Language::P::Toy::Value::Array::Iterator->new( $runtime, $self );
}

sub lvalue_iterator {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Array::Iterator->new( $runtime, $self );
}

sub _to_list {
    my( $self, $runtime ) = @_;
    my $values = $self->{array};

    $self->{array} = [];
    bless $self, 'Language::P::Toy::Value::List';

    $self->push_value( $runtime, @$values );
}

1;
