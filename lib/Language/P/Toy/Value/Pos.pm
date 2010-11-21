package Language::P::Toy::Value::Pos;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(value) );

sub new {
    my( $class, $runtime, $scalar ) = @_;

    return $class->SUPER::new( $runtime,
                               { value => $scalar } );
}

sub _get {
    my( $self, $runtime ) = @_;
    my $pos = $self->value->get_pos( $runtime );

    return Language::P::Toy::Value::Undef->new( $runtime ) if $pos && $pos == -1;
    return Language::P::Toy::Value::Scalar->new_integer( $runtime, $pos );

}

sub _set {
    my( $self, $runtime, $value ) = @_;
    my $dest = $self->value;

    if( !$value->is_defined( $runtime ) ) {
        $dest->set_pos( $runtime, -1, 1 );

        return;
    }

    my $pos = $value->as_integer( $runtime );
    my $len = $self->value->get_length_int( $runtime );

    if( $pos < 0 && -$pos >= $len ) {
        $pos = 0;
    } elsif( $pos < 0 ) {
        $pos = $len + $pos;
    } elsif( $pos > $len ) {
        $pos = $len;
    }

    $dest->set_pos( $runtime, $pos, 1 );
}

1;
