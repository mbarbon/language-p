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

sub is_bareword { 0 }

sub _fields {
    no strict 'refs';
    my @fields = @{$_[0] . '::FIELDS'};

    foreach my $base ( reverse @{$_[0] . '::ISA'} ) {
        unshift @fields, _fields( $base );
    }

    return @fields;
}

sub fields { _fields( ref( $_[0] ) ) }

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

sub bare { 0 }

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Bareword;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Constant);

sub type { 'string' }
sub bare { 1 }
sub is_bareword { 1 }

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

sub parsing_prototype { return [ -1, -1, '@' ] }

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

our @FIELDS = qw(name sigil);

__PACKAGE__->mk_ro_accessors( @FIELDS, qw(slot) );

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

our @FIELDS = qw(name lines);

__PACKAGE__->mk_ro_accessors( @FIELDS, qw(lexicals outer) );

package Language::P::ParseTree::SubroutineDeclaration;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name);

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

package Language::P::ParseTree::ConditionalBlock;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition block block_type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::ConditionalLoop;

use strict;
use warnings;
use base qw(Language::P::ParseTree::ConditionalBlock);

package Language::P::ParseTree::For;

use strict;
use warnings;
use base qw(Language::P::ParseTree::ConditionalLoop);

our @FIELDS = qw(initializer step);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Foreach;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expression block variable);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Ternary;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition iftrue iffalse);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Builtin;

use strict;
use warnings;
use base qw(Language::P::ParseTree::FunctionCall);

my %prototype_bi =
  ( print       => [ -1, -1, '!', '@' ],
    defined     => [ 1 ,  1, '$' ],
    return      => [ -1, -1, '@' ],
    );

sub parsing_prototype { return $prototype_bi{$_[0]->function} }

package Language::P::ParseTree::Print;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Builtin);

our @FIELDS = qw(filehandle);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Overridable;

use strict;
use warnings;
use base qw(Language::P::ParseTree::FunctionCall);

my %prototype_ov =
  ( unlink      => [ -1, -1, '@' ],
    die         => [ -1, -1, '@' ],
    open        => [  1, -1, '*', '$', '@' ],
    pipe        => [  2,  2, '*', '*' ],
    chdir       => [  0,  1, '$' ],
    rmdir       => [  0,  1, '$' ],
    readline    => [  0,  1, '$' ],
    glob        => [ -1, -1, '@' ],
    close       => [  0,  1, '*' ],
    binmode     => [  0,  2, '*', '$' ],
    );

sub parsing_prototype { return $prototype_ov{$_[0]->function} }

package Language::P::ParseTree::Glob;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Overridable);

sub function { 'glob' }

1;
