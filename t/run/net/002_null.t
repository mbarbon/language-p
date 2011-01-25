#!/usr/bin/perl -w

print "1..3\n";

if( defined &Internals::Net::get_class ) {
    $obj_class = Internals::Net::get_class( 'System.Object' );
    $type_class = Internals::Net::get_class( 'System.Type' );
    $convert_class = Internals::Net::get_class( 'System.Convert' );

    $null = Internals::Net::call_method( $type_class, 'GetMethod', 'DummyMethod' );
    print defined $null ? "not ok\n" : "ok\n";

    $null = Internals::Net::call_static( $convert_class, 'ChangeType', undef, $obj_class );
    print defined $null ? "not ok\n" : "ok\n";

    $eq = Internals::Net::call_static( $obj_class, 'Equals', undef, undef );
    print $eq ? "ok\n" : "not ok - null == null\n";
} else {
    print "ok - skipped\n" for 1..3;
}
