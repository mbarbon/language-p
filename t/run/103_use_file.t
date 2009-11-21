#!/usr/bin/perl -w

BEGIN {
    print "1..6\n";
    @INC = 't/run/files';
}

use Moo '2';
no Moo;
use Moo '4';

use Bar;
no Bar;

Moo::ok_moo( 5 );
Bar::ok_bar( 6 );
