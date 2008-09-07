#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Subroutine;
use Language::P::ParseTree qw(:all);

my $runtime = Language::P::Toy::Runtime->new;

my $fib = Language::P::Toy::Value::Subroutine->new( { bytecode   => [],
                                                  stack_size => 1,
                                                  } );

my @fib =
  ( o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 2 } ),
       ),
    o( 'parameter_index', index => 0 ),
    o( 'compare_i_lt_int' ),
    o( 'jump_if_eq_immed',
       value => 0,
       to    => 8,
       ),
    # if n < 2
    o( 'start_list' ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'end_list' ),
    o( 'return' ),
    # if n >= 2
    o( 'start_list' ),
    # fib( n - 1 )
    o( 'start_list' ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'parameter_index', index => 0 ),
    o( 'subtract' ),
    o( 'end_list' ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    # fib( n - 2 )
    o( 'start_list' ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 2 } ),
       ),
    o( 'parameter_index', index => 0 ),
    o( 'subtract' ),
    o( 'end_list' ),
    o( 'constant', value => $fib ),
    o( 'call' ),
    # sum
    o( 'add' ),
    o( 'end_list' ),
    o( 'return' ),
    );

$fib->{bytecode} = \@fib;

my @main =
  ( o( 'start_list' ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 10 } ),
       ),
    o( 'end_list' ),
    o( 'constant', value => $fib ),
    o( 'call', context => CXT_SCALAR ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 3 );
is( $stack[2]->as_integer, 89 );

1;
