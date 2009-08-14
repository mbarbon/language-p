package Language::P::Toy::Exception;

use strict;
use warnings;
use base qw(Language::P::Exception);

sub full_message { $_[0]->format_message }

1;
