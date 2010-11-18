#!/usr/bin/perl -w

print "1..24\n";

# ==
print "# ==\n";

$x = 1 == 1;
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 1 == 2;
print $x eq '' ? "ok\n" : "not ok\n";

# !=
print "# !=\n";

$x = 1 != 2;
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 1 != 1;
print $x eq '' ? "ok\n" : "not ok\n";

# <
print "# <\n";

$x = 1 < 2;
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 1 < 1;
print $x eq '' ? "ok\n" : "not ok\n";

# <=
print "# <=\n";

$x = 1 <= 1;
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 2 <= 1;
print $x eq '' ? "ok\n" : "not ok\n";

# >
print "# >\n";

$x = 2 > 1;
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 1 > 1;
print $x eq '' ? "ok\n" : "not ok\n";

# >=
print "# >=\n";

$x = 1 >= 1;
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 1 >= 2;
print $x eq '' ? "ok\n" : "not ok\n";

# eq
print "# eq\n";

$x = 'a' eq 'a';
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 'b' eq 'a';
print $x eq '' ? "ok\n" : "not ok\n";

# ne
print "# ne\n";

$x = 'b' ne 'a';
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 'b' ne 'b';
print $x eq '' ? "ok\n" : "not ok\n";

# lt
print "# lt\n";

$x = 'a' lt 'b';
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 'b' lt 'b';
print $x eq '' ? "ok\n" : "not ok\n";

# le
print "# le\n";

$x = 'a' le 'a';
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 'b' le 'a';
print $x eq '' ? "ok\n" : "not ok\n";

# gt
print "# gt\n";

$x = 'b' gt 'a';
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 'b' gt 'b';
print $x eq '' ? "ok\n" : "not ok\n";

# ge
print "# ge\n";

$x = 'b' ge 'b';
print $x eq '1' ? "ok\n" : "not ok\n";

$x = 'a' ge 'b';
print $x eq '' ? "ok\n" : "not ok\n";
