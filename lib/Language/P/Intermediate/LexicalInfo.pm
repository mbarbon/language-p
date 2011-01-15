package Language::P::Intermediate::LexicalInfo;

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_ro_accessors( qw(level name sigil symbol_name index
                                 outer_index in_pad from_main declaration) );

sub set_index { $_[0]->{index} = $_[1] }
sub set_declaration { $_[0]->{declaration} = $_[1] }
sub set_outer_index { $_[0]->{outer_index} = $_[1] }
sub set_from_main { $_[0]->{from_main} = $_[1] }

1;
