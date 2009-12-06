#!/usr/bin/perl -w

print "1..16\n";

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
