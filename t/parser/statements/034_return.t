#!/usr/bin/perl -w

use t::lib::TestParser tests => 7;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    return @y;
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: y
        sigil: VALUE_ARRAY
    context: CXT_CALLER
    function: OP_RETURN
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    @x;
    @y;
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Symbol
    context: CXT_VOID
    name: x
    sigil: VALUE_ARRAY
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: y
        sigil: VALUE_ARRAY
    context: CXT_CALLER
    function: OP_RETURN
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    if( $a ) {
        @y;
    }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Conditional
    iffalse: ~
    iftrues:
      - !parsetree:ConditionalBlock
        block: !parsetree:Block
          lines:
            - !parsetree:Builtin
              arguments:
                - !parsetree:Symbol
                  context: CXT_CALLER
                  name: y
                  sigil: VALUE_ARRAY
              context: CXT_CALLER
              function: OP_RETURN
        block_type: if
        condition: !parsetree:Symbol
          context: CXT_SCALAR
          name: a
          sigil: VALUE_SCALAR
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    while( $a ) {
        @y;
    }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:ConditionalLoop
    block: !parsetree:Block
      lines:
        - !parsetree:Symbol
          context: CXT_VOID
          name: y
          sigil: VALUE_ARRAY
    block_type: while
    condition: !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
    continue: ~
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    1;
    {
        2;
        3;
    }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:BareBlock
    continue: ~
    lines:
      - !parsetree:Constant
        context: CXT_VOID
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
      - !parsetree:Builtin
        arguments:
          - !parsetree:Constant
            context: CXT_CALLER
            flags: CONST_NUMBER|NUM_INTEGER
            value: 3
        context: CXT_CALLER
        function: OP_RETURN
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    1;
    do {
        2;
        3;
    }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Builtin
    arguments:
      - !parsetree:DoBlock
        context: CXT_CALLER
        lines:
          - !parsetree:Constant
            context: CXT_VOID
            flags: CONST_NUMBER|NUM_INTEGER
            value: 2
          - !parsetree:Constant
            context: CXT_CALLER
            flags: CONST_NUMBER|NUM_INTEGER
            value: 3
    context: CXT_CALLER
    function: OP_RETURN
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    1;
    for( 1; 2; 3 ) {
        4;
        5;
    }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:For
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 4
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 5
    block_type: for
    condition: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
    continue: ~
    initializer: !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    step: !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
name: x
prototype: ~
EOE
