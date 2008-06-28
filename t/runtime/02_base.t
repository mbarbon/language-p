#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use Language::P::Runtime;
use Language::P::Opcodes;
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
  ( { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_constant,
      value    => $fh1,
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { string => "Hello, world!\n" } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_print },
    { function => \&Language::P::Opcodes::o_end },
    );

$runtime->reset;
$runtime->run_bytecode( \@program1 );

is( $$out1, "Hello, world!\n" );

my( $out2, $fh2 ) = _oth();

my @program2 =
  ( { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_constant,
      value    => $fh2,
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { string => "Hello, " } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { string => "world!" } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { string => "\n" } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_print },
    { function => \&Language::P::Opcodes::o_end },
    );

$runtime->reset;
$runtime->run_bytecode( \@program2 );

is( $$out2, "Hello, world!\n" );

my @program3 =
  ( { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 1 } ),
      },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 3 } ),
      },
    { function => \&Language::P::Opcodes::o_add },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 7 } ),
      },
    { function => \&Language::P::Opcodes::o_multiply },
    { function => \&Language::P::Opcodes::o_end },
    );

$runtime->reset;
$runtime->run_bytecode( \@program3 );
my @stack3 = $runtime->stack_copy;

is( scalar @stack3, 1 );
is( $stack3[0]->as_integer, 28 );
