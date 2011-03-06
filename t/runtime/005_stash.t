#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

use Language::P::Constants qw(:all);
use Language::P::Toy::Runtime;
use Language::P::Toy::Value::SymbolTable;
use Language::P::Toy::Value::MainSymbolTable;

my $runtime = Language::P::Toy::Runtime->new;
my $st = $runtime->symbol_table;

is( $st->is_main, 1 );

my $foo_cr = $st->get_package( $runtime, 'Foo', 1 );
isa_ok( $foo_cr, 'Language::P::Toy::Value::SymbolTable', 'get_package Foo' );

my $foo_glob = $st->get_symbol( $runtime, 'Foo::', VALUE_GLOB, 0 );
is( $foo_glob->get_slot( $runtime, 'hash' ), $foo_cr, 'package glob' );

my $bar_nc = $st->get_package( $runtime, 'Bar', 0 );
is( $bar_nc, undef, 'do not create package unless required' );

my $bar_baz_cr = $st->get_package( $runtime, 'Bar::Baz', 1 );
isa_ok( $bar_baz_cr, 'Language::P::Toy::Value::SymbolTable', 'get_package Bar::Baz' );

my $bar_glob = $st->get_symbol( $runtime, 'Bar::', VALUE_GLOB, 0 );
my $bar_st = $bar_glob->get_slot( $runtime, 'hash' );
isa_ok( $bar_st, 'Language::P::Toy::Value::SymbolTable' );

my $baz_glob = $bar_st->get_symbol( $runtime, 'Baz::', VALUE_GLOB, 0 );
my $bar_baz_st = $baz_glob->get_slot( $runtime, 'hash' );
isa_ok( $bar_baz_st, 'Language::P::Toy::Value::SymbolTable' );
is( $bar_baz_st, $bar_baz_cr );
