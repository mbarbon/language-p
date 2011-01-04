#!/usr/bin/perl -w

print "1..5\n";

if( defined &Internals::Net::get_class ) {
    $class = Internals::Net::get_class( 'System.DateTime' );
    $date = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 42 );
    $date2 = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 42 );
    $date3 = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 43 );
    $type = Internals::Net::call_method( $class, 'GetType' );

    %m = ( $class => 'class',
           $date  => 'date',
           $type  => 'type',
           );

    # TODO not clear wether it is better to use object identity or stringification
    print $m{$class} eq 'class' ? "ok\n" : "not ok - $class => $m{$class}\n";
    print $m{$date} eq 'date' ? "ok\n" : "not ok - $date => $m{$date}\n";
    print $m{$date2} eq 'date' ? "ok\n" : "not ok - $date => $m{$date}\n";
    print exists $m{$date3} ? "not ok\n" : "ok\n";
    print $m{$type} eq 'type' ? "ok\n" : "not ok - $type => $m{$type}\n";
} else {
    print "ok - skipped\n" for 1..5;
}
