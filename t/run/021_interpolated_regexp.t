#!/usr/bin/perl -w

print "1..5\n";

$text = 'abbcccddddeeeeeffffff';
@match     = ( '^a', 'bc', 'de+f' );
@not_match = ( 'bac', 'df' );

foreach $rx ( @match ) {
    print $text =~ /$rx/ ? "ok\n" : "not ok\n";
}

foreach $rx ( @not_match ) {
    print $text !~ /$rx/ ? "ok\n" : "not ok\n";
}
