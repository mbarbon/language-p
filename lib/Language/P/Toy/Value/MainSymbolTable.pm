package Language::P::Toy::Value::MainSymbolTable;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::SymbolTable);

use Language::P::Toy::Value::ActiveScalar;
use Language::P::Toy::Value::StringNumber;

sub is_main { 1 }

my %special_names =
  ( "\017"   => 1,
    );
our %sigils; *sigils = \%Language::P::Toy::Value::SymbolTable::sigils;

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    my $out = Language::P::Toy::Value::Handle->new( { handle => \*STDOUT } );
    $self->set_symbol( 'STDOUT', 'I', $out );

    my $interpreter = Language::P::Toy::Value::StringNumber->new( { string => $^X } );
    $self->set_symbol( "\030", '$', $interpreter );

    my $inc = Language::P::Toy::Value::Array->new;
    $inc->push_value( Language::P::Toy::Value::StringNumber->new( { string => '.' } ) );
    $self->set_symbol( 'INC', '@', $inc );

    return $self;
}

sub _tied_to_rt_variable {
    my( $name ) = @_;

    my $get = sub {
        return Language::P::Toy::Value::StringNumber->new
                   ( { string => $Language::P::Toy::Runtime::current
                                     ->{_variables}->{osname},
                       } );
    };

    return Language::P::Toy::Value::ActiveScalarCallbacks->new
               ( { get_callback => $get,
                   } )
}

sub get_symbol {
    my( $self, $name, $sigil, $create ) = @_;
    my( $symbol, $created ) = $self->SUPER::_get_symbol( $name, '*', $create );

    return $symbol unless $symbol;
    if( !$created ) {
        return $symbol if $sigil eq '*';
        return $create ? $symbol->get_or_create_slot( $sigils{$sigil}[0] ) :
                         $symbol->get_slot( $sigils{$sigil}[0] );
    }
    if( $special_names{$name} ) {
        if( $name eq "\017" ) {
            $symbol->set_slot( 'scalar', _tied_to_rt_variable( 'osname' ) );
        }
    }

    return $symbol if $sigil eq '*';
    return $create ? $symbol->get_or_create_slot( $sigils{$sigil}[0] ) :
                     $symbol->get_slot( $sigils{$sigil}[0] );
}

1;
