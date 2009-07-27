package Language::P::Toy::Value::ScratchPad;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

use Language::P::Toy::Value::Undef;

__PACKAGE__->mk_ro_accessors( qw(outer names values clear) );

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{values} ||= [];
    $self->{names} ||= {};
    $self->{clear} ||= [];

    return $self;
}

sub new_scope {
    my( $self, $runtime, $outer_scope ) = @_;

    my $new = ref( $self )->new( $runtime,
                                 { outer  => $outer_scope,
                                   values => [ @{$self->values} ],
                                   clear  => $self->clear,
                                   } );
    my $values = $new->values;
    foreach my $clear ( @{$new->{clear}} ) {
        # FIXME lexical initialization
        $values->[$clear] = Language::P::Toy::Value::Undef->new( $runtime );
    }

    return $new;
}

sub add_value {
    my( $self, $runtime, $lexical, $value ) = @_;

    # FIXME lexical initialization
    push @{$self->values}, @_ > 3 ? $value : Language::P::Toy::Value::Undef->new( $runtime );
    $self->{names}{$lexical->symbol_name} ||= [];
    push @{$self->{names}{$lexical->symbol_name}}, $#{$self->values};

    return $#{$self->values};
}

sub is_empty { return $#{$_[0]->values} == -1 ? 1 : 0 }

1;
