#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use_ok( 'Language::P::Parser::Regex' );
use_ok( 'Language::P::Runtime' );
use_ok( 'Language::P::Opcodes' );
use_ok( 'Language::P::Value::StringNumber' );
