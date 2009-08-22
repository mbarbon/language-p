package Language::P::Toy::Value::List;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Array);

__PACKAGE__->mk_ro_accessors( qw() );

sub type { 8 }

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

    foreach my $value ( @values ) {
        if(    $value->isa( 'Language::P::Toy::Value::Array' )
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

sub as_scalar {
    my( $self, $runtime ) = @_;

    return @{$self->{array}} ? $self->{array}[-1]->as_scalar( $runtime ) :
                               Language::P::Toy::Value::Undef->new( $runtime );
}

sub slice {
    my( $self, $runtime, $indices ) = @_;
    my @res;

    for( my $iter = $indices->iterator; $iter->next; ) {
        my $index = $iter->item->as_integer;

        next if $index > $#{$self->{array}};

        push @res, $self->{array}[$index];
    }

    return Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
}

1;
