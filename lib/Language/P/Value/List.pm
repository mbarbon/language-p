package Language::P::Value::List;

use strict;
use warnings;
use base qw(Language::P::Value::Array);

__PACKAGE__->mk_ro_accessors( qw() );

sub type { 8 }

sub assign {
    my( $self, $other ) = @_;

    # FIXME optimize: don't do it unless necessary
    my $oiter = $other->clone( 1 )->iterator;
    for( my $iter = $self->iterator; $iter->next; ) {
        $iter->item->assign_iterator( $oiter );
    }
}

sub push {
    my( $self, @values ) = @_;

    foreach my $value ( @values ) {
        if( $value->isa( 'Language::P::Value::Array' ) ) {
            for( my $it = $value->iterator; $it->next; ) {
                push @{$self->{array}}, $it->item;
            }
        } else {
            push @{$self->{array}}, $value;
        }
    }

    return;
}

sub as_scalar {
    my( $self ) = @_;

    return @{$self->{array}} ? $self->{array}[-1]->as_scalar :
                               # FIXME real undef
                               Language::P::Value::StringNumber->new;
}

1;
