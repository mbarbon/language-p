#!/usr/bin/perl -w

print "1..3\n";

@x = split ' ', 'ab   a v  f';
print "@x" eq 'ab a v f' ? "ok\n" : "not ok - '@x'\n";

@x = split ' ', '    ab   a v  f   ';
print "@x" eq 'ab a v f' ? "ok\n" : "not ok - '@x'\n";

$_ = '    ab   a v  f   ';
@x = split;
print "@x" eq 'ab a v f' ? "ok\n" : "not ok - '@x'\n";
