package TestParser;

use strict;
use warnings;

use Exporter 'import';

use Language::P::Parser;
use Language::P::ParseTree qw(:all);
use Language::P::Value::SymbolTable;

our @EXPORT_OK = qw(fresh_parser parsed_program parse_and_diff
                    parse_and_diff_yaml);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

my @lines;

{
    package TestParserGenerator;

    sub new {
        @lines = ();

        return bless $_[1], __PACKAGE__;
    }

    sub process {
        push @lines, $_[1];
    }

    sub push_code { }
    sub pop_code { }
    sub finished { }
    sub runtime { $_[0]->{runtime} }

    sub add_declaration {
        my( $self, $name ) = @_;

        my $sub = Language::P::Value::Subroutine::Stub->new
                      ( { name     => $name,
                          } );
        $self->runtime->symbol_table->set_symbol( $name, '&', $sub );
    }

    package TestParserRuntime;

    sub new {
        my $st = Language::P::Value::SymbolTable->new;

        return bless { symbol_table => $st }, __PACKAGE__;
    }

    sub symbol_table { $_[0]->{symbol_table} }
    sub set_bytecode { }
}

sub fresh_parser {
    my $rt = TestParserRuntime->new;
    my $parser = Language::P::Parser->new
                     ( { generator => TestParserGenerator->new
                                          ( { runtime => $rt } ),
                         runtime   => $rt,
                         } );

    return $parser;
}

sub parsed_program {
    return \@lines;
}

sub parse_and_diff_yaml {
    my( $expr, $expected ) = @_;

    $expected =~ s{ ((?:NUM|CXT|FLAG|CONST|STRING)_[A-Z_ \|]+)}
                  {" " . eval $1 or die $@}eg;

    require Language::P::ParseTree::DumpYAML;

    my $parser = fresh_parser();
    $parser->parse_string( $expr, 'main' );

    my $got = '';
    my $dumper = Language::P::ParseTree::DumpYAML->new;
    foreach my $line ( @{parsed_program()} ) {
        $got .= $dumper->dump( $line );
    }

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $got, $expected );
}

1;
