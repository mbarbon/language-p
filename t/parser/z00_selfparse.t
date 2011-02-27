#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 19;

parse_ok( \@INC, 'Language::P' );
parse_ok( \@INC, 'Language::P::Object' );
parse_ok( \@INC, 'Language::P::Assembly' );
parse_ok( \@INC, 'Language::P::Constants' );
parse_ok( \@INC, 'Language::P::Exception' );
parse_ok( \@INC, 'Language::P::Intermediate::BasicBlock' );
parse_ok( \@INC, 'Language::P::Intermediate::Code' );
parse_ok( \@INC, 'Language::P::Intermediate::Generator' );
parse_ok( \@INC, 'Language::P::Intermediate::Transform' );
parse_ok( \@INC, 'Language::P::Keywords' );
parse_ok( \@INC, 'Language::P::Lexer' );
parse_ok( \@INC, 'Language::P::Opcodes' );
parse_ok( \@INC, 'Language::P::ParseTree' );
parse_ok( \@INC, 'Language::P::ParseTree::PropagateContext' );
parse_ok( \@INC, 'Language::P::ParseTree::Visitor' );
parse_ok( \@INC, 'Language::P::Parser' );
parse_ok( \@INC, 'Language::P::Parser::Exception' );
parse_ok( \@INC, 'Language::P::Parser::Lexicals' );
parse_ok( \@INC, 'Language::P::Parser::Regex' );

