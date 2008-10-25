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
        my( $interpreter, @directories ) = @$test_dir;
        my $harness;

        if( $interpreter ) {
            $harness = TAP::Harness->new
              ( { formatter => $formatter,
                  exec      => [ $self->perl, '-Mblib', '--', $interpreter ],
                  } );
        } else {
            $harness = TAP::Harness->new
              ( { formatter => $formatter,
                  exec      => [ $self->perl, '-Mblib', '--' ],
                  } );
        }

        my @tests = $self->expand_test_dir( @directories );

        local $ENV{PERL5OPT} = $ENV{HARNESS_PERL_SWITCHES}
          if $ENV{HARNESS_PERL_SWITCHES};
        $harness->aggregate_tests( $aggregator, @tests );
    }
    $aggregator->stop();
    $formatter->summary( $aggregator );
}

my %test_tags =
  ( 'parser'     => [ [ undef,   't/parser' ] ],
    'runtime'    => [ [ undef,   't/runtime' ] ],
    'perl5'      => [ [ 'bin/p', 't/perl5' ] ],
    'run'        => [ [ 'bin/p', 't/run' ] ],
    'all'        => [ 'parser', 'runtime', 'run', 'perl5' ],
    );

sub _expand_tags {
    my( $self, $tag ) = @_;
    die "Unknown test tag '$tag'" unless exists $test_tags{$tag};

    my $base = $test_tags{$tag};
    my @res;

    foreach my $part ( @$base ) {
        if( ref $part ) {
            push @res, $part;
        } else {
            push @res, _expand_tags( $self, $part );
        }
    }

    return @res;
}

sub ACTION_test {
    my( $self ) = @_;

    $self->_run_p_tests( _expand_tags( $self, 'all' ) );
}

our $AUTOLOAD;
sub AUTOLOAD {
    ( my $function = $AUTOLOAD ) =~ s/^.*:://;

    die "Unknown action '$function'"
        unless $function =~ /^ACTION_test_(\w+)/;

    $_[0]->_run_p_tests( _expand_tags( $_[0], $1 ) );
}

1;
