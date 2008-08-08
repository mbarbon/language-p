#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use Language::P::Runtime;
use Language::P::Opcodes qw(o);
use Language::P::Value::StringNumber;
use Language::P::Value::Handle;

sub _oth {
    my $buf = "";
    open my $fh, '>', \$buf;
    my $ofh = Language::P::Value::Handle->new( { handle => $fh } );

    return ( \$buf, $ofh );
}

my $runtime = Language::P::Runtime->new;
my( $out1, $fh1 ) = _oth();

my @program1 =
  ( o( 'start_list' ),
    o( 'constant', value => $fh1 ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { string => "Hello, world!\n" } ),
       ),
    o( 'end_list' ),
    o( 'print' ),
    o( 'end' ),
  );

$runtime->reset;
$runtime->run_bytecode( \@program1 );

is( $$out1, "Hello, world!\n" );

my( $out2, $fh2 ) = _oth();

my @program2 =
  ( o( 'start_list' ),
    o( 'constant', value => $fh2 ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { string => "Hello, " } ),
       ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { string => "world!" } ),
       ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { string => "\n" } ),
       ),
    o( 'end_list' ),
    o( 'print' ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@program2 );

is( $$out2, "Hello, world!\n" );

my @program3 =
  ( o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 3 } ),
       ),
    o( 'add' ),
    o( 'constant',
       value => Language::P::Value::StringNumber->new( { integer => 7 } ),
       ),
    o( 'multiply' ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@program3 );
my @stack3 = $runtime->stack_copy;

is( scalar @stack3, 3 );
is( $stack3[2]->as_integer, 28 );
