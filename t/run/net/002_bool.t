#!/usr/bin/perl -w

print "1..6\n";

if( defined &Internals::Net::get_class ) {
    $class = Internals::Net::get_class( 'System.String' );
    $string1 = Internals::Net::create( $class, '1', 1 );
    $string2 = Internals::Net::create( $class, '2', 1 );

    $true = Internals::Net::call_method( $string1, 'Equals', $string1 );
    print $true ? "ok\n" : "not ok\n";
    print $true == 1 ? "ok\n" : "not ok\n";

    $type = Internals::Net::call_method( $true, 'GetType' );
    print $type eq 'System.Boolean' ? "ok\n" : "not ok - $type\n";

    $false = Internals::Net::call_method( $string1, 'Equals', $string2 );
    print $false ? "not ok\n" : "ok\n";
    print $false == 0 ? "ok\n" : "not ok\n";

    $type = Internals::Net::call_method( $false, 'GetType' );
    print $type eq 'System.Boolean' ? "ok\n" : "not ok - $type\n";
} else {
    print "ok - skipped\n" for 1..6;
}
