package TestParser;

use strict;
use warnings;

use Exporter 'import';

use Language::P::Parser;
use Language::P::Value::SymbolTable;

our @EXPORT_OK = qw(fresh_parser parsed_program parse_and_diff);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

my @lines;

{
    package TestParserGenerator;

    sub new {
        @lines = ();

        return __PACKAGE__;
    }

    sub process {
        push @lines, $_[1];
    }

    sub push_code { }
    sub pop_code { }
    sub finished { }

    package TestParserRuntime;

    sub new {
        my $st = Language::P::Value::SymbolTable->new;

        return bless { symbol_table => $st }, __PACKAGE__;
    }

    sub symbol_table { $_[0]->{symbol_table} }
    sub set_bytecode { }
}

sub fresh_parser {
    my $parser = Language::P::Parser->new
                     ( { generator => TestParserGenerator->new,
                         runtime   => TestParserRuntime->new,
                         } );

    return $parser;
}

sub parsed_program {
    return \@lines;
}

sub parse_and_diff {
    my( $expr, $expected ) = @_;

    my $parser = fresh_parser();
    $parser->parse_string( $expr );

    my $got = '';
    foreach my $line ( @{parsed_program()} ) {
        $got .= $line->pretty_print;
    }

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $got, $expected );
}

1;
