package Language::P::Toy::Value::Regex;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Code);

__PACKAGE__->mk_ro_accessors( qw(regex_string) );

use Language::P::Constants qw(:all);

use constant
  { REGEXP_NO_MORE_MATCHES => -1,
    REGEXP_SCAN_ALL        => -2,
    };

sub type { 15 }

sub next_start {
    my( $self, $start ) = @_;

    return REGEXP_SCAN_ALL;
}

sub match {
    my( $self, $runtime, $string, $pos, $allow_zero_width ) = @_;
    my $start = !defined $pos || $pos < 0 ? 0 : $pos;

    # print "String: $string\n";

    my $rv;
    # make space for the values
    push @{$runtime->{_stack}}, 0, $string;
    foreach my $i ( $start .. length( $string ) ) {
        local $SIG{__WARN__} = sub { Carp::confess( @_ ) };
        $runtime->{_stack}[-2] = $i;
        # print "Start: $i\n";
        $self->call( $runtime, -2, CXT_VOID ); # -2 so we can blindly add 1
        $runtime->run;
        $rv = pop @{$runtime->{_stack}};

        next unless $rv->{matched};
        # disallow matching twice at the same position with a zero-length match
        if( defined $pos && $pos == $rv->{match_end} && !$allow_zero_width ) {
            $rv->{matched} = 0;
            next;
        }

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
