#!/usr/bin/perl -w

print "1..7\n";

# basic formatting
$v = sprintf( ' %%s ', 'abc' );
print $v eq ' %s ' ? "ok\n" : "not ok - <$v>\n";

$v = sprintf( ' %s ', 'abc' );
print $v eq ' abc ' ? "ok\n" : "not ok - <$v>\n";

$v = sprintf( ' %d ', 123 );
print $v eq ' 123 ' ? "ok\n" : "not ok - <$v>\n";

$v = sprintf( ' %% %s %d ', 'abc', 123 );
print $v eq ' % abc 123 ' ? "ok\n" : "not ok - <$v>\n";

# more formatting options
$v = sprintf( ' %03x ', 56 );
print $v eq ' 038 ' ? "ok\n" : "not ok - <$v>\n";

$v = sprintf( ' %010.3f ', 1.2 );
print $v eq ' 000001.200 ' ? "ok\n" : "not ok - <$v>\n";

$v = sprintf( ' %10.3f ', 1.2 );
print $v eq '      1.200 ' ? "ok\n" : "not ok - <$v>\n";
