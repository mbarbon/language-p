package Language::P::Intermediate::Code;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Scalar::Util;

__PACKAGE__->mk_ro_accessors( qw(type name basic_blocks outer inner
                                 lexicals prototype) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{inner} = [];

    return $self;
}

sub is_main  { $_[0]->{type} == 1 }
sub is_sub   { $_[0]->{type} == 2 }
sub is_regex { $_[0]->{type} == 3 }

sub weaken   { $_->weaken, Scalar::Util::weaken( $_ ) foreach @{$_[0]->inner} }

1;
