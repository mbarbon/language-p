#!/usr/bin/perl -w

BEGIN { print "1..19\n" }
BEGIN { unshift @INC, 'support/bytecode', 'lib' }

use Language::P::Object qw(:all);
BEGIN { print "ok\n" }
use Language::P::Constants qw(:all);
BEGIN { print "ok\n" }
use Language::P::Keywords qw(:all);
BEGIN { print "ok\n" }
use Language::P::Opcodes qw(:all);
BEGIN { print "ok\n" }
use Language::P::Assembly qw(:all);
BEGIN { print "ok\n" }
use Language::P::Exception;
BEGIN { print "ok\n" }
use Language::P::Intermediate::BasicBlock;
BEGIN { print "ok\n" }
use Language::P::Intermediate::Code;
BEGIN { print "ok\n" }
use Language::P::Intermediate::Generator;
BEGIN { print "ok\n" }
use Language::P::Intermediate::Transform;
BEGIN { print "ok\n" }
use Language::P::Lexer;
BEGIN { print "ok\n" }
use Language::P::ParseTree;
BEGIN { print "ok\n" }
use Language::P::ParseTree::Visitor;
BEGIN { print "ok\n" }
use Language::P::ParseTree::PropagateContext;
BEGIN { print "ok\n" }
use Language::P::Parser::Exception;
BEGIN { print "ok\n" }
use Language::P::Parser::Lexicals;
BEGIN { print "ok\n" }
use Language::P::Parser::Regex;
BEGIN { print "ok\n" }
use Language::P::Parser;
BEGIN { print "ok\n" }
use Language::P;
BEGIN { print "ok\n" }
