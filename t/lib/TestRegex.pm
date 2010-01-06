package TestRegex;

use strict;
use warnings;

use Exporter 'import';

use Language::P::Toy::Runtime;
use Language::P::Toy::Generator;
use Language::P::Parser::Regex;

our @EXPORT_OK = qw(match);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

my $runtime = Language::P::Toy::Runtime->new;
my $generator = Language::P::Toy::Generator->new( { runtime => $runtime } );
my $parser = Language::P::Parser::Regex->new( { runtime     => $runtime,
                                                generator   => $generator,
                                                interpolate => 1,
                                                flags       => 0,
                                                } );

sub match {
    my( $string, $regex ) = @_;
    my $parsed_rx = $parser->parse_string( $regex );
    my $pattern = Language::P::ParseTree::Pattern->new
                      ( { components => $parsed_rx,
                          } );

#    use Data::Dumper; print Dumper $parsed_rx;

    my $re = $generator->process_regex( $pattern );
#    use Data::Dumper; print Dumper $re;
    my $match = $re->match( $runtime, $string );

    return $match;
}

1;
