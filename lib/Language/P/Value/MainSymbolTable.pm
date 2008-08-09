package Language::P::Value::MainSymbolTable;

use strict;
use warnings;
use base qw(Language::P::Value::SymbolTable);

use Language::P::Value::ActiveScalar;

sub is_main { 1 }

my %special_names =
  ( "\017"   => 1,
    );
our %sigils; *sigils = \%Language::P::Value::SymbolTable::sigils;

sub _tied_to_rt_variable {
    my( $name ) = @_;

    my $get = sub {
        return Language::P::Value::StringNumber->new
                   ( { string => $Language::P::Runtime::current
                                     ->{_variables}->{osname},
                       } );
    };

    return Language::P::Value::ActiveScalarCallbacks->new
               ( { get_callback => $get,
                   } )
}

sub get_symbol {
    my( $self, $name, $sigil, $create ) = @_;
    my( $symbol, $created ) = $self->SUPER::_get_symbol( $name, '*', $create );

    return $symbol if !$symbol || !$created;
    if( $special_names{$name} ) {
        if( $name eq "\017" ) {
            $symbol->set_slot( 'scalar', _tied_to_rt_variable( 'osname' ) );
        }
    }

    return $symbol if $sigil eq '*';
    return $symbol->get_slot( $sigils{$sigil}[0] );
}

1;
