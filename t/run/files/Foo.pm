package Foo;

sub import {
    my( $cp, $cf, $cl ) = caller;

    print "$cp $cf $cl" eq 'W t/run/123_caller.t 86' ? "ok\n" : "not ok - $cp $cf $cl\n";
}

1;
