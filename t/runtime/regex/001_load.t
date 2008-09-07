#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use_ok( 'Language::P::Parser::Regex' );
use_ok( 'Language::P::Toy::Runtime' );
use_ok( 'Language::P::Toy::Opcodes' );
use_ok( 'Language::P::Toy::Value::StringNumber' );
