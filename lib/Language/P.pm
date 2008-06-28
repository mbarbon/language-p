package Language::P;

use strict;
use warnings;

our $VERSION = '0.01';

use Language::P::Parser;
use Language::P::Generator;
use Language::P::Runtime;

sub run {
    my( $class, @args ) = @_;

    my $runtime = Language::P::Runtime->new;
    my $generator = Language::P::Generator->new( { runtime => $runtime } );
    my $parser = Language::P::Parser->new( { generator => $generator,
                                             runtime   => $runtime,
                                             } );

    my $code = $parser->parse_file( $args[0] );
    $runtime->run_last_file( $code );
}

1;
