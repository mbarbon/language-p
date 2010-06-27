#!/usr/bin/perl -w

print "1..10\n";

$text = 'abcdefgh';

# no-op
$t = $text; $c = $t =~ tr///;
print $t eq 'abcdefgh' && $c == 0 ? "ok\n" : "not ok - '$t', $c\n";

# another no-op
$t = $text; $c = $t =~ tr///c;
print $t eq 'abcdefgh' && $c == 8 ? "ok\n" : "not ok - '$t', $c\n";

# a third no-op
$t = $text; $c = $t =~ tr/ae/ae/;
print $t eq 'abcdefgh' && $c == 2 ? "ok\n" : "not ok - '$t', $c\n";

# simple
$t = $text; $c = $t =~ tr/abcd/efgh/;
print $t eq 'efghefgh' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";

$t = $text; $c = $t =~ tr/abcd/ef/;
print $t eq 'efffefgh' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";

# delete
$t = $text; $c = $t =~ tr/abcd/ef/d;
print $t eq 'efefgh' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";

# squeeze
$t = $text; $c = $t =~ tr/abcd/ccee/s;
print $t eq 'ceefgh' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";

# complement
$t = $text; $c = $t =~ tr/abcd/defg/c;
print $t eq 'abcdgggg' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";

# complement + delete
$t = $text; $c = $t =~ tr/abcd/efghabcd/cd;
print $t eq 'abcd' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";

# complement + squeeze
$t = $text; $c = $t =~ tr/abcd/abcd/cs;
print $t eq 'abcdd' && $c == 4 ? "ok\n" : "not ok - '$t', $c\n";
