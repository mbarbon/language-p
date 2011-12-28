#!/usr/bin/perl -w

print "1..4\n";

sub assign_all {
    $_ = 8 foreach @_;
}

sub assign_element {
    $_ = 8 foreach $_[1], $_[3];
}

sub no_assign_all {
    1 foreach @_;
}

sub no_assign_element {
    1 foreach $_[1], $_[3];
}

@x = ( 1, 2, 3, 4, 5 );
no_assign_all( @x );
print "@x" eq '1 2 3 4 5' ? "ok\n" : "not ok - @x\n";

@x = ( 1, 2, 3, 4, 5 );
no_assign_element( @x );
print "@x" eq '1 2 3 4 5' ? "ok\n" : "not ok - @x\n";

@x = ( 1, 2, 3, 4, 5 );
assign_all( @x );
print "@x" eq '8 8 8 8 8' ? "ok\n" : "not ok - @x\n";

@x = ( 1, 2, 3, 4, 5 );
assign_element( @x );
print "@x" eq '1 8 3 8 5' ? "ok\n" : "not ok - @x\n";
