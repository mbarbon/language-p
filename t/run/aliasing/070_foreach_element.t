print "1..10\n";

@x = ( 1, 2, 3 );
%x = ( 1, 2, 3, 4, 5, 6 );

foreach ( $x[1], $x{3} ) {
    $_ = 7;
}

print $x[1] == 7 ? "ok\n" : "not ok\n";
print $x{3} == 7 ? "ok\n" : "not ok\n";

foreach my $t ( $x[1], $x{3} ) {
    $t = 8;
}

print $x[1] == 8 ? "ok\n" : "not ok\n";
print $x{3} == 8 ? "ok\n" : "not ok\n";

foreach my $t ( $x[7], $x{7} ) {
    print "# no assign\n";
}

print $#x == 7 ? "ok\n" : "not ok\n";
print exists $x{7} ? "ok\n" : "not ok\n";

foreach my $t ( $x[7], $x{7} ) {
    $t = 7;
}

print $#x == 7 ? "ok\n" : "not ok\n";
print $x[7] == 7 ? "ok\n" : "not ok\n";

print exists $x{7} ? "ok\n" : "not ok\n";
print $x{7} == 7 ? "ok\n" : "not ok\n";
