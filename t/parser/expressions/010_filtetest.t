#!/usr/bin/perl -w

use t::lib::TestParser tests => 30;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-f $foo
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISFILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-f FOO
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_FT_ISFILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-f _
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_FT_ISFILE
EOE

# effective
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-r
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_EREADABLE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-w
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_EWRITABLE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-x
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_EEXECUTABLE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-o
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_EOWNED
EOE

# real
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-R
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_RREADABLE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-W
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_RWRITABLE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-X
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_REXECUTABLE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-O
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ROWNED
EOE

# size
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-e
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_EXISTS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-z
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_EMPTY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-s
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_NONEMPTY
EOE

# type
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-f
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISFILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-d
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISDIR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-l
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISSYMLINK
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-p
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISPIPE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-S
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISSOCKET
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-b
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISBLOCKSPECIAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-c
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISCHARSPECIAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-t
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: STDIN
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_FT_ISTTY
EOE

# special bits
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-u
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_SETUID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-g
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_SETGID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-k
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_STICKY
EOE

# content
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-T
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISASCII
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-B
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ISBINARY
EOE

# times
parse_and_diff_yaml( <<'EOP', <<'EOE' );
-M
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_MTIME
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-A
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_ATIME
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-C
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_FT_CTIME
EOE
