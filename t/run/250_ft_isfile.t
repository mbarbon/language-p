#!/usr/bin/perl -w

print "1..4\n";

print -f 't/run/021_qr.t' ? "ok\n" : "not ok\n";
print -f 't' ? "not ok\n" : "ok\n";
print defined -f 't' ? "ok\n" : "not ok\n";
print defined -f 't/dhadjkas' ? "not ok\n" : "ok\n";
