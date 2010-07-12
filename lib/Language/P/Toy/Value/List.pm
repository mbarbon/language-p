package Language::P::Toy::Value::List;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Array);

__PACKAGE__->mk_ro_accessors( qw() );

sub type { 8 }

sub new_boolean {
    my( $class, $runtime, $value ) = @_;

    return $value ?
               Language::P::Toy::Value::List->new
                   ( $runtime,
                     { array => [ Language::P::Toy::Value::StringNumber->new
                                      ( $runtime, { integer => 1 } ) ] } ) :
               Language::P::Toy::Value::List->new( $runtime, { array => [] } );
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    # FIXME optimize: don't do it unless necessary
    my $oiter = $other->clone( $runtime, 1 )->iterator( $runtime );
    for( my $iter = $self->iterator( $runtime ); $iter->next( $runtime ); ) {
        $iter->item->assign_iterator( $runtime, $oiter );
    }
}

sub push_value {
    my( $self, $runtime, @values ) = @_;

    $self->push_flatten( $runtime, @values );
}

sub as_scalar {
    my( $self, $runtime ) = @_;

    return @{$self->{array}} ? $self->{array}[-1]->as_scalar( $runtime ) :
                               Language::P::Toy::Value::Undef->new( $runtime );
}

sub slice {
    my( $self, $runtime, $indices ) = @_;
    my @res;

    my $found = 0;
    for( my $iter = $indices->iterator; $iter->next; ) {
        my $index = $iter->item->as_integer;

        $found ||= $index <= $#{$self->{array}};
        push @res, $self->get_item_or_undef( $runtime, $index );
    }
    @res = () unless $found;

    return Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
}

1;
