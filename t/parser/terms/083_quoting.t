#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 6;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"x\Qfoo\Ey";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: x
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: foo
    context: CXT_SCALAR
    function: OP_QUOTEMETA
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: y
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\lfoo\E";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: foo
    context: CXT_SCALAR
    function: OP_LCFIRST
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\Lfoo\E";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: foo
    context: CXT_SCALAR
    function: OP_LC
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\ufoo\E";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: foo
    context: CXT_SCALAR
    function: OP_UCFIRST
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\Ufoo\E";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: foo
    context: CXT_SCALAR
    function: OP_UC
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\Uf\Qoo";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: f
      - !parsetree:Overridable
        arguments:
          - !parsetree:Constant
            context: CXT_SCALAR
            flags: CONST_STRING
            value: oo
        context: CXT_SCALAR
        function: OP_QUOTEMETA
    context: CXT_SCALAR
    function: OP_UC
context: CXT_VOID
EOE
