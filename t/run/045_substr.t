#!/usr/bin/perl -w

print "1..8\n";

$x = "abcdef";

# accessor
print substr( $x, 3 ) eq 'def' ? "ok\n" : "not ok\n";
print substr( $x, 2, 3 ) eq 'cde' ? "ok\n" : "not ok\n";
print substr( $x, 3, -1 ) eq 'de' ? "ok\n" : "not ok\n";
print substr( $x, -4, -1 ) eq 'cde' ? "ok\n" : "not ok\n";

# mutator
$r = substr( $x, 3, -1, '123' );
print $r eq 'de' ? "ok\n" : "not ok - $r\n";
print $x eq 'abc123f' ? "ok\n" : "not ok - $x\n";

# lvalue
$r = substr( $x, 3, -1 ) = 'de';
print $r eq 'de' ? "ok\n" : "not ok - $r\n";
print $x eq 'abcdef' ? "ok\n" : "not ok - $x\n";
