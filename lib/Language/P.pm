package Language::P;

=head1 NAME

Language::P - parsing/compiling Perl5 code using Perl5

=head1 SYNOPSYS

  my $p = Language::P->new_from_argv
              ( \@ARGV,
                { runtime   => $runtime,
                  generator => $generator,
                  } );

  $p->run;

=head1 DESCRIPTION

An experiment: a Perl 5 parser written in Perl 5, which might in time
have multiple backends.  For now it only has a partial parser
implementation and a toy runtime written in Perl 5.

Time permitting it will acquire a Parrot (and Java and .Net and ... runtime).

See L<Language::P::Docs::TOC>.

=head1 METHODS

=cut

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_ro_accessors( qw(runtime generator) );
__PACKAGE__->mk_accessors( qw(program program_arguments program_code) );

our $VERSION = '0.01_04';

use Language::P::Parser;

=head2 new_from_argv

  $p = Language::P->new_from_argv( \@ARGV,
                                   { generator => $code_generator,
                                     runtime   => $runtime,
                                     } );

Constructs a C<Language::P> object, initializes it calling
C<initialize> passing the second argument, processes command-line
arguments ten uses anything remaining in the command line as a program
name and its arguments.

=cut

sub new_from_argv {
    my( $class, $argv, $args ) = @_;
    my $self = $class->SUPER::new;

    $self->initialize( $args );

    if( @$argv ) {
        if( $argv->[0] =~ /^-/ ) {
            $argv = $self->process_command_line( $argv );
        }

        if( $self->program_code ) {
            $self->program_arguments( $argv );
        } else {
            $self->program( $argv->[0] );
            $self->program_arguments( [ @$argv[1 .. $#$argv] ] );
        }
    }

    return $self;
}

sub initialize {
    my( $self, $args ) = @_;

    $self->{runtime} = $args->{runtime};
    $self->{generator} = $args->{generator};
}

sub process_command_line {
    my( $self, $argv ) = @_;
    my @remaining;

    for( my $i = 0; $i <= $#$argv; ++$i ) {
        my $arg = $argv->[$i];

        $arg eq '--' and do {
            push @remaining, @{$argv}[$i + 1 .. $#$argv];
            last;
        };
        $arg =~ /^-Z(\S+)/ and do {
            $self->generator->set_option( $1 );
            $self->runtime->set_option( $1 );
            next;
        };
        $arg =~ /^-e/ and do {
            ++$i;
            my $code = $self->program_code( $argv->[$i] );

            die "No code specified for -e.\n" unless defined $code;
        };

        # pass through
        push @remaining, $arg;
    }

    return \@remaining;
}

sub run {
    my( $self ) = @_;

    if( $self->program_code ) {
        $self->runtime->run_string( $self->program_code, '-e', 1 );
    } else {
        $self->runtime->run_file( $self->program, 1 );
    }
}

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SOURCES

The latest sources can be found on GitHub at
L<http://github.com/mbarbon/language-p/tree>

=cut

1;
