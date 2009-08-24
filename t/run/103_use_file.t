#!/usr/bin/perl -w

BEGIN {
    print "1..6\n";
    @INC = 't/run/files';
}

use Foo '2';
no Foo;
use Foo '4';

use Bar;
no Bar;

Foo::ok_foo( 5 );
Bar::ok_bar( 6 );
