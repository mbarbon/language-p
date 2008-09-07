#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Subroutine;
use Language::P::ParseTree qw(:all);

my $runtime = Language::P::Toy::Runtime->new;

my @add_mul =
  ( o( 'start_list' ),
    o( 'parameter_index', index => 0 ),
    o( 'parameter_index', index => 1 ),
    o( 'add' ),
    o( 'parameter_index', index => 2 ),
    o( 'multiply' ),
    o( 'end_list' ),
    o( 'return' ),
    );

my $add_mul = Language::P::Toy::Value::Subroutine->new( { bytecode   => \@add_mul,
                                                      stack_size => 1,
                                                      } );

my @main =
  ( o( 'start_list' ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 3 } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 7 } ),
       ),
    o( 'end_list' ),
    o( 'constant', value => $add_mul ),
    o( 'call', context => CXT_SCALAR ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 3 );
is( $stack[2]->as_integer, 28 );

1;
