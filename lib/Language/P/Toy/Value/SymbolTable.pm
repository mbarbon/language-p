package Language::P::Toy::Value::SymbolTable;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Hash);

__PACKAGE__->mk_ro_accessors( qw(name) );

use Language::P::Constants qw(:all);
use Language::P::Toy::Value::Typeglob;

sub type { 7 }
sub is_main { 0 }
# TODO inheritance
sub has_overloading { $_[0]->{overload} ? 1 : 0 }
sub overload_table { $_[0]->{overload} }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    return $self;
}

sub get_package {
    my( $self, $runtime, $package, $create ) = @_;
    my( $pack ) = $self->get_symbol( $runtime, $package . '::', VALUE_STASH, $create );

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
  ( VALUE_SCALAR()  => [ 'scalar',     'Language::P::Toy::Value::Scalar' ],
    VALUE_ARRAY()   => [ 'array',      'Language::P::Toy::Value::Array' ],
    VALUE_HASH()    => [ 'hash',       'Language::P::Toy::Value::Hash' ],
    VALUE_SUB()     => [ 'subroutine', 'Language::P::Toy::Value::Subroutine' ],
    VALUE_GLOB()    => [ undef,        'Language::P::Toy::Value::Typeglob' ],
    VALUE_HANDLE()  => [ 'io',         'Language::P::Toy::Value::Handle' ],
    VALUE_STASH()   => [ 'hash',       'language::P::Toy::Value::SymbolTable' ],
    );

sub get_symbol {
    my( $self, $runtime, $name, $sigil, $create ) = @_;
    my( $symbol, $created ) = $self->_get_glob( $runtime, $name, $create );

    return $symbol unless $symbol;

    $self->_apply_magic( $runtime, $name, $symbol ) if $created;

    return $symbol if $sigil == VALUE_GLOB;

    my $value = $symbol->get_slot( $runtime, $sigils{$sigil}[0] );
    return $value if $value || !$create;

    if( $sigil == VALUE_STASH ) {
        $value = Language::P::Toy::Value::SymbolTable->new
                     ( $runtime, { name => substr $name, 0, -2 } );
        $symbol->set_slot( $runtime, 'hash', $value );

        return $value;
    }

    return $symbol->get_or_create_slot( $runtime, $sigils{$sigil}[0] );
}

sub _get_glob {
    my( $self, $runtime, $name, $create ) = @_;
    my( @packages ) = split /(?<=::)/, $name;
    my $name_prefix = '';
    if( $self->is_main ) {
        shift @packages if $packages[0] eq 'main::';
        $name_prefix = 'main::' if @packages == 1;
    }

    my $index = 0;
    my $current = $self;
    foreach my $package ( @packages ) {
        my $glob = $current->{hash}{$package};
        return ( undef, 0 ) if !$glob && !$create;
        my $created = 0;
        if( !$glob ) {
            $created = 1;
            $glob = $current->{hash}{$package} =
                Language::P::Toy::Value::Typeglob->new
                    ( $runtime, { name => $name_prefix . $name } );
        }

        if( $index == $#packages ) {
            return ( $glob, $created );
        } else {
            $current = $glob->get_slot( $runtime, 'hash' );
            if( !$current ) {
                return ( undef, 0 ) unless $create;
                my $pack_name = join '', @packages[0 .. $index];
                $current = Language::P::Toy::Value::SymbolTable->new
                               ( $runtime, { name => substr $pack_name, 0, -2 } );
                $glob->set_slot( $runtime, 'hash', $current );
            }

            return $current if $index == $#packages;
        }

        ++$index;
    }
}

sub set_symbol {
    my( $self, $runtime, $name, $sigil, $value ) = @_;
    my $glob = $self->get_symbol( $runtime, $name, VALUE_GLOB, 1 );

    $glob->set_slot( $runtime, $sigils{$sigil}[0], $value );

    return;
}

sub find_method {
    my( $self, $runtime, $name, $is_super ) = @_;

    my $name_glob = $self->{hash}{$name};
    if( $name_glob && !$is_super ) {
        my $sub = $name_glob->body->subroutine;

        return $sub if $sub;
    }

    my $isa_glob = $self->{hash}{ISA};
    my $isa_array = $isa_glob ? $isa_glob->body->array : undef;
    if( !$isa_array || $isa_array->get_count( $runtime ) == 0 ) {
        my $universal_stash = $runtime->symbol_table->get_package( $runtime, 'UNIVERSAL' );

        return $universal_stash->find_method( $runtime, $name, 0 )
            if $self != $universal_stash;
        return undef;
    }

    for( my $i = 0; $i < $isa_array->get_count( $runtime ); ++$i ) {
        my $base = $isa_array->get_item( $runtime, $i )->as_string( $runtime );
        my $base_stash = $runtime->symbol_table->get_package( $runtime, $base );
        next unless $base_stash;
        my $sub = $base_stash->find_method( $runtime, $name, 0 );

        return $sub if $sub;
    }

    return undef;
}

sub derived_from {
    my( $self, $runtime, $base ) = @_;

    return 0 unless $base;
    return 1 if $self == $base;

    my $isa_glob = $self->{hash}{ISA};
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
