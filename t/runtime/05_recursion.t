#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Runtime;
use Language::P::Opcodes qw(o);
use Language::P::Value::Subroutine;

my $runtime = Language::P::Runtime->new;

my $fib = Language::P::Value::Subroutine->new( { bytecode   => [],
                                                  stack_size => 1,
                                                  } );

my @fib =
  ( o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 2 } ),
       ),
    o( 'parameter_index', index => 0 ),
    o( 'compare_i_lt_int' ),
    o( 'jump_if_eq_immed',
       value => 0,
       to    => 8,
       ),
    # if n < 2
    o( 'start_call' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'push_scalar' ),
    o( 'return' ),
    # if n >= 2
    o( 'start_call' ),
    # fib( n - 1 )
    o( 'start_call' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'parameter_index', index => 0 ),
    o( 'subtract' ),
    o( 'push_scalar' ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    # fib( n - 2 )
    o( 'start_call' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 2 } ),
       ),
    o( 'parameter_index', index => 0 ),
    o( 'subtract' ),
    o( 'push_scalar' ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    # sum
    o( 'add' ),
    o( 'push_scalar' ),
    o( 'return' ),
    );

$fib->{bytecode} = \@fib;

my @main =
  ( o( 'start_call' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 10 } ),
       ),
    o( 'push_scalar' ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 1 );
is( $stack[0]->as_integer, 89 );

1;
