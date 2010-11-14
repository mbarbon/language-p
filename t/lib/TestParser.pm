package TestParser;

use strict;
use warnings;

use Exporter 'import';
use Test::More ();

use Language::P::Parser qw(:all);
use Language::P::Keywords;
use Language::P::Constants qw(:all);
use Language::P::Opcodes qw(:all);
use Language::P::ParseTree::PropagateContext;
use Language::P::Toy::Value::MainSymbolTable;

use YAML qw(Bless Dump);

our @EXPORT_OK = qw(fresh_parser parsed_program parse_ok
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
    sub set_data_handle { }

    sub add_declaration {
        my( $self, $name, $prototype ) = @_;

        my $sub = Language::P::Toy::Value::Subroutine::Stub->new
                      ( $self->runtime,
                        { name     => $name,
                          prototype=> $prototype,
                          } );
        $self->runtime->_symbol_table->set_symbol( $self->runtime,
                                                   $name, '&', $sub );
    }

    package TestParserRuntime;

    sub new {
        my $self = bless {}, __PACKAGE__;
        my $st = Language::P::Toy::Value::MainSymbolTable->new( $self );

        $self->{symbol_table} = $st;

        return $self;
    }

    sub get_symbol { $_[0]->_symbol_table->get_symbol( $_[0], $_[1], $_[2] ) }
    sub get_package { $_[0]->_symbol_table->get_package( $_[0], $_[1] ) }
    sub _symbol_table { $_[0]->{symbol_table} }
    sub set_bytecode { }
    sub wrap_method { }
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

sub parse_ok {
    my( $dirs, $module ) = @_;
    ( my $file = $module ) =~ s{::}{/}g;
    my $parser = fresh_parser;

    require File::Spec;

    my $path;
    foreach my $dir ( ref $dirs ? @$dirs : $dirs ) {
        $path = File::Spec->catfile( $dir, $file . '.pm' );
        last if -f $path
    }
    eval {
        $parser->parse_file( $path, PARSE_ADD_RETURN|PARSE_MAIN );
    };
    if( my $e = $@ ) {
        Test::More::ok( 0, $module );

        if( ref $e && $e->isa( 'Language::P::Exception' ) ) {
            my $pos = $e->position || [ 'some file', 'not known' ];
            Test::More::diag( $e->message . ' at ' . $pos->[0] .
                              ' line ' . $pos->[1] );
        } else {
            Test::More::diag( "Abnormal parser faiure:" );
            Test::More::diag( "$e" );
        }
    } else {
        Test::More::ok( 1, $module );
    }
}

sub parse_string {
    my( $expr, $package ) = @_;

    my $parser = fresh_parser();
    $parser->parse_string( $expr, 0, '<string>',
                           { package  => $package || 'main',
                             lexicals => undef,
                             hints    => 0,
                             warnings => undef,
                             } );

    return parsed_program();
}

sub parse_and_diff_yaml {
    my( $expr, $expected ) = @_;

    $expected =~ s{ ((?:NUM|CXT|FLAG|CONST|STRING|VALUE|OP|DECLARATION|PROTO|CHANGED|RX_CLASS|RX_GROUP|RX_POSIX|RX_ASSERTION)_[A-Z_ \|]+)}
                  {" " . ( eval $1 or die $@ )}eg;

    require Language::P::ParseTree::DumpYAML;

    my $got = '';
    my $dumper = Language::P::ParseTree::DumpYAML->new;
    eval {
        foreach my $line ( @{parse_string( $expr )} ) {
            $got .= $dumper->dump( $line );
        }
    };
    my $e = $@;
    if( $e && ref( $e ) && $e->isa( 'Language::P::Exception' ) ) {
        my $v = { message => $e->message,
                  file    => $e->position->[0],
                  line    => $e->position->[1],
                  };
        Bless( $v )->tag( 'p:Exception' );

        $got .= Dump( $v );
    } elsif( $e ) {
        $got .= $e;
    }

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $got, $expected );
}

package t::lib::TestParser;

sub import {
    shift;

    strict->import;
    warnings->import;
    Test::More->import( @_ );
    Exporter::export( 'TestParser', scalar caller, ':all' );
}

1;
