package Language::P::Toy::Value::LvalueList;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Array);

__PACKAGE__->mk_ro_accessors( qw() );

sub type { 18 }

sub assign {
    my( $self, $runtime, $other ) = @_;

    # FIXME optimize: don't do it unless necessary
    my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
    for( my $iter = $self->lvalue_iterator( $runtime ); $iter->next( $runtime ); ) {
        $iter->item->assign_iterator( $runtime, $oiter );
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
