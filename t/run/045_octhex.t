#!/usr/bin/perl -w

print "1..5\n";

# base oct
print oct( '11' )   == 9 ? "ok\n" : "not ok\n";
print oct( ' 11z' ) == 9 ? "ok\n" : "not ok\n";

# oct binary
print oct( '0b11' ) == 3 ? "ok\n" : "not ok\n";

# oct hexadecimal
print oct( '0x11' ) == 17 ? "ok\n" : "not ok\n";

# base hex
print hex( 'ff' ) == 255 ? "ok\n" : "not ok\n";
