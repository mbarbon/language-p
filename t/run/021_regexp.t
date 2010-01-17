#!/usr/bin/perl -w

print "1..29\n";

$text = 'abbcccddddeeeeeffffff';

# match
print $text =~ /^a/ ? "ok\n" : "not ok\n";
print $text =~ /bc/ ? "ok\n" : "not ok\n";
print $text =~ /de+f/ ? "ok\n" : "not ok\n";

# not match
print $text !~ /bac/ ? "ok\n" : "not ok\n";

# quantifiers
print $text =~ /eg*f/ ? "ok\n" : "not ok\n";
print $text =~ /eg?f/ ? "ok\n" : "not ok\n";
print $text !~ /g+f/ ? "ok\n" : "not ok\n";

# quantified group
print $text =~ /(a|b)*/ ? "ok\n" : "not ok\n";

# alternation
print $text =~ /(a|b|c)d/ ? "ok\n" : "not ok\n";

# captures
print $text =~ /(a|b|c)d/ ? "ok\n" : "not ok\n";
print $1 eq 'c' ? "ok\n" : "not ok\n";

{
    $text =~ /(not match)/;

    print $1 eq 'c' ? "ok\n" : "not ok\n";

    print $text =~ /(d+)(e+)/ ? "ok\n" : "not ok\n";
    print $1 eq 'dddd' ? "ok\n" : "not ok\n";
    print $2 eq 'eeeee' ? "ok\n" : "not ok\n";
}

print $1 eq 'c' ? "ok\n" : "not ok - $1\n";

# captures in list context
@x = $text =~ /((b|c)+)/;

print "$x[0] $x[1]" eq "bbccc c" ? "ok\n" : "not ok - $x[0] $x[1]\n";

# global match in list context
@x = $text =~ /b+|d+|f+/g;

print "$x[0] $x[1] $x[2]" eq "bb dddd ffffff" ? "ok\n" : "not ok - $x[0] $x[1] $x[2]\n";

# global match in scalar context
print $text =~ /b+|d+|f+/g ? "ok\n" : "not ok\n";
print pos $text == 3 ? "ok\n" : "not ok\n";

print $text =~ /b+|d+|f+/g ? "ok\n" : "not ok\n";
print pos $text == 10 ? "ok\n" : "not ok\n";

print $text =~ /b+|d+|f+/g ? "ok\n" : "not ok\n";
print pos $text == 21 ? "ok\n" : "not ok\n";

print $text =~ /b+|d+|f+/gc ? "not ok\n" : "ok\n";
print pos $text == 21 ? "ok\n" : "not ok\n";

print $text =~ /b+|d+|f+/g ? "not ok\n" : "ok\n";
print defined pos $text ? "not ok\n" : "ok\n";

# global match the empty string
++$x, "\n" while $text =~ /z*/g;
print $x == 22 ? "ok\n" : "not ok\n";
