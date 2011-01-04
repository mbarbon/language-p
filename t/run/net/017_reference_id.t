#!/usr/bin/perl -w

print "1..5\n";

if( defined &Internals::Net::get_class ) {
    $class = Internals::Net::get_class( 'System.DateTime' );
    $date = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 42 );
    $date2 = Internals::Net::create( $class, 2010, 12, 16, 22, 13, 42 );
    $type = Internals::Net::call_method( $class, 'GetType' );
    $type2 = Internals::Net::call_method( $class, 'GetType' );

    %m = ( \$class => 'class',
           \$date  => 'date',
           \$type  => 'type',
           );

    print $m{\$class} eq 'class' ? "ok\n" : "not ok - ${\\$class} => $m{\$class}\n";
    print $m{\$date} eq 'date' ? "ok\n" : "not ok - ${\\$date} => $m{\$date}\n";
    print exists $m{\$date2} ? "not ok\n" : "ok\n";
    print $m{\$type} eq 'type' ? "ok\n" : "not ok - ${\\$type} => $m{\$type}\n";
    print $m{\$type2} eq 'type' ? "ok\n" : "not ok - ${\\$type2} => $m{\$type2}\n";
} else {
    print "ok - skipped\n" for 1..5;
}
