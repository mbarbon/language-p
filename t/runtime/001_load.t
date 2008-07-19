#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 14;

use_ok( 'Language::P::Runtime' );
use_ok( 'Language::P::Opcodes' );
use_ok( 'Language::P::Value::Any' );
use_ok( 'Language::P::Value::Array' );
use_ok( 'Language::P::Value::Code' );
use_ok( 'Language::P::Value::Handle' );
use_ok( 'Language::P::Value::List' );
use_ok( 'Language::P::Value::Reference' );
use_ok( 'Language::P::Value::Scalar' );
use_ok( 'Language::P::Value::ScratchPad' );
use_ok( 'Language::P::Value::StringNumber' );
use_ok( 'Language::P::Value::Subroutine' );
use_ok( 'Language::P::Value::SymbolTable' );
use_ok( 'Language::P::Value::Typeglob' );
