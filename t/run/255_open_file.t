#!/usr/bin/perl -w

print "1..6\n";

unlink 'hfjksdhjkds';

$ok = open $in, '<', 't/run/255_open_file.t';
print $ok ? "ok\n" : "not ok - open < t/run/255_open_fil.t\n";

$line = readline $in;
print $line eq "#!/usr/bin/perl -w\n" ? "ok\n" : "not ok - '$line'\n";
close $in;

$ok = open $in, '<', 'hfjksdhjkds';
print $ok ? "not ok - open < hfjksdhjkds\n" : "ok\n";

$ok = open $out, '>', 'hfjksdhjkds';
print $ok ? "ok\n" : "not ok - open > hfjksdhjkds\n";

print $out 'Some', ' ', 'text';
close $out;

$ok = open $in, '<', 'hfjksdhjkds';
print $ok ? "ok\n" : "not ok - open < hfjksdhjkds\n";

$line = readline $in;
print $line eq 'Some text' ? "ok\n" : "not ok - '$line'\n";
close $in;

unlink 'hfjksdhjkds';
