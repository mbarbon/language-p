package Language::P::Intermediate::LexicalState;

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_ro_accessors( qw(scope package hints warnings) );

1;
