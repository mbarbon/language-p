package Language::P::Toy::Value::MainSymbolTable;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::SymbolTable);

use Config;

use Language::P::Toy::Value::ActiveScalar;
use Language::P::Toy::Value::StringNumber;

sub is_main { 1 }

my %special_names =
  ( # H
    "\010"             => 1,
    # O
    "\017"             => 1,
    # W
    "\027ARNING_BITS"  => 1,
    );
our %sigils; *sigils = \%Language::P::Toy::Value::SymbolTable::sigils;

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    my $irs = Language::P::Toy::Value::Scalar->new_string( $runtime, "\n" );
    $self->set_symbol( $runtime, '/', '$', $irs );

    my $ais = Language::P::Toy::Value::Scalar->new_string( $runtime, " " );
    $self->set_symbol( $runtime, '"', '$', $ais );

    my $out = Language::P::Toy::Value::Handle->new( $runtime, { handle => \*STDOUT } );
    $self->set_symbol( $runtime, 'STDOUT', 'I', $out );

    my $err = Language::P::Toy::Value::Handle->new( $runtime, { handle => \*STDERR } );
    $self->set_symbol( $runtime, 'STDERR', 'I', $err );

    my $interpreter = Language::P::Toy::Value::Scalar->new_string( $runtime, $^X );
    $self->set_symbol( $runtime, "\030", '$', $interpreter );

    # TODO make readonly
    my $version = Language::P::Toy::Value::Scalar->new_float( $runtime, $] );
    $self->set_symbol( $runtime, ']', '$', $version );

    my $inc = Language::P::Toy::Value::Array->new( $runtime );
    $inc->push_value( $runtime, Language::P::Toy::Value::Scalar->new_string( $runtime, $_ ) )
        foreach 'support/toy/lib', grep !m{/$Config{archname}$}, @INC;
    $self->set_symbol( $runtime, 'INC', '@', $inc );
    $self->set_symbol( $runtime, 'Internals::add_overload', '&',
                       $runtime->wrap_method( $runtime, 'add_overload' ) );
    $self->set_symbol( $runtime, 'UNIVERSAL::isa', '&',
                       $runtime->wrap_method( $runtime, 'derived_from' ) );

    return $self;
}

sub _tied_to_rt_variable {
    my( $runtime, $name ) = @_;

    my $get = sub {
        return Language::P::Toy::Value::StringNumber->new
                   ( $runtime,
                     { string => $runtime->{_variables}->{$name},
                       } );
    };

    return Language::P::Toy::Value::ActiveScalarCallbacks->new
               ( $runtime,
                 { get_callback => $get,
                   set_callback => sub { die "Readonly $name" },
                   } )
}

sub _tied_to_rt_methods {
    my( $runtime, $get_m, $set_m ) = @_;

    my $get = sub {
        return $runtime->$get_m;
    };

    my $set = sub {
        $runtime->$set_m( $_[2] );
    };

    return Language::P::Toy::Value::ActiveScalarCallbacks->new
               ( $runtime,
                 { get_callback => $get,
                   set_callback => $set,
                   } )
}

sub _apply_magic {
    my( $self, $runtime, $name, $symbol ) = @_;

    $self->SUPER::_apply_magic( $runtime, $name, $symbol );

    if( $special_names{$name} ) {
        if( $name eq "\017" ) {
            $symbol->set_slot( $runtime, 'scalar',
                               _tied_to_rt_variable( $runtime, 'osname' ) );
        } elsif( $name eq "\010" ) {
            $symbol->set_slot( $runtime, 'scalar',
                               _tied_to_rt_methods( $runtime, 'get_hints',
                                                    'set_hints' ) );
        } elsif( $name eq "\027ARNING_BITS" ) {
            $symbol->set_slot( $runtime, 'scalar',
                               _tied_to_rt_methods( $runtime, 'get_warnings',
                                                    'set_warnings' ) );
        }
    }
}

sub get_symbol {
    my( $self, $runtime, $name, $sigil, $create ) = @_;
    return $self if $name eq 'main::' && $sigil eq '::';

    return $self->SUPER::get_symbol( $runtime, $name, $sigil, $create );
}

1;
