#!/usr/bin/perl -w

print "1..7\n";

$baz = 7;
$moo = 8;

print "ok 1\n";

goto IN_BLOCK;

print "not ok - should not print\n";
{
    local $baz = 4;
    my $foo = 1;
  IN_BLOCK:
    local $moo = 7;
    my $bar = 1;
    goto IN2_BLOCK;
    {
        local $moo = 17;
      IN2_BLOCK:
        local $moo = 8;
        local $moo = 13;
        goto OUT_BLOCK;
        local $moo = 19;
    }
    local $moo = 9;
  OUT_BLOCK:
    print defined $foo ? "not ok 2\n" : "ok 2\n";
    print $bar ? "ok 3\n" : "not ok 3\n";
    print $baz == 7 ? "ok 4\n" : "not ok 4\n";
    print $moo == 7 ? "ok 5\n" : "not ok 5\n";
}

print $baz == 7 ? "ok 6\n" : "not ok 6\n";
print $moo == 8 ? "ok 7\n" : "not ok 7\n";
