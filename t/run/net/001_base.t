#!/usr/bin/perl -w

print "1..5\n";

if( defined &Internals::Net::get_class ) {
    $class = Internals::Net::get_class( 'System.DateTime' );
    print $class ? "ok\n" : "not ok\n";

    $days = Internals::Net::call_static( $class, 'DaysInMonth', 2011, 01 );
    print $days == 31 ? "ok\n" : "not ok - $days\n";

    $date = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 42 );
    print $date ? "ok\n" : "not ok\n";

    $sec = Internals::Net::get_property( $date, 'Second' );
    print $sec == 42 ? "ok\n" : "not ok - $sec\n";

    $date2 = Internals::Net::create( $class, 2009, 12, 16, 22, 13, 42 );

    $span = Internals::Net::call_method( $date, 'Subtract', $date2 );
    $days = Internals::Net::get_property( $span, 'Days' );
    print $days == 365 ? "ok\n" : "not ok - $days\n";
} else {
    print "ok - skipped\n" for 1..5;
}

