package Language::P::Parser::Lexicals;

use strict;
use warnings;
use parent qw(Language::P::Object);

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

sub add_name_our {
    my( $self, $sigil, $name, $full_name ) = @_;

    $self->add_lexical( Language::P::ParseTree::Symbol->new
                            ( { name        => $full_name,
                                sigil       => $sigil,
                                symbol_name => $sigil . "\0" . $name,
                                } ) );
}

sub add_lexical {
    my( $self, $lexical ) = @_;

    my $s = $self->names->{$lexical->symbol_name} = $lexical;
}

sub all_visible_lexicals {
    my( $self ) = @_;
    my( %seen, %lex, %glob );

    for( my $lexicals = $self; $lexicals; $lexicals = $lexicals->outer ) {
        while( my( $k, $v ) = each %{$lexicals->{names}} ) {
            next if $seen{$k};
            $seen{$k} = 1;
            if( $v->isa( 'Language::P::ParseTree::Symbol' ) ) {
                $glob{$k} = $v->name;
            } else {
                $lex{$k} = $v;
            }
        }
    }

    return ( \%lex, \%glob );
}

1;
