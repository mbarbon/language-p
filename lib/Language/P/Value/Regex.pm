package Language::P::Value::Regex;

use strict;
use warnings;
use base qw(Language::P::Value::Code);

use constant
  { REGEXP_NO_MORE_MATCHES => -1,
    REGEXP_SCAN_ALL        => -2,
    };

sub next_start {
    my( $self, $start ) = @_;

    return REGEXP_SCAN_ALL;
}

sub match {
    my( $self, $runtime, $string ) = @_;

    # print "String: $string\n";

    my $rv;
    # make space for the values
    push @{$runtime->{_stack}}, 0, $string;
    foreach my $i ( 0 .. length( $string ) ) {
        local $SIG{__WARN__} = sub { Carp::confess @_ };
        $runtime->{_stack}[-2] = $i;
        # print "Start: $i\n";
        $self->call( $runtime, -2 ); # -2 so we can blindly add 1
        $runtime->run;
        $rv = pop @{$runtime->{_stack}};

        next unless $rv->{matched};

        $rv->{match_start} = $i;
        # print 'Matched: "' . substr( $string, $i, $rv->{match_end} - $i )
        #                    . "\"\n";
        last;
    }
    # clean stack
    pop @{$runtime->{_stack}};
    pop @{$runtime->{_stack}};

#     if( !$rv->{matched} ) {
#         print "No match\n";
#     }

    return $rv;
}

1;
