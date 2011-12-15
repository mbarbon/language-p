#!/usr/bin/perl -w

print "1..10\n";

sub assign {
    $_[1] = 7;
}

sub no_assign {
    return $_[1];
}

@x = ( 1, 2, 3 );
%x = ( 1, 2, 3, 4, 5, 6 );

no_assign( 1, $x[1], 3 );
print $x[1] == 2 ? "ok\n" : "not ok\n";

no_assign( 1, $x{3}, 3 );
print $x{3} == 4 ? "ok\n" : "not ok\n";

assign( 1, $x[1], 3 );
print $x[1] == 7 ? "ok\n" : "not ok\n";

assign( 1, $x{3}, 3 );
print $x{3} == 7 ? "ok\n" : "not ok\n";

no_assign( 1, $x[7], 3 );
print $#x == 2 ? "ok\n" : "not ok\n";

no_assign( 1, $x{7}, 3 );
print !exists $x{7} ? "ok\n" : "not ok\n";

assign( 1, $x[7], 3 );
print $#x == 7 ? "ok\n" : "not ok\n";
print $x[7] == 7 ? "ok\n" : "not ok\n";

assign( 1, $x{7}, 3 );
print exists $x{7} ? "ok\n" : "not ok\n";
print $x{7} == 7 ? "ok\n" : "not ok\n";
