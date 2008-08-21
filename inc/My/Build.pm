package My::Build;

use strict;
use warnings;
use base qw(Module::Build);

sub ACTION_code {
    my( $self ) = @_;

    if( !$self->up_to_date( [ 'inc/Keywords.pm' ],
                            [ 'lib/Language/P/Keywords.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-MKeywords', '-e', 'write_keywords',
                          '--', 'lib/Language/P/Keywords.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Keywords.pm' );
    }

    $self->SUPER::ACTION_code;
}

sub _run_p_tests {
    my( $self, @test_dirs ) = @_;

    $self->depends_on( 'code' );

    require TAP::Harness;
    require TAP::Formatter::Console;
    require TAP::Parser::Aggregator;

    my $formatter = TAP::Formatter::Console->new( { jobs => 1 } );
    my $aggregator = TAP::Parser::Aggregator->new;
    $aggregator->start();
    foreach my $test_dir ( @test_dirs ) {
        my( $with_p, @directories ) = @$test_dir;
        my $harness;

        if( $with_p ) {
            $harness = TAP::Harness->new
              ( { formatter => $formatter,
                  exec      => [ $self->perl, '-Mblib', '--', 'bin/p' ],
                  } );
        } else {
            $harness = TAP::Harness->new
              ( { formatter => $formatter,
                  exec      => [ $self->perl, '-Mblib', '--' ],
                  } );
        }
        my @tests = $self->expand_test_dir( @directories );

        $harness->aggregate_tests( $aggregator, @tests );
    }
    $aggregator->stop();
    $formatter->summary( $aggregator );
}

sub ACTION_test_parser {
    my( $self ) = @_;

    $self->_run_p_tests( [ 0, 't/parser' ] );
}

sub ACTION_test_runtime {
    my( $self ) = @_;

    $self->_run_p_tests( [ 0, 't/runtime' ] );
}

sub ACTION_test_perl {
    my( $self ) = @_;

    $self->_run_p_tests( [ 1, 't/perl5' ] );
}

sub ACTION_test_run {
    my( $self ) = @_;

    $self->_run_p_tests( [ 1, 't/run' ] );
}

sub ACTION_test {
    my( $self ) = @_;

    $self->_run_p_tests( [ 0, 't/parser' ],
                         [ 0, 't/runtime' ],
                         [ 1, 't/run' ],
                         [ 1, 't/perl5' ],
                         );
}

1;
