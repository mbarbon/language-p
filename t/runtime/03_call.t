#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Runtime;
use Language::P::Opcodes;
use Language::P::Value::Subroutine;

my $runtime = Language::P::Runtime->new;

my @add_mul =
  ( { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_parameter_index,
      index    => 0,
      },
    { function => \&Language::P::Opcodes::o_parameter_index,
      index    => 1,
      },
    { function => \&Language::P::Opcodes::o_add },
    { function => \&Language::P::Opcodes::o_parameter_index,
      index    => 2,
      },
    { function => \&Language::P::Opcodes::o_multiply },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_return },
    );

my $add_mul = Language::P::Value::Subroutine->new( { bytecode   => \@add_mul,
                                                      stack_size => 1,
                                                      } );

my @main =
  ( { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 1 } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 3 } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 7 } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => $add_mul,
      },
    { function => \&Language::P::Opcodes::o_call },
    { function => \&Language::P::Opcodes::o_end },
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 1 );
is( $stack[0]->as_integer, 28 );

1;
