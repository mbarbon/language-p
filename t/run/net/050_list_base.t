#!/usr/bin/perl -w

print "1..6\n";

if( defined &Internals::Net::get_class ) {
    $date_class = Internals::Net::get_class( 'System.DateTime' );

    $generic_list = Internals::Net::get_class( 'System.Collections.Generic.List`1' );
    $date_list = Internals::Net::specialize_type( $generic_list, $date_class );

    $array = Internals::Net::create( $date_list );

    $array->Add( Internals::Net::create( $date_class, 2010, 12, 16, 23, 13, 42 ) );
    $array->Add( undef );
    $array->Add( undef );

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
