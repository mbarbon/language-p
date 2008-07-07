package Language::P::ParseTree;

use strict;
use warnings;

sub import {
    my( $class, @args );
    my( $package ) = caller;

}

my %new_map;
our $AUTOLOAD;

sub AUTOLOAD {
    die unless $AUTOLOAD;
}

package Language::P::ParseTree::Node;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub fields {
    no strict 'refs';
    return @{ref( $_[0] ) . '::FIELDS'};
}

sub pretty_print {
    my( $self ) = @_;

    return "root:\n" . $self->_pretty_print( 1 );
}

sub _print_value {
    my( $self, $value, $level ) = @_;
    my( $prefix ) = ( ' ' x ( $level * 4 ) );

    if( !defined $value ) {
        return $prefix . "undef\n";
    } elsif( ref $value eq 'ARRAY' ) {
        my $str = '';

        foreach my $element ( @$value ) {
            $str .= _print_value( $self, $element, $level + 1 );
        }

        return $str;
    } elsif( ref $value eq 'HASH' ) {
        die;
    } elsif(    ref( $value )
             && ref( $value )->isa( 'Language::P::ParseTree::Node' ) ) {
        return $value->_pretty_print( $level + 1 );
    } else {
        return $prefix . $value . "\n";
    }
}

sub _pretty_print {
    my( $self, $level ) = @_;
    my( $str, $prefix ) = ( '', ' ' x ( $level * 4 ) );

    $str .= $prefix . 'class: ' . ref( $self ) . "\n";
    foreach my $field ( $self->fields ) {
        my $value = $self->$field;

        if(    ref( $value )
            && (    ref $value eq 'ARRAY'
                 || ref $value eq 'HASH'
                 || ref( $value )->isa( 'Language::P::ParseTree::Node' )
                 ) ) {
            $str .= $prefix . $field . ":\n";
            $str .= _print_value( $self, $value, $level );
        } else {
            $str .= $prefix . $field . ": " . _print_value( $self, $value, 0 );
        }
    }

    return $str;
}

package Language::P::ParseTree::Constant;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(value type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::QuotedString;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(components);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::FunctionCall;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(function arguments);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::MethodCall;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(invocant method arguments indirect);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Symbol;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name sigil);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::LexicalSymbol;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name sigil slot);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::LexicalDeclaration;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name sigil declaration_type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub symbol_name { return $_[0]->sigil . $_[0]->name }

package Language::P::ParseTree::Block;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(lines);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Subroutine;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name lexicals outer lines);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::BinOp;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op left right);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::UnOp;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op left);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::List;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expressions);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Slice;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(subscripted subscript type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Subscript;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(subscripted subscript type reference);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Conditional;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(iftrues iffalse);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Ternary;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition iftrue iffalse);

__PACKAGE__->mk_ro_accessors( @FIELDS );

1;
