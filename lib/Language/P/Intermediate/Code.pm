package Language::P::Intermediate::Code;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(type name basic_blocks outer inner
                                 lexicals prototype scopes) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{inner} = [];
    $self->{scopes} = [];

    return $self;
}

sub is_main  { $_[0]->{type} == 1 || $_[0]->{type} == 4 }
sub is_sub   { $_[0]->{type} == 2 }
sub is_regex { $_[0]->{type} == 3 }
sub is_eval  { $_[0]->{type} == 4 }

1;
