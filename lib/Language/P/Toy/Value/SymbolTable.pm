package Language::P::Toy::Value::SymbolTable;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(symbols) );

use Language::P::Toy::Value::Typeglob;

sub type { 7 }
sub is_main { 0 }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{symbols} ||= {};

    return $self;
}

sub get_package {
    my( $self, $runtime, $package, $create ) = @_;

    return $self if $self->is_main && $package eq 'main';
    return $self->_get_symbol( $runtime, $package, '::', $create );
}

our %sigils =
  ( '$'  => [ 'scalar',     'Language::P::Toy::Value::Scalar' ],
    '@'  => [ 'array',      'Language::P::Toy::Value::Array' ],
    '%'  => [ 'hash',       'Language::P::Toy::Value::Hash' ],
    '&'  => [ 'subroutine', 'Language::P::Toy::Value::Subroutine' ],
    '*'  => [ undef,        'Language::P::Toy::Value::Typeglob' ],
    'I'  => [ 'io',         'Language::P::Toy::Value::Handle' ],
    'F'  => [ 'format',     'Language::P::Toy::Value::Format' ],
    '::' => [ undef,        'language::P::Toy::Value::SymbolTable' ],
    );

sub get_symbol {
    my( $self, $runtime, $name, $sigil, $create ) = @_;
    my( $symbol, $created ) = $self->_get_symbol( $runtime, $name, $sigil, $create );

    return $symbol;
}

sub _get_symbol {
    my( $self, $runtime, $name, $sigil, $create ) = @_;
    my( @packages ) = split /::/, $name;
    if( $self->is_main && ( $packages[0] eq '' || $packages[0] eq 'main' ) ) {
        shift @packages;
    }

    my $index = 0;
    my $current = $self;
    foreach my $package ( @packages ) {
        if( $index == $#packages && $sigil ne '::' ) {
            my $glob = $current->{symbols}{$package};
            my $created = 0;
            return ( undef, $created ) if !$glob && !$create;
            if( !$glob ) {
                $created = 1;
                $glob = $current->{symbols}{$package} =
                    Language::P::Toy::Value::Typeglob->new( $runtime );
            }
            return ( $glob, $created ) if $sigil eq '*';
            return ( $create ? $glob->get_or_create_slot( $runtime, $sigils{$sigil}[0] ) :
                               $glob->get_slot( $runtime, $sigils{$sigil}[0] ),
                     $created );
        } else {
            my $subpackage = $package . '::';
            if( !exists $current->{symbols}{$subpackage} ) {
                return ( undef, 0 ) unless $create;

                $current = $current->{symbols}{$subpackage} =
                  Language::P::Toy::Value::SymbolTable->new( $runtime );
            } else {
                $current = $current->{symbols}{$subpackage};
            }

            return $current if $index == $#packages;
        }

        ++$index;
    }
}

sub set_symbol {
    my( $self, $runtime, $name, $sigil, $value ) = @_;
    my $glob = $self->get_symbol( $runtime, $name, '*', 1 );

    $glob->set_slot( $runtime, $sigils{$sigil}[0], $value );

    return;
}

sub find_method {
    my( $self, $runtime, $name ) = @_;

    my $name_glob = $self->{symbols}{$name};
    if( $name_glob ) {
        my $sub = $name_glob->body->subroutine;

        return $sub if $sub;
    }

    my $isa_glob = $self->{symbols}{ISA};
    return unless $isa_glob;
    my $isa_array = $isa_glob->body->array;

    for( my $i = 0; $i < $isa_array->get_count( $runtime ); ++$i ) {
        my $base = $isa_array->get_item( $runtime, $i )->as_string( $runtime );
        my $base_stash = $runtime->symbol_table->get_package( $runtime, $base );
        next unless $base_stash;
        my $sub = $base_stash->find_method( $runtime, $name );

        return $sub if $sub;
    }

    return undef;
}

1;
