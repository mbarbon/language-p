package My::Build;

use strict;
use warnings;
use base qw(Module::Build);

use File::Basename;

=head1 ACTIONS

=cut

sub _compile_pir_pbc {
    my( $self, $parrot, $pir_file, $deps ) = @_;
    ( my $pbc_file = $pir_file ) =~ s/\.pir$/.pbc/;

    return if $self->up_to_date( [ $pir_file, @$deps, $parrot ],
                                 [ $pbc_file ] );
    $self->do_system( $parrot, '--output-pbc', '-o', $pbc_file, $pir_file );
    $self->add_to_cleanup( $pbc_file );
}

=head2 code_parrot

Build Parrot runtime support code under F<support/parrot> and create
the F<p_parrot> script under F<bin>.

=cut

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

=head2 code_dlr

=cut

sub ACTION_code_dlr {
    my( $self ) = @_;

    if( !$self->up_to_date( [ 'inc/Opcodes.pm', 'inc/OpcodesDotNet.pm', 'lib/Language/P/Keywords.pm' ],
                            [ 'support/dotnet/Bytecode/BytecodeGenerated.cs' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodesDotNet', '-e', 'write_dotnet_deserializer()',
                          '--', 'support/dotnet/Bytecode/BytecodeGenerated.cs' );
        $self->add_to_cleanup( 'support/dotnet/Bytecode/BytecodeGenerated.cs' );
    }

    my @files = map glob( "support/dotnet/$_" ), qw(*.cs */*.cs);

    # only works with MonoDevelop and when mdtool is in path
    if( !$self->up_to_date( [ @files ],
                            [ 'support/dotnet/bin/Debug/dotnet.exe' ] ) ) {
        $self->do_system( 'mdtool', 'build', 'support/dotnet/dotnet.csproj' );
    }
}

=head2 code

Calls the defult C<code> action, C<code_parrot> if appropriate, and
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
                            [ 'lib/Language/P/Opcodes.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodes', '-e', 'write_opcodes()',
                          '--', 'lib/Language/P/Opcodes.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Opcodes.pm' );
    }
    if( !$self->up_to_date( [ 'inc/Opcodes.pm', 'lib/Language/P/Keywords.pm' ],
                            [ 'lib/Language/P/Intermediate/SerializeGenerated.pm' ] ) ) {
        $self->do_system( $^X, '-Iinc', '-Ilib',
                          '-MOpcodes', '-e', 'write_perl_serializer()',
                          '--', 'lib/Language/P/Intermediate/SerializeGenerated.pm' );
        $self->add_to_cleanup( 'lib/Language/P/Intermediate/SerializeGenerated.pm' );
    }

    $self->depends_on( 'code_parrot' ) if $self->args( 'parrot' );
    $self->depends_on( 'code_dlr' ) if $self->args( 'dlr' );

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
        my( $run_bc, $harness ) = ( 0 );

        if( $interpreter ) {
            my $cmdline;
            if( ref $interpreter ) {
                if( $interpreter->[-1] =~ /\.exe$/ ) {
                    $cmdline = $interpreter;
                    $run_bc = 1;
                } else {
                    $cmdline = [ $self->perl, '-Mblib', '--', @$interpreter ];
                }
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

        if( $run_bc ) {
            $_ .= '.pb' foreach @tests;
        }

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
    'parrot'     => [ 'parser', 'intermediate', 'parrot_run', 'parrot_perl5' ],
    'parrot_run' => [ [ 'bin/p_parrot', _all_subdirs( 't/run' ) ] ],
    'parrot_perl5'=>[ [ 'bin/p_parrot', _all_subdirs( 't/perl5' ) ] ],
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

=head2 test_parrot

Runs F<t/parser> and F<t/intermediate> tests, then the F<t/run> and
F<t/perl5> tests using F<bin/p_parrot>.

=head2 test_parrot_run

Runs the tests under F<t/run> using F<bin/p_parrot>.

=head2 test_parrot_perl5

Runs the tests under F<t/perl5> using F<bin/p_parrot>.

=cut

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

sub _run_dotnet {
    my( $self, @tags ) = @_;

    my( @byte_compile, @run );
    foreach my $tag ( @tags ) {
        my( $interpreter, @directories ) = @$tag;

        push @run, [ [ 'mono', 'support/dotnet/bin/Debug/dotnet.exe' ],
                     @directories ];
    }

    $self->_run_p_tests( @run );
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

sub ACTION_test_dotnet_run {
    my( $self ) = @_;

    $self->_run_dotnet( _expand_tags( $self, 'run' ) );
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
