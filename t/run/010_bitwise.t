#!/usr/bin/perl -w

print "1..11\n";

# or
$x = "a"; $y = "b";
$z = $x | $y;

print $z eq "c" ? "ok\n" : "not ok - $z\n";

$z = $x;
$z |= $y;

print $z eq "c" ? "ok\n" : "not ok - $z\n";

$x = 150; $y = 105;
$z = $x | $y;

print $z == 255 ? "ok\n" : "not ok - $z\n";

# and
$x = "a"; $y = "b";
$z = $x & $y;

print $z eq "`" ? "ok\n" : "not ok - $z\n";

$x = 245; $y = 105;
$z = $x & $y;

print $z == 97 ? "ok\n" : "not ok - $z\n";

$z = $x;
$z &= $y;

print $z == 97 ? "ok\n" : "not ok - $z\n";

# xor
$x = "A"; $y = "b";
$z = $x ^ $y;

print $z eq "#" ? "ok\n" : "not ok - $z\n";

$x = 245; $y = 105;
$z = $x ^ $y;

print $z == 156 ? "ok\n" : "not ok - $z\n";

$z = $x;
$z ^= $y;

print $z == 156 ? "ok\n" : "not ok - $z\n";

# not
$x = 123;
$z = ~$x & 0xffff;

print $z == 65412 ? "ok\n" : "not ok - $z\n";

$x = "abc";
$z = ~$x;

print $z eq "\x9e\x9d\x9c" ? "ok\n" : "not ok - $z\n";
