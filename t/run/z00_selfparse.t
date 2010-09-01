#!/usr/bin/perl -w

BEGIN { print "1..1\n" }
BEGIN { unshift @INC, 'lib' }

use Language::P::Constants qw(:all);
# use Language::P::Keywords;
# use Language::P::Opcodes;
use Language::P::Assembly qw(:all);
use Language::P::Exception;
# use Language::P::Intermediate::BasicBlock;
use Language::P::Intermediate::Code;
# use Language::P::Intermediate::Generator;
# use Language::P::Intermediate::Transform;
# use Language::P::Lexer;
# use Language::P::ParseTree;
# use Language::P::ParseTree::PropagateContext;
# use Language::P::ParseTree::Visitor;
# use Language::P::Parser;
use Language::P::Parser::Exception;
use Language::P::Parser::Lexicals;
# use Language::P::Parser::Regex;
# use Language::P;

print "ok 1 - got there\n";
