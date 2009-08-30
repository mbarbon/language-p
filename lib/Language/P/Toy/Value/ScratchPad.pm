package Language::P::Toy::Value::ScratchPad;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

use Language::P::ParseTree qw(VALUE_SCALAR VALUE_ARRAY VALUE_HASH);
use Language::P::Toy::Value::Undef;

__PACKAGE__->mk_ro_accessors( qw(outer names values clear) );

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{values} ||= [];
    $self->{names} ||= {};
    $self->{clear} ||= { scalar  => [],
                         array   => [],
                         hash    => [],
                         };

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
    foreach my $clear ( @{$new->{clear}{scalar}} ) {
        $values->[$clear] = Language::P::Toy::Value::Undef->new( $runtime );
    }
    foreach my $clear ( @{$new->{clear}{array}} ) {
        $values->[$clear] = Language::P::Toy::Value::Array->new( $runtime );
    }
    foreach my $clear ( @{$new->{clear}{hash}} ) {
        $values->[$clear] = Language::P::Toy::Value::Hash->new( $runtime );
    }
    foreach my $clear ( @{$new->{clear}{array}} ) {
        $values->[$clear] = Language::P::Toy::Value::Array->new;
    }
    foreach my $clear ( @{$new->{clear}{hash}} ) {
        $values->[$clear] = Language::P::Toy::Value::Hash->new;
    }

    return $new;
}

sub add_value_index {
    my( $self, $runtime, $lex_info, $index, $value ) = @_;

    # make repeated add a no-op
    return if defined $self->values->[$index];

    if( @_ == 5 ) {
        $self->values->[$index] = $value;
    } elsif( $lex_info->{sigil} == VALUE_SCALAR ) {
        $self->values->[$index] = Language::P::Toy::Value::Undef->new( $runtime );
    } elsif( $lex_info->{sigil} == VALUE_ARRAY ) {
        $self->values->[$index] = Language::P::Toy::Value::Array->new( $runtime );
    } elsif( $lex_info->{sigil} == VALUE_HASH ) {
        $self->values->[$index] = Language::P::Toy::Value::Hash->new( $runtime );
    }
    $self->{names}{$lex_info->{symbol_name}} ||= [];
    push @{$self->{names}{$lex_info->{symbol_name}}}, $index;

    return $index;
}

sub is_empty { return $#{$_[0]->values} == -1 ? 1 : 0 }

1;
