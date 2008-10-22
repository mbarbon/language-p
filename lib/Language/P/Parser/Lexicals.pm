package Language::P::Parser::Lexicals;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(outer names is_subroutine
                                 top_level) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{names} ||= {};

    return $self;
}

sub _find_name {
    my( $self, $name, $level ) = @_;

    return ( $level, $self->names->{$name} )
        if exists $self->names->{$name};
    return _find_name( $self->outer, $name,
                       $level + $self->is_subroutine ) if $self->outer;
    return ( 0, undef );
}

sub find_name {
    my( $self, $name ) = @_;

    return _find_name( $self, $name, 0 );
}

sub add_name {
    my( $self, $sigil, $name ) = @_;

    $self->add_lexical( Language::P::ParseTree::LexicalDeclaration->new
                            ( { name  => $name,
                                sigil => $sigil,
                                flags => 0,
                                } ) );
}

sub add_lexical {
    my( $self, $lexical ) = @_;

    my $s = $self->names->{$lexical->symbol_name} = $lexical;
}

1;
