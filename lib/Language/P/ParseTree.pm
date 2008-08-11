package Language::P::ParseTree;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(NUM_INTEGER NUM_FLOAT NUM_HEXADECIMAL NUM_OCTAL NUM_BINARY

                    CXT_CALLER CXT_VOID CXT_SCALAR CXT_LIST CXT_LVALUE
                    CXT_VIVIFY CXT_CALL_MASK

                    PROTO_DEFAULT

                    FLAG_IMPLICITARGUMENTS FLAG_ERASEFRAME
                    );
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

use constant
  { NUM_INTEGER        => 1,
    NUM_FLOAT          => 2,
    NUM_HEXADECIMAL    => 4,
    NUM_OCTAL          => 8,
    NUM_BINARY         => 16,

    CXT_CALLER         => 1,
    CXT_VOID           => 2,
    CXT_SCALAR         => 4,
    CXT_LIST           => 8,
    CXT_LVALUE         => 16,
    CXT_VIVIFY         => 32,
    CXT_CALL_MASK      => 2|4|8,

    PROTO_DEFAULT      => [ -1, -1, '@' ],

    # function calls
    FLAG_IMPLICITARGUMENTS => 1,
    FLAG_ERASEFRAME        => 2,
    };

package Language::P::ParseTree::Node;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub is_bareword { 0 }
sub is_constant { 0 }
sub is_symbol { 0 }
sub is_compound { 0 }
sub can_implicit_return { 1 }
sub lvalue_context { Language::P::ParseTree::CXT_SCALAR }

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

sub is_constant { 1 }

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Bareword;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Constant);

sub type { 'string' }
sub is_bareword { 1 }

package Language::P::ParseTree::Number;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Constant);

our @FIELDS = qw(flags);

sub type { 'number' }

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

our @FIELDS = qw(function arguments context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub parsing_prototype { return Language::P::ParseTree::PROTO_DEFAULT }

package Language::P::ParseTree::SpecialFunctionCall;

use strict;
use warnings;
use base qw(Language::P::ParseTree::FunctionCall);

our @FIELDS = qw(flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::MethodCall;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(invocant method arguments indirect context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Identifier;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name sigil context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_symbol { 1 }
sub lvalue_context {
    my( $self ) = @_;

    return $self->sigil eq '%' || $self->sigil eq '@' ?
               Language::P::ParseTree::CXT_LIST :
               Language::P::ParseTree::CXT_SCALAR;
}

package Language::P::ParseTree::Symbol;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Identifier);

package Language::P::ParseTree::LexicalSymbol;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Identifier);

__PACKAGE__->mk_ro_accessors( qw(slot) );

package Language::P::ParseTree::LexicalDeclaration;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Identifier);

our @FIELDS = qw(declaration_type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub symbol_name { return $_[0]->sigil . $_[0]->name }

package Language::P::ParseTree::Block;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(lines);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }

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

our @FIELDS = qw(op left right context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::UnOp;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op left context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Parentheses;

use strict;
use warnings;
use base qw(Language::P::ParseTree::UnOp);

sub op { '()' }
sub lvalue_context { Language::P::ParseTree::CXT_LIST }

package Language::P::ParseTree::Dereference;

use strict;
use warnings;
use base qw(Language::P::ParseTree::UnOp);

package Language::P::ParseTree::List;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expressions);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context { Language::P::ParseTree::CXT_LIST }

package Language::P::ParseTree::Slice;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(subscripted subscript type reference context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context { Language::P::ParseTree::CXT_LIST }

package Language::P::ParseTree::Subscript;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(subscripted subscript type reference context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Conditional;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(iftrues iffalse);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }

package Language::P::ParseTree::ConditionalBlock;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition block block_type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }

package Language::P::ParseTree::ConditionalLoop;

use strict;
use warnings;
use base qw(Language::P::ParseTree::ConditionalBlock);

sub can_implicit_return { 0 }
sub is_compound { 1 }

package Language::P::ParseTree::For;

use strict;
use warnings;
use base qw(Language::P::ParseTree::ConditionalLoop);

our @FIELDS = qw(initializer step);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }

package Language::P::ParseTree::Foreach;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expression block variable);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }
sub is_compound { 1 }

package Language::P::ParseTree::Ternary;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition iftrue iffalse context);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context {
    my( $self ) = @_;
    my $l = $self->iftrue->lvalue_context;
    my $r = $self->iffalse->lvalue_context;

    Carp::confess( "Assigning to both scalar and array" ) unless $r == $l;

    return $r;
}

package Language::P::ParseTree::Builtin;

use strict;
use warnings;
use base qw(Language::P::ParseTree::FunctionCall);

my %prototype_bi =
  ( print       => [ -1, -1, '!', '@' ],
    defined     => [  0,  1, '#' ],
    return      => [ -1, -1, '@' ],
    undef       => [  0,  1, '$' ],
    eval        => [  0,  1, '$' ],
    );

sub parsing_prototype { return $prototype_bi{$_[0]->function} }
sub can_implicit_return { return $_[0]->function eq 'return' ? 0 : 1 }

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
    abs         => [  0,  1, '$' ],
    wantarray   => [  0,  0 ],
    );

sub parsing_prototype { return $prototype_ov{$_[0]->function} }

package Language::P::ParseTree::Glob;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Overridable);

sub function { 'glob' }

package Language::P::ParseTree::InterpolatedPattern;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op string flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Pattern;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op components flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Substitution;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(pattern replacement);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXGroup;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(components capture);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXQuantifier;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(node min max greedy);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXAssertion;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXClass;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(elements);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXAlternation;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(left right);

__PACKAGE__->mk_ro_accessors( @FIELDS );

1;
