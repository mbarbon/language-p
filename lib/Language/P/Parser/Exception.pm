package Language::P::Parser::Exception;

use strict;
use warnings;
use parent qw(Language::P::Exception);

sub full_message { $_[0]->format_message }

1;
