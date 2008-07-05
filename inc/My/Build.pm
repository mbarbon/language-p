package My::Build;

use strict;
use warnings;
use base qw(Module::Build);

sub ACTION_perl_tests {
    my( $self ) = @_;

    require TAP::Harness;

    my $harness =
      TAP::Harness->new( { lib  => 'blib/lib',
                           exec => [ $self->perl, '-Mblib', '--', 'bin/p' ],
                           } );
    my @base = $self->expand_test_dir( 't/perl5/base' );

    $harness->runtests( @base );
}

1;
