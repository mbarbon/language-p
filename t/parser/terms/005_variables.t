#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 9;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: '@'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$#foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: $#
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
%foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: '%'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
*foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: '*'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$_
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: _
sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$#
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: '#'
sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$^E
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: "\x05"
sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${^F}
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: "\x06"
sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${^Foo}
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: "\x06oo"
sigil: $
EOE
