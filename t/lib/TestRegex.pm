package TestRegex;

use strict;
use warnings;

use Exporter 'import';

use Language::P::Runtime;
use Language::P::Generator;
use Language::P::Parser::Regex;

our @EXPORT_OK = qw(match);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

my $runtime = Language::P::Runtime->new;
my $generator = Language::P::Generator->new( { runtime => $runtime } );
my $parser = Language::P::Parser::Regex->new( { runtime     => $runtime,
                                                generator   => $generator,
                                                interpolate => 1,
                                                } );

sub match {
    my( $string, $regex ) = @_;
    my $parsed_rx = $parser->parse_string( $regex );

#    use Data::Dumper; print Dumper $parsed_rx;

    my $code = $generator->process_regex( $parsed_rx );
#    use Data::Dumper; print Dumper $code;
    my $match = $code->match( $runtime, $string );

    return $match;
}

1;
