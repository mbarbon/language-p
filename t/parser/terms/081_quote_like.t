#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 11;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
q<$e>;
EOP
root:
    class: Language::P::ParseTree::Constant
    value: $e
    type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
q "$e";
EOP
root:
    class: Language::P::ParseTree::Constant
    value: $e
    type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qq();
EOP
root:
    class: Language::P::ParseTree::Constant
    value: 
    type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qq(ab${e}cdefg);
EOP
root:
    class: Language::P::ParseTree::QuotedString
    components:
            class: Language::P::ParseTree::Constant
            value: ab
            type: string
            class: Language::P::ParseTree::Symbol
            name: e
            sigil: $
            class: Language::P::ParseTree::Constant
            value: cdefg
            type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qq(a(${e}(d)e\)f)g);
EOP
root:
    class: Language::P::ParseTree::QuotedString
    components:
            class: Language::P::ParseTree::Constant
            value: a(
            type: string
            class: Language::P::ParseTree::Symbol
            name: e
            sigil: $
            class: Language::P::ParseTree::Constant
            value: (d)e)f)g
            type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qq '$e';
EOP
root:
    class: Language::P::ParseTree::QuotedString
    components:
            class: Language::P::ParseTree::Symbol
            name: e
            sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qx($e);
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: backtick
    left:
        class: Language::P::ParseTree::QuotedString
        components:
                class: Language::P::ParseTree::Symbol
                name: e
                sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qx  # test
'$e';
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: backtick
    left:
        class: Language::P::ParseTree::Constant
        value: $e
        type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qx#$e#;
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: backtick
    left:
        class: Language::P::ParseTree::QuotedString
        components:
                class: Language::P::ParseTree::Symbol
                name: e
                sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qw!!;
EOP
root:
    class: Language::P::ParseTree::List
    expressions:
EOE

parse_and_diff( <<'EOP', <<'EOE' );
qw zaaa bbb
    eee fz;
EOP
root:
    class: Language::P::ParseTree::List
    expressions:
            class: Language::P::ParseTree::Constant
            value: aaa
            type: string
            class: Language::P::ParseTree::Constant
            value: bbb
            type: string
            class: Language::P::ParseTree::Constant
            value: eee
            type: string
            class: Language::P::ParseTree::Constant
            value: f
            type: string
EOE
