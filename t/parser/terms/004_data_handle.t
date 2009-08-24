#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'
__DATA__
'

__DATA__
some
data
that
is skipped
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "\n__DATA__\n"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'
__END__
'

__END__
some
data
that
is skipped
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "\n__END__\n"
EOE
