package Language::P;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(runtime parser generator) );
__PACKAGE__->mk_accessors( qw(program program_arguments) );

our $VERSION = '0.01';

use Language::P::Parser;
use Language::P::Generator;
use Language::P::Runtime;

sub new_from_argv {
    my( $class, $argv ) = @_;
    my $self = $class->SUPER::new;

    $self->initialize;

    if( @$argv ) {
        if( $argv->[0] =~ /^-/ ) {
            $argv = $self->process_command_line( $argv );
        }

        $self->program( $argv->[0] );
        $self->program_arguments( [ @$argv[1 .. $#$argv] ] );
    }

    return $self;
}

sub initialize {
    my( $self ) = @_;

    my $runtime = Language::P::Runtime->new;
    my $generator = Language::P::Generator->new( { runtime => $runtime } );
    my $parser = Language::P::Parser->new( { generator => $generator,
                                             runtime   => $runtime,
                                             } );

    $self->{runtime} = $runtime;
    $self->{generator} = $generator;
    $self->{parser} = $parser;
}

sub process_command_line {
    my( $self, $argv ) = @_;

    local @ARGV = @$argv;

    require Getopt::Long;

    Getopt::Long::GetOptions
      ( \my %args,
        'D=s' => \my $debugging,
        );

    if( $debugging ) {
        foreach my $deb_opt ( split /,/, $debugging ) {
            if( $deb_opt eq 'parse_tree' ) {
                $self->generator->set_debug( $deb_opt );
            }
        }
    }

    return [ @ARGV ];
}

sub run {
    my( $self ) = @_;

    my $code = $self->parser->parse_file( $self->program );
    $self->runtime->run_last_file( $code );
}

1;
