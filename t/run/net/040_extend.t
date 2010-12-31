#!/usr/bin/perl -w

print "1..4\n";

if( defined &Internals::Net::extend ) {
    {
        package Example::Class;

        Internals::Net::extend( 'Example::Class', 'System.DateTime' );

        sub test_method {
            my( $self ) = @_;

            return Internals::Net::get_property( $self, 'Second' );
        }
    }

    $date = Example::Class->new( 2010, 12, 16, 22, 13, 42 );
    print $date ? "ok\n" : "not ok\n";
    print ref( $date ) eq 'Example::Class' ? "ok\n" : "not ok\n";

    $span = $date->Subtract( $date );
    $days = Internals::Net::get_property( $span, 'Days' );
    print $days == 0 ? "ok\n" : "not ok - $days\n";

    print $date->test_method == 42 ?  "ok\n" : "not ok\n";
} else {
    print "ok - skipped\n" for 1..4;
}
