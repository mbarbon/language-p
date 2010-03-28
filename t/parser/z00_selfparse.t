#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 17;

use lib 't/lib';
use TestParser qw(:all);

parse_ok( 'lib', 'Language::P' );
parse_ok( 'lib', 'Language::P::Assembly' );
parse_ok( 'lib', 'Language::P::Exception' );
parse_ok( 'lib', 'Language::P::Intermediate::BasicBlock' );
parse_ok( 'lib', 'Language::P::Intermediate::Code' );
parse_ok( 'lib', 'Language::P::Intermediate::Generator' );
parse_ok( 'lib', 'Language::P::Intermediate::Transform' );
parse_ok( 'lib', 'Language::P::Keywords' );
parse_ok( 'lib', 'Language::P::Lexer' );
parse_ok( 'lib', 'Language::P::Opcodes' );
parse_ok( 'lib', 'Language::P::ParseTree' );
parse_ok( 'lib', 'Language::P::ParseTree::PropagateContext' );
parse_ok( 'lib', 'Language::P::ParseTree::Visitor' );
parse_ok( 'lib', 'Language::P::Parser' );
parse_ok( 'lib', 'Language::P::Parser::Exception' );
parse_ok( 'lib', 'Language::P::Parser::Lexicals' );
parse_ok( 'lib', 'Language::P::Parser::Regex' );

