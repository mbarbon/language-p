package Language::P::ParseTree::DumpYAML;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

use YAML qw(Dump Bless);

my %dispatch =
  ( 'ARRAY'    => '_filter_array',
    'DEFAULT'  => '_filter_fields',
    );

sub method_map { \%dispatch }

sub _filter_array {
    my( $self, $array ) = @_;

    return [ map { ref( $_ ) ? $self->visit( $_ ) : $_ } @$array ];
}

sub _filter_fields {
    my( $self, $tree ) = @_;
    my @fields = $tree->fields;

    my $clone = {};

    foreach my $field ( @fields ) {
        my $v = $tree->$field;
        $clone->{$field} = ref( $v ) ? $self->visit( $v ) : $v;
    }

    foreach my $attr ( qw(context label) ) {
        if( $tree->has_attribute( $attr ) ) {
            $clone->{$attr} = $tree->get_attribute( $attr );
        }
    }

    ( my $tag = ref $tree ) =~ s/^.*::/parsetree:/;
    Bless( $clone )->tag( $tag );

    return $clone;
}

sub dump {
    my( $self, $tree, $clean ) = @_;

    if( $clean || 1 ) {
        my $clone = $self->visit( $tree );

        return Dump( $clone );
    } else {
        return Dump( $tree );
    }
}

1;
