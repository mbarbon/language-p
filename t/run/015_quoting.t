#!/usr/bin/perl -w

print "1..3\n";

$q = quotemeta 'abc!^#';
print $q eq 'abc\\!\\^\\#' ? "ok\n" : "not ok - $q\n";

$q = '\Qabc!^#\E';
print $q eq '\Qabc!^#\E' ? "ok\n" : "not ok - $q\n";

$q = "\Qabc!^#\E";
print $q eq 'abc\\!\\^\\#' ? "ok\n" : "not ok - $q\n";
