#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Handle;

sub _oth {
    my $buf = "";
    open my $fh, '>', \$buf;
    my $ofh = Language::P::Toy::Value::Handle->new( { handle => $fh } );

    return ( \$buf, $ofh );
}

my $runtime = Language::P::Toy::Runtime->new;
my( $out1, $fh1 ) = _oth();

my @program1 =
  ( o( 'constant', value => $fh1 ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { string => "Hello, world!\n" } ),
       ),
    o( 'make_list', count => 1 ),
    o( 'print' ),
    o( 'end' ),
  );

$runtime->reset;
$runtime->run_bytecode( \@program1 );

is( $$out1, "Hello, world!\n" );

my( $out2, $fh2 ) = _oth();

my @program2 =
  ( o( 'constant', value => $fh2 ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { string => "Hello, " } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { string => "world!" } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { string => "\n" } ),
       ),
    o( 'make_list', count => 3 ),
    o( 'print' ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@program2 );

is( $$out2, "Hello, world!\n" );

my @program3 =
  ( o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 1 } ),
       ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 3 } ),
       ),
    o( 'add' ),
    o( 'constant',
       value => Language::P::Toy::Value::StringNumber->new( { integer => 7 } ),
       ),
    o( 'multiply' ),
    o( 'end' ),
    );

$runtime->reset;
$runtime->run_bytecode( \@program3 );
my @stack3 = $runtime->stack_copy;

is( scalar @stack3, 3 );
is( $stack3[2]->as_integer, 28 );
