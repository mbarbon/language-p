#!/usr/bin/perl -w

print "1..5\n";

$text = 'abbcccddddeeeeeffffff';
@rx = ( '^a', 'bac', 'bc', 'df', 'de+f' );

$i = 0;
foreach $rx ( @rx ) {
    if ( $i % 2 ) {
        print $text !~ /$rx/ ? "ok\n" : "not ok\n";
    } else {
        print $text =~ /$rx/ ? "ok\n" : "not ok\n";
    }
    $i = $i + 1;
}
