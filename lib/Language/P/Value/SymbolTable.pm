package Language::P::Value::SymbolTable;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(symbols is_main) );

use Language::P::Value::Typeglob;

sub type { 7 }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{symbols} ||= {};
    $self->{is_main} ||= 0;

    return $self;
}

sub get_package {
    my( $self, $package ) = @_;

    return $self if $self->is_main && $package eq 'main';

    die 'Implement me';
}

my %sigils =
  ( '$'  => [ 'scalar',     'Language::P::Value::Scalar' ],
    '@'  => [ 'array',      'Language::P::Value::Array' ],
    '%'  => [ 'hash',       'Language::P::Value::Hash' ],
    '&'  => [ 'subroutine', 'Language::P::Value::Subroutine' ],
    '*'  => [ undef,        'Language::P::Value::Typeglob' ],
    'I'  => [ 'io',         'Language::P::Value::Handle' ],
    'F'  => [ 'format',     'Language::P::Value::Format' ],
    '::' => [ undef,        'language::P::Value::SymbolTable' ],
    );

sub get_symbol {
    my( $self, $name, $sigil, $create ) = @_;
    my( @packages ) = split /::/, $name;

    my $index = 0;
    my $current = $self;
    foreach my $package ( @packages ) {
        if( $index == $#packages ) {
            return $current if $sigil eq '::';
            my $glob = $current->{symbols}{$package};
            return undef if !$glob && !$create;
            if( !$glob ) {
                $glob = $current->{symbols}{$package} =
                    Language::P::Value::Typeglob->new;
            }
            return $glob if $sigil eq '*';
            return $glob->get_slot( $sigils{$sigil}[0] );
        } else {
            my $subpackage = $package . '::';
            if( !exists $current->{symbols}{$subpackage} ) {
                return undef unless $create;

                $current = $current->{symbols}{$subpackage} =
                  Language::P::Value::SymbolTable->new;
            } else {
                $current = $current->{symbols}{$subpackage};
            }
        }

        ++$index;
    }
}

sub set_symbol {
    my( $self, $name, $sigil, $value ) = @_;
    my $glob = $self->get_symbol( $name, '*', 1 );

    $glob->set_slot( $sigils{$sigil}[0], $value );

    return;
}

1;
