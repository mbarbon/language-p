#!/usr/bin/perl -w

print "1..4\n";

@a = 7;

print 'a' x 4 eq 'aaaa' ? "ok\n" : "not ok\n";
print @a x 4 eq '1111' ? "ok\n" : "not ok\n";

@x = ( @a ) x 4;

print "@x" eq "7 7 7 7" ? "ok\n" : "not ok -  @x\n";

@x = @a x 4;

print "@x" eq "1111" ? "ok\n" : "not ok -  @x\n";
