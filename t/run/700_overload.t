BEGIN { unshift @INC, 'support/bytecode' }

package X;

use overload "+" => \&foo;

sub foo {
    my( $a, $b, $inv ) = @_;

    $X::inv = $inv;

    return $$a + $b;
}

package main;

print "1..4\n";

my $b = 3;
my $a = bless \$b, 'X';

$X::inv = -1;
print $a + 1 == 4 ? "ok\n" : "not ok\n";
print !$X::inv ? "ok\n" : "not ok\n";

$X::inv = 0;
print 1 + $a == 4 ? "ok\n" : "not ok\n";
print $X::inv ? "ok\n" : "not ok\n";
