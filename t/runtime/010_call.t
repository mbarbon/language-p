#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Runtime;
use Language::P::Opcodes qw(o);
use Language::P::Value::Subroutine;

my $runtime = Language::P::Runtime->new;

my @add_mul =
  ( o( 'start_call' ),
    o( 'parameter_index', index => 0 ),
    o( 'parameter_index', index => 1 ),
    o( 'add' ),
    o( 'parameter_index', index => 2 ),
    o( 'multiply' ),
    o( 'push_scalar' ),
    o( 'return' ),
    );

my $add_mul = Language::P::Value::Subroutine->new( { bytecode   => \@add_mul,
                                                      stack_size => 1,
                                                      } );

my @main =
  ( o( 'start_call' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'push_scalar' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 3 } ),
       ),
    o( 'push_scalar' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 7 } ),
       ),
    o( 'push_scalar' ),
    o( 'constant', value => $add_mul ),
    o( 'call' ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 1 );
is( $stack[0]->as_integer, 28 );

1;
