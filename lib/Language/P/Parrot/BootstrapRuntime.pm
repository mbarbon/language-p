package Language::P::Parrot::BootstrapRuntime;

use strict;
use warnings;
use base qw(Language::P::Toy::Runtime);

__PACKAGE__->mk_ro_accessors( qw(parrot) );

sub run_last_file {
    my( $self, $file ) = @_;

    system( $self->parrot, '-L', 'support/parrot', $file );
}

1;
