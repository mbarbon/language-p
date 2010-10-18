package overload;

sub import {
    shift;
    my $package = (caller)[0];
    return unless @_;

    Internals::add_overload( $package, \@_ );
}

1;
