#!/usr/bin/perl -w

print "1..16\n";

$s = \1;
$a = [];
$h = {};
$g = \*a;
$c = \&foo;
$r = \\&foo;

( $sc, $ac, $hc, $gc, $cc, $rc ) = ( $s, $a, $h, $g, $c, $r );

%ms = ( $s => 'scalar',
        $a => 'array',
        $h => 'hash',
        $g => 'glob',
        $c => 'code',
        $r => 'ref' );

%mn = ( ( $s + 0 ) => 'scalar',
        ( $a + 0 ) => 'array',
        ( $h + 0 ) => 'hash',
        ( $g + 0 ) => 'glob',
        ( $c + 0 ) => 'code',
        ( $r + 0 ) => 'ref' );

print $ms{$sc} eq 'scalar' ? "ok\n" : "not ok - $sc => $ms{$sc}\n";
print $ms{$ac} eq 'array' ? "ok\n" : "not ok - $ac => $ms{$ac}\n";
print $ms{$hc} eq 'hash' ? "ok\n" : "not ok - $hc => $ms{$hc}\n";
print $ms{$gc} eq 'glob' ? "ok\n" : "not ok - $gc => $ms{$gc}\n";
print $ms{$cc} eq 'code' ? "ok\n" : "not ok - $cc => $ms{$cc}\n";
print $ms{$rc} eq 'ref' ? "ok\n" : "not ok - $rc => $ms{$rc}\n";

print $mn{$sc + 0} eq 'scalar' ? "ok\n" : "not ok - $sc => $mn{$sc}\n";
print $mn{$ac + 0} eq 'array' ? "ok\n" : "not ok - $ac => $mn{$ac}\n";
print $mn{$hc + 0} eq 'hash' ? "ok\n" : "not ok - $hc => $mn{$hc}\n";
print $mn{$gc + 0} eq 'glob' ? "ok\n" : "not ok - $gc => $mn{$gc}\n";
print $mn{$cc + 0} eq 'code' ? "ok\n" : "not ok - $cc => $mn{$cc}\n";
print $mn{$rc + 0} eq 'ref' ? "ok\n" : "not ok - $rc => $mn{$rc}\n";

$so = \1;
$ao = [];
$gs = \*a;
$cs = \&foo;

print exists $ms{$so} ? "not ok - $so\n" : "ok\n";
print exists $ms{$ao} ? "not ok - $ao\n" : "ok\n";
print $ms{$gs} eq 'glob' ? "ok\n" : "not ok - $gs => $ms{$gs}\n";
print $ms{$cs} eq 'code' ? "ok\n" : "not ok - $cs => $ms{$cs}\n";
