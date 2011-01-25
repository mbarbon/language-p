#!/usr/bin/perl -w

print "1..4\n";

if( defined &Internals::Net::get_class ) {
    $date_class = Internals::Net::get_class( 'System.DateTime' );

    $generic_list = Internals::Net::get_class( 'System.Collections.Generic.List`1' );
    $date_list = Internals::Net::specialize_type( $generic_list, $date_class );

    print $generic_list eq 'System.Collections.Generic.List`1[T]' ? "ok\n" : "not ok - $generic_list\n";
    print $date_list eq 'System.Collections.Generic.List`1[System.DateTime]' ? "ok\n" : "not ok - $date_list\n";

    $list = Internals::Net::create( $date_list, 2 );

    $count = Internals::Net::get_property( $list, 'Count' );
    $capacity = Internals::Net::get_property( $list, 'Capacity' );

    print $count == 0 ? "ok\n" : "not ok - $count\n";
    print $capacity == 2 ? "ok\n" : "not ok - $capacity\n";
} else {
    print "ok - skipped\n" for 1..4;
}
