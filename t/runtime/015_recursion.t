#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Subroutine;
use Language::P::Constants qw(:all);

my $runtime = Language::P::Toy::Runtime->new;

my $fib = Language::P::Toy::Value::Subroutine->new
              ( $runtime,
                { bytecode   => [],
                  stack_size => 1,
                  } );

my @fib =
  ( o( 'parameter_index', index => 0 ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 2 } ),
       ),
    o( 'compare_i_ge_int' ),
    o( 'jump_if_eq_immed',
       value => 1,
       to    => 7,
       ),
    # if n < 2
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } ),
       ),
    o( 'make_list', count => 1, context => CXT_LIST ),
    o( 'return' ),
    # if n >= 2
    # fib( n - 1 )
    o( 'parameter_index', index => 0 ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } ),
       ),
    o( 'subtract' ),
    o( 'make_list', count => 1, context => CXT_LIST ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    # fib( n - 2 )
    o( 'parameter_index', index => 0 ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 2 } ),
       ),
    o( 'subtract' ),
    o( 'make_list', count => 1, context => CXT_LIST ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    # sum
    o( 'add' ),
    o( 'make_list', count => 1, context => CXT_LIST ),
    o( 'return' ),
    );

$fib->{bytecode} = \@fib;

my @main =
  ( o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 10 } ),
       ),
    o( 'make_list', count => 1, context => CXT_LIST ),
    o( 'constant', value => $fib ),
    o( 'call', context => CXT_SCALAR ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 3 );
is( $stack[2]->as_integer( $runtime ), 89 );

1;
