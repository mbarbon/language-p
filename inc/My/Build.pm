package My::Build;

use strict;
use warnings;
use parent qw(Module::Build);

use File::Basename qw();
use File::Path qw();

=head1 ACTIONS

=cut

=head2 code_perl5

Creates symlinks for perl5 core tests.

=cut

sub _symlink {
    my( $src, $targ ) = @_;

    File::Path::mkpath( $targ ) unless -d $targ;
    symlink( $src,
             File::Spec->catfile( $targ, File::Basename::basename( $src ) ) );
}

sub ACTION_code_perl5 {
    my( $self ) = @_;
    my $perl5_path = File::Spec->rel2abs( $self->args( 'perl5' ) );

    if( !-e 't/perl5/t' || !-e 't/harness' ) {
        symlink( File::Spec->catfile( $perl5_path, 't/harness' ), 't/harness' );
        for my $f ( glob( File::Spec->catdir( $perl5_path, 't/base/*.t' ) ) ) {
            _symlink( $f, 't/perl5/t/base' );
        }

        $self->add_to_cleanup( 't/perl5/t', 't/harness' );
    }
}

=head2 code

Calls the defult C<code> action, C<code_dlr> if appropriate, and
builds F<lib/Language/P/Opcodes.pm> and F<lib/Language/P/Keywords.pm>
from the files under F<inc>.

=cut

sub ACTION_code {
    my( $self ) = @_;

    if( !$self->up_to_date( [ 'inc/Keywords.pm' ],
                            [ 'lib/Language/P/Keywords.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MKeywords', '-e', 'write_keywords',
                          '--', 'lib/Language/P/Keywords.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Keywords.pm' );
    }
    if( !$self->up_to_date( [ 'inc/Opcodes.pm', 'inc/Keywords.pm',
                              'lib/Language/P/Keywords.pm' ],
                            [ 'lib/Language/P/Opcodes.pm', 'lib/Language/P/Toy/Assembly.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodes', '-e', 'write_opcodes()',
                          '--', 'lib/Language/P/Opcodes.pm' );
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodes', '-e', 'write_toy_opclasses()',
                          '--', 'lib/Language/P/Toy/Assembly.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Opcodes.pm',
                               'lib/Language/P/Toy/Assembly.pm' );
    }
    if( !$self->up_to_date( [ 'inc/Opcodes.pm', 'lib/Language/P/Keywords.pm' ],
                            [ 'lib/Language/P/Intermediate/SerializeGenerated.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodes', '-e', 'write_perl_serializer()',
                          '--', 'lib/Language/P/Intermediate/SerializeGenerated.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Intermediate/SerializeGenerated.pm' );
    }

    $self->depends_on( 'code_perl5' ) if $self->args( 'perl5' );

    $self->SUPER::ACTION_code;
}

sub _all_subdirs {
    my( $dir ) = @_;
    my @subdirs;

    local $_;

    my $subr = sub {
        return unless -d $File::Find::name;
        push @subdirs, $File::Find::name;
    };

    require File::Find;
    File::Find::find( {wanted => $subr, no_chdir => 1 }, $dir );

    return @subdirs;
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
            my $cmdline;

            if( ref $interpreter ) {
                $cmdline = [ $self->perl, '-Mblib', '--', @$interpreter ];
            } else {
                $cmdline = [ $self->perl, '-Mblib', '--', $interpreter ];
            }

            $harness = TAP::Harness->new
              ( { formatter => $formatter,
                  exec      => $cmdline,
                  } );
        } else {
            $harness = TAP::Harness->new
              ( { formatter => $formatter,
                  exec      => [ $self->perl, '-Mblib', '--' ],
                  } );
        }

        my @tests = sort map $self->expand_test_dir( $_ ), @directories;

        local $ENV{PERL5OPT} = $ENV{HARNESS_PERL_SWITCHES}
          if $ENV{HARNESS_PERL_SWITCHES};
        $harness->aggregate_tests( $aggregator, @tests );
    }
    $aggregator->stop();
    $formatter->summary( $aggregator );
}

my %test_tags =
  ( 'parser'     => [ [ undef,   _all_subdirs( 't/parser' ) ] ],
    'runtime'    => [ [ undef,   _all_subdirs( 't/runtime' ) ] ],
    'intermediate' => [ [ undef, _all_subdirs( 't/intermediate' ) ] ],
    'perl5'      => [ [ 'bin/p', _all_subdirs( 't/perl5' ) ] ],
    'run'        => [ [ 'bin/p', _all_subdirs( 't/run' ) ] ],
    'all'        => [ 'parser', 'intermediate', 'runtime', 'run', 'perl5' ],
    );

=head2 test_parser

Runs the tests under F<t/parser>.

=head2 test_intermediate

Runs the tests under F<t/intermediate>.

=head2 test_runtime

Runs the Toy runtime tests under F<t/runtime>.

=head2 test_run

Runs the tests under F<t/run> using F<bin/p>.

=head2 test_perl5

Runs the tests under F<t/perl5> using F<bin/p>.

=cut

sub ACTION_test_parser;
sub ACTION_test_intermediate;
sub ACTION_test_runtime;
sub ACTION_test_run;
sub ACTION_test_perl5;

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

sub _byte_compile {
    my( $self, @tags ) = @_;

    my @byte_compile;
    foreach my $tag ( @tags ) {
        my( $interpreter, @directories ) = @$tag;

        push @byte_compile, [ [ $interpreter, '-Zdump-bytecode' ],
                              @directories ];
    }

    local $ENV{P_BYTECODE_PATH} = 'support/bytecode';
    $self->_run_p_tests( @byte_compile );
}

sub ACTION_test_dump_bytecode {
    my( $self ) = @_;

    $self->_byte_compile( _expand_tags( $self, 'run' ) );
}

=head2 test

Runs all the tests (uses th Toy runtime for the tests that require
running code).

=cut

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
