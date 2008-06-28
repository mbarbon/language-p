#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use Language::P::Runtime;
use Language::P::Opcodes;
use Language::P::Value::Subroutine;

my $runtime = Language::P::Runtime->new;

my $fib = Language::P::Value::Subroutine->new( { bytecode   => [],
                                                  stack_size => 1,
                                                  } );

my @fib =
  ( { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 2 } ),
      },
    { function => \&Language::P::Opcodes::o_parameter_index,
      index    => 0,
      },
    { function => \&Language::P::Opcodes::o_compare_i_lt },
    { function => \&Language::P::Opcodes::o_jump_if_eq_immed,
      value    => 0,
      to       => 6,
      },
    # if n < 2
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 1 } ),
      },
    { function => \&Language::P::Opcodes::o_return },
    # if n >= 2
    # fib( n - 1 )
    { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 1 } ),
      },
    { function => \&Language::P::Opcodes::o_parameter_index,
      index    => 0,
      },
    { function => \&Language::P::Opcodes::o_subtract },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => $fib,
      },
    { function => \&Language::P::Opcodes::o_call },
    # fib( n - 2 )
    { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 2 } ),
      },
    { function => \&Language::P::Opcodes::o_parameter_index,
      index    => 0,
      },
    { function => \&Language::P::Opcodes::o_subtract },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => $fib,
      },
    { function => \&Language::P::Opcodes::o_call },
    # sum
    { function => \&Language::P::Opcodes::o_add },
    { function => \&Language::P::Opcodes::o_return },
    );

$fib->{bytecode} = \@fib;

my @main =
  ( { function => \&Language::P::Opcodes::o_start_call },
    { function => \&Language::P::Opcodes::o_constant,
      value    => Language::P::Value::StringNumber->new( { integer => 10 } ),
      },
    { function => \&Language::P::Opcodes::o_push_scalar },
    { function => \&Language::P::Opcodes::o_constant,
      value    => $fib,
      },
    { function => \&Language::P::Opcodes::o_call },
    { function => \&Language::P::Opcodes::o_end },
    );

$runtime->reset;
$runtime->run_bytecode( \@main );
my @stack = $runtime->stack_copy;

is( scalar @stack, 1 );
is( $stack[0]->as_integer, 89 );

1;
