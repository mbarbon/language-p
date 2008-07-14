package Language::P::Value::Subroutine;

use strict;
use warnings;
use base qw(Language::P::Value::Code);

__PACKAGE__->mk_ro_accessors( qw(name) );

sub type { 6 }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    # for @_
    $self->{stack_size} = 1;

    return $self;
}

package Language::P::Value::Subroutine::Stub;

use strict;
use warnings;
use base qw(Language::P::Value::Subroutine);

sub call { Carp::confess( "Called subroutine stub" ) }

1;
