#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Subroutine;
use Language::P::Constants qw(:all);

my $runtime = Language::P::Toy::Runtime->new;

my @wantarray =
  ( o( 'want' ),
    o( 'make_list', arg_count => 1, context => CXT_LIST ),
    o( 'return' ),
    );

my $want = Language::P::Toy::Value::Subroutine->new
               ( $runtime,
                 { bytecode   => \@wantarray,
                   stack_size => 1,
                   } );

my @main =
  ( o( 'make_list', arg_count => 0, context => CXT_LIST ),
    o( 'constant', value   => $want ),
    o( 'call',     context => CXT_VOID ),
    o( 'make_list', arg_count => 0, context => CXT_LIST ),
    o( 'constant', value   => $want ),
    o( 'call',     context => CXT_SCALAR ),
    o( 'make_list', arg_count => 0, context => CXT_LIST ),
    o( 'constant', value   => $want ),
    o( 'call',     context => CXT_LIST ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 5 );
isa_ok( $stack[2], 'Language::P::Toy::Value::List' );
is( $stack[3]->as_string( $runtime ), '' );
is( $stack[4]->get_item( $runtime, 0 )->as_integer( $runtime ), 1 );

1;
