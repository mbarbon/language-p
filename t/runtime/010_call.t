#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Subroutine;
use Language::P::Constants qw(:all);

my $runtime = Language::P::Toy::Runtime->new;

my @add_mul =
  ( o( 'parameter_index', index => 0 ),
    o( 'parameter_index', index => 1 ),
    o( 'add' ),
    o( 'parameter_index', index => 2 ),
    o( 'multiply' ),
    o( 'make_list', count => 1 ),
    o( 'return' ),
    );

my $add_mul = Language::P::Toy::Value::Subroutine->new
                  ( $runtime,{ bytecode   => \@add_mul,
                               stack_size => 1,
                               } );

my @main =
  ( o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 3 } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 7 } ),
       ),
    o( 'make_list', count => 3 ),
    o( 'constant', value => $add_mul ),
    o( 'call', context => CXT_SCALAR ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 3 );
is( $stack[2]->as_integer( $runtime ), 28 );

1;
