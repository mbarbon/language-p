#!/usr/bin/perl -w

print "1..1\n";

if( defined &Internals::Net::get_class ) {
    $class = Internals::Net::get_class( 'System.DateTime' );
    $date = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 42 );
    $date2 = Internals::Net::create( $class, 2009, 12, 16, 22, 13, 42 );

    $span = $date->Subtract( $date2 );

    $days = Internals::Net::get_property( $span, 'Days' );
    print $days == 365 ? "ok\n" : "not ok - $days\n";
} else {
    print "ok - skipped\n" for 1..1;
}
