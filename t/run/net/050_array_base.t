#!/usr/bin/perl -w

print "1..6\n";

if( defined &Internals::Net::get_class ) {
    $date_class = Internals::Net::get_class( 'System.DateTime' );
    $array_class = Internals::Net::get_class( 'System.Array' );

    $array = $array_class->CreateInstance( $date_class, 3 );
    $array->[0] = Internals::Net::create( $date_class, 2010, 12, 16, 22, 13, 42 );
    $array->[1] = Internals::Net::create( $date_class, 2010, 12, 16, 22, 14, 42 );
    $array->[2] = Internals::Net::create( $date_class, 2010, 12, 16, 23, 13, 42 );

    print @$array == 3 ? "ok\n" : "not ok\n";
    print $#$array == 2 ? "ok\n" : "not ok\n";

    @copy = @$array;

    print @copy == 3 ? "ok\n" : "not ok\n";

    print $array->[0] eq $copy[0] ? "ok\n" : "not ok\n";
    print $array->[1] ne $copy[0] ? "ok\n" : "not ok\n";
    print $array->[2] eq $copy[2] ? "ok\n" : "not ok\n";
} else {
    print "ok - skipped\n" for 1..6;
}
