#!/usr/bin/perl -w

print "1..4\n";

sub add3 {
    my( $x ) = @_;

    return sub {
        my( $y ) = @_;

        return sub {
            my( $z ) = @_;

            return $x + $y + $z;
        };
    };
}

print add3( 1 )->( 2 )->( 3 ) == 6 ? "ok 1\n" : "not ok 1\n";
$add3_1 = add3( 1 );
$add3_1_2 = $add3_1->( 2 );
$add3_1_3 = $add3_1->( 3 );
print $add3_1->( 4 )->( 7 ) == 12 ? "ok 2\n" : "not ok 2\n";
print $add3_1_2->( 3 ) == 6 ? "ok 3\n" : "not ok 3\n";
print $add3_1_3->( 5 ) == 9 ? "ok 4\n" : "not ok 4\n";
