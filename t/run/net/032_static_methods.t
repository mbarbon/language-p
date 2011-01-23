#!/usr/bin/perl -w

print "1..1\n";

if( defined &Internals::Net::get_class ) {
    $class = Internals::Net::get_class( 'System.DateTime' );

    $days = $class->DaysInMonth( 2011, 01 );
    print $days == 31 ? "ok\n" : "not ok - $days\n";
} else {
    print "ok - skipped\n" for 1..1;
}
