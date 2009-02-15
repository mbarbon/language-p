package My::Build;

use strict;
use warnings;
use base qw(Module::Build);

use File::Basename;

sub _compile_pir_pbc {
    my( $self, $parrot, $pir_file, $deps ) = @_;
    ( my $pbc_file = $pir_file ) =~ s/\.pir$/.pbc/;

    return if $self->up_to_date( [ $pir_file, @$deps, $parrot ],
                                 [ $pbc_file ] );
    $self->do_system( $parrot, '--output-pbc', '-o', $pbc_file, $pir_file );
    $self->add_to_cleanup( $pbc_file );
}

sub ACTION_code_parrot {
    my( $self ) = @_;
    my $parrot_path = $self->args( 'parrot' );

    if( !$self->up_to_date( [ 'inc/p_parrot' ], [ 'bin/p_parrot' ] ) ) {
        require File::Slurp; File::Slurp->import( qw(read_file write_file) );

        $self->log_info( "Creating 'bin/p_parrot'" );
        write_file( 'bin/p_parrot',
                    map { s/%PARROT%/$parrot_path/eg; $_ }
                        read_file( 'inc/p_parrot' ) );
        chmod 0755, 'bin/p_parrot';
        $self->add_to_cleanup( 'bin/p_parrot' );
    }
    foreach my $pir_file ( 'support/parrot/runtime/p5runtime.pir' ) {
        _compile_pir_pbc( $self, $parrot_path, $pir_file,
                          [ glob 'support/parrot/runtime/*.pir' ] );
    }
}

sub ACTION_code {
    my( $self ) = @_;

    if( !$self->up_to_date( [ 'inc/Keywords.pm' ],
                            [ 'lib/Language/P/Keywords.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-MKeywords', '-e', 'write_keywords',
                          '--', 'lib/Language/P/Keywords.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Keywords.pm' );
    }
    if( !$self->up_to_date( [ 'inc/Opcodes.pm', 'lib/Language/P/Keywords.pm' ],
                            [ 'lib/Language/P/Opcodes.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodes', '-e', 'write_opcodes',
                          '--', 'lib/Language/P/Opcodes.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Opcodes.pm' );
    }
    $self->depends_on( 'code_parrot' ) if $self->args( 'parrot' );

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
    'intermediate' => [ [ undef, 't/intermediate' ] ],
    'perl5'      => [ [ 'bin/p', 't/perl5' ] ],
    'run'        => [ [ 'bin/p', 't/run' ] ],
    'all'        => [ 'parser', 'intermediate', 'runtime', 'run', 'perl5' ],
    'parrot'     => [ 'parser', 'intermediate', 'parrot_run', 'parrot_perl5' ],
    'parrot_run' => [ [ 'bin/p_parrot', 't/run' ] ],
    'parrot_perl5'=>[ [ 'bin/p_parrot', 't/perl5' ] ],
    );
sub ACTION_test_parser;
sub ACTION_test_intermediate;
sub ACTION_test_runtime;
sub ACTION_test_run;
sub ACTION_test_perl5;
sub ACTION_test_parrot;
sub ACTION_test_parrot_run;
sub ACTION_test_parrot_perl5;

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

    return if $function eq 'DESTROY';
    die "Unknown action '$function'"
        unless $function =~ /^ACTION_test_(\w+)/;

    $_[0]->_run_p_tests( _expand_tags( $_[0], $1 ) );
}

1;
