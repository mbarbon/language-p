package Language::P::Toy::Value::SymbolTable;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(symbols) );

use Language::P::Toy::Value::Typeglob;

sub type { 7 }
sub is_main { 0 }
# TODO inheritance
sub has_overloading { $_[0]->{overload} ? 1 : 0 }
sub overload_table { $_[0]->{overload} }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{symbols} ||= {};

    return $self;
}

sub get_package {
    my( $self, $runtime, $package, $create ) = @_;

    return $self if $self->is_main && $package eq 'main';
    my( $pack ) = $self->_get_symbol( $runtime, $package, '::', $create );

    return $pack;
}

sub _tied_to_regex_capture {
    my( $runtime, $index ) = @_;

    my $get = sub {
        my $re_state = $runtime->get_last_match;

        return Language::P::Toy::Value::Undef->new( $runtime )
            if !$re_state || @{$re_state->{captures}} < $index;
        return Language::P::Toy::Value::Scalar->new_string( $runtime, $re_state->{string_captures}[$index - 1] );
    };

    return Language::P::Toy::Value::ActiveScalarCallbacks->new
               ( $runtime,
                 { get_callback => $get,
                   set_callback => sub { die "Readonly capture"; },
                   } );
}

sub _apply_magic {
    my( $self, $runtime, $name, $symbol ) = @_;

     if( $name =~ /^([1-9][0-9]*)$/ ) {
             $symbol->set_slot( $runtime, 'scalar',
                                _tied_to_regex_capture( $runtime, $1 ) );
     }
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
    my( $symbol, $created ) = $self->_get_symbol( $runtime, $name, '*', $create );

    return $symbol unless $symbol;
    if( !$created ) {
        return $symbol if $sigil eq '*';
        return $create ? $symbol->get_or_create_slot( $runtime, $sigils{$sigil}[0] ) :
                         $symbol->get_slot( $runtime, $sigils{$sigil}[0] );
    }
    $self->_apply_magic( $runtime, $name, $symbol );

    return $symbol if $sigil eq '*';
    return $create ? $symbol->get_or_create_slot( $runtime, $sigils{$sigil}[0] ) :
                     $symbol->get_slot( $runtime, $sigils{$sigil}[0] );
}

sub _get_symbol {
    my( $self, $runtime, $name, $sigil, $create ) = @_;
    my( @packages ) = split /::/, $name;
    my $name_prefix = '';
    if( $self->is_main ) {
        shift @packages if $packages[0] eq '' || $packages[0] eq 'main';
        $name_prefix = 'main::' if @packages == 1;
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
                    Language::P::Toy::Value::Typeglob->new
                        ( $runtime, { name => $name_prefix . $name } );
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
    unless( $isa_glob ) {
        my $universal_stash = $runtime->symbol_table->get_package( $runtime, 'UNIVERSAL' );

        return $universal_stash->find_method( $runtime, $name )
            if $self != $universal_stash;
        return undef;
    }
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

sub derived_from {
    my( $self, $runtime, $base ) = @_;

    return 0 unless $base;
    return 1 if $self == $base;

    my $isa_glob = $self->{symbols}{ISA};
    unless( $isa_glob ) {
        my $universal_stash = $runtime->symbol_table->get_package( $runtime, 'UNIVERSAL' );

        return $universal_stash == $base ? 1 : 0;
    }
    my $isa_array = $isa_glob->body->array;

    for( my $i = 0; $i < $isa_array->get_count( $runtime ); ++$i ) {
        my $base_name = $isa_array->get_item( $runtime, $i )->as_string( $runtime );
        my $base_stash = $runtime->symbol_table->get_package( $runtime, $base_name, 0 );
        next unless $base_stash;

        return 1 if $base_stash == $base;
        return 1 if $base_stash->derived_from( $runtime, $base );
    }

    return 0;
}

1;
