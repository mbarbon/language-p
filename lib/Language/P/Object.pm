package Language::P::Object;

use strict;
use warnings;

# tiny replacement for Class::Accessor::Fast: C::A::F uses base, which
# uses eval STRING, and most of its replacement are either XS or use
# eval STRING as well

sub new {
    return bless { %{$_[1] || {}} }, ref $_[0] || $_[0];
}

sub mk_ro_accessors {
    no strict 'refs';

    my $package = shift;

    foreach my $method ( @_ ) {
        *{"${package}::${method}"} = sub {
            return $_[0]->{$method};
        };
    }
}

sub mk_accessors {
    no strict 'refs';

    my $package = shift;

    foreach my $method ( @_ ) {
        *{"${package}::${method}"} = sub {
            return $_[0]->{$method} = $_[1] if @_ == 2;
            return $_[0]->{$method};
        };
    }
}

1;
