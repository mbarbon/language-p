package Language::P::Intermediate::Scope;

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_ro_accessors( qw(outer bytecode id flags context
                                 exception pos_s pos_e lexical_state) );

sub set_exception { $_[0]->{exception} = $_[1] }
sub set_flags { $_[0]->{flags} = $_[1] }

1;
