package Language::P::Value::List;

use strict;
use warnings;
use base qw(Language::P::Value::Array);

__PACKAGE__->mk_ro_accessors( qw() );

sub type { 8 }

sub clone {
    my( $self, $level ) = @_;
    # FIXME optimize
    my $clone = Language::P::Value::List->new( { array => [ @{$self->{array}} ] } );

    if( $level > 0 ) {
        foreach my $entry ( @{$clone->{array}} ) {
            $entry = $entry->clone( $level - 1 );
        }
    }

    return $clone;
}

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

    die 'unimplemented' if grep $_->isa( __PACKAGE__ ), @values;
    push @{$self->{array}}, @values;

    return;
}

sub as_scalar {
    my( $self ) = @_;

    return @{$self->{array}} ? $self->{array}[-1]->as_scalar :
                               # FIXME real undef
                               Language::P::Value::StringNumber->new;
}

1;
