#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 14;

use_ok( 'Language::P::Toy::Runtime' );
use_ok( 'Language::P::Toy::Opcodes' );
use_ok( 'Language::P::Toy::Value::Any' );
use_ok( 'Language::P::Toy::Value::Array' );
use_ok( 'Language::P::Toy::Value::Code' );
use_ok( 'Language::P::Toy::Value::Handle' );
use_ok( 'Language::P::Toy::Value::List' );
use_ok( 'Language::P::Toy::Value::Reference' );
use_ok( 'Language::P::Toy::Value::Scalar' );
use_ok( 'Language::P::Toy::Value::ScratchPad' );
use_ok( 'Language::P::Toy::Value::StringNumber' );
use_ok( 'Language::P::Toy::Value::Subroutine' );
use_ok( 'Language::P::Toy::Value::SymbolTable' );
use_ok( 'Language::P::Toy::Value::Typeglob' );
