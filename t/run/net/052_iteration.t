#!/usr/bin/perl -w

print "1..7\n";

if( defined &Internals::Net::get_class ) {
    $object_class = Internals::Net::get_class( 'System.Object' );
    $date_class = Internals::Net::get_class( 'System.DateTime' );
    $array_class = Internals::Net::get_class( 'System.Array' );
    $scalar_class = Internals::Net::get_class( 'org.mbarbon.p.values.P5Scalar' );

    $array = $array_class->CreateInstance( $object_class, 2 );
    $array->[0] = Internals::Net::create( $date_class, 2010, 12, 16, 22, 13, 42 );
    $array->[1] = undef;

    $idx = 0;
    foreach my $i ( @$array ) {
        print $i eq '12/16/2010 22:13:42' ? "ok\n" : "not ok - $i\n" if $idx == 0;
        print defined $i ? "not ok - $i\n" : "ok\n" if $idx == 1;
        ++$idx;
    }

    $idx = 0;
    foreach my $i ( 1, @$array, 2 ) {
        print $i eq '12/16/2010 22:13:42' ? "ok\n" : "not ok - $i\n" if $idx == 1;
        print defined $i ? "not ok - $i\n" : "ok\n" if $idx == 2;
        ++$idx;
    }

    $sarray = $array_class->CreateInstance( $scalar_class, 3 );
    $ref = \1;
    $sarray->[0] = $ref;
    $sarray->[1] = undef;
    $sarray->[2] = "a";

    $idx = 0;
    foreach my $i ( @$sarray ) {
        print $i eq $ref ? "ok\n" : "not ok - $i\n" if $idx == 0;
        print defined $i ? "not ok\n" : "ok\n" if $idx == 1;
        print $i eq "a" ? "ok\n" : "not ok - $i\n" if $idx == 2;
        ++$idx;
    }
} else {
    print "ok - skipped\n" for 1..7;
}
