package TestParser;

use strict;
use warnings;

use Exporter 'import';

use Language::P::Parser;
use Language::P::Keywords;
use Language::P::ParseTree qw(:all);
use Language::P::ParseTree::PropagateContext;
use Language::P::Toy::Value::MainSymbolTable;

our @EXPORT_OK = qw(fresh_parser parsed_program
                    parse_and_diff_yaml parse_string);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

my @lines;

{
    package TestParserGenerator;

    sub new {
        @lines = ();
        $_[1]->{_propagate_context} = Language::P::ParseTree::PropagateContext->new;

        return bless $_[1], __PACKAGE__;
    }

    sub process {
        $_[0]->{_propagate_context}->visit( $_[1], TestParser::CXT_VOID );
        push @lines, $_[1];
    }

    sub runtime { $_[0]->{runtime} }
    sub start_code_generation {}
    sub end_code_generation {}

    sub add_declaration {
        my( $self, $name ) = @_;

        my $sub = Language::P::Toy::Value::Subroutine::Stub->new
                      ( { name     => $name,
                          } );
        $self->runtime->symbol_table->set_symbol( $name, '&', $sub );
    }

    package TestParserRuntime;

    sub new {
        my $st = Language::P::Toy::Value::MainSymbolTable->new;

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

sub parse_string {
    my( $expr, $package ) = @_;

    my $parser = fresh_parser();
    $parser->parse_string( $expr, $package || 'main' );

    return parsed_program();
}

sub parse_and_diff_yaml {
    my( $expr, $expected ) = @_;

    $expected =~ s{ ((?:NUM|CXT|FLAG|CONST|STRING|VALUE|OP|DECLARATION|PROTO)_[A-Z_ \|]+)}
                  {" " . eval $1 or die $@}eg;

    require Language::P::ParseTree::DumpYAML;

    my $got = '';
    my $dumper = Language::P::ParseTree::DumpYAML->new;
    foreach my $line ( @{parse_string( $expr )} ) {
        $got .= $dumper->dump( $line );
    }

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $got, $expected );
}

1;
