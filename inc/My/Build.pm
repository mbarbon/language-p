package My::Build;

use strict;
use warnings;
use base qw(Module::Build);

sub _run_with_p {
    my( $self, $dirs ) = @_;

    require TAP::Harness;

    my $harness =
      TAP::Harness->new( { exec => [ $self->perl, '-Mblib', '--', 'bin/p' ],
                           } );
    my @base = $self->expand_test_dir( $dirs );

    $harness->runtests( @base );
}

sub ACTION_test_perl {
    my( $self ) = @_;

    $self->_run_with_p( 't/perl5' );
}

sub ACTION_test_run {
    my( $self ) = @_;

    $self->_run_with_p( 't/run' );
}

1;
