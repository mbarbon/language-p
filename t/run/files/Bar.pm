package Bar;

if( __FILE !~ /[a]/ ) {
    die "Something is wrong";
}

sub ok_bar {
    print "ok $_[0]\n";
}

1;
