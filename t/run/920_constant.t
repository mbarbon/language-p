#!/usr/bin/perl -w

BEGIN { print "1..3\n"; }
BEGIN { unshift @INC, 'support/bytecode', 'lib' }

use constant T_FOO => 1;
use constant
  { T_BAZ => 2,
    T_BAR => 3,
    };

print T_FOO == 1 ? "ok\n" : "not ok\n";
print T_BAZ == 2 ? "ok\n" : "not ok\n";
print T_BAR == 3 ? "ok\n" : "not ok\n";
