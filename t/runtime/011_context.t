#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use Language::P::Runtime;
use Language::P::Opcodes qw(o);
use Language::P::Value::Subroutine;
use Language::P::ParseTree qw(:all);

my $runtime = Language::P::Runtime->new;

my @wantarray =
  ( o( 'start_list' ),
    o( 'want' ),
    o( 'end_list' ),
    o( 'return' ),
    );

my $want = Language::P::Value::Subroutine->new
               ( { bytecode   => \@wantarray,
                   stack_size => 1,
                   } );

my @main =
  ( o( 'start_list' ),
    o( 'end_list' ),
    o( 'constant', value   => $want ),
    o( 'call',     context => CXT_VOID ),
    o( 'start_list' ),
    o( 'end_list' ),
    o( 'constant', value   => $want ),
    o( 'call',     context => CXT_SCALAR ),
    o( 'start_list' ),
    o( 'end_list' ),
    o( 'constant', value   => $want ),
    o( 'call',     context => CXT_LIST ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 4 );
is( $stack[2]->as_string, '' );
is( $stack[3]->get_item( 0 )->as_integer, 1 );

1;
