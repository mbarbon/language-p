package Language::P::ParseTree;

use strict;
use warnings;
use Exporter 'import';

our @OPERATIONS;
BEGIN {
    @OPERATIONS =
      ( qw(OP_POWER OP_MATCH OP_NOT_MATCH OP_MULTIPLY OP_DIVIDE OP_MODULUS
           OP_REPEAT OP_ADD OP_SUBTRACT OP_CONCATENATE OP_NUM_LT OP_NUM_GT
           OP_NUM_LE OP_NUM_GE OP_STR_LT OP_STR_GT OP_STR_LE OP_STR_GE
           OP_NUM_EQ OP_NUM_NE OP_NUM_CMP OP_STR_EQ OP_STR_NE OP_STR_CMP
           OP_LOG_AND OP_LOG_OR OP_DOT_DOT OP_DOT_DOT_DOT OP_ASSIGN
           OP_ADD_ASSIGN OP_SUBTRACT_ASSIGN OP_MULTIPLY_ASSIGN
           OP_DIVIDE_ASSIGN OP_LOG_AND OP_LOG_OR OP_LOG_XOR OP_PLUS
           OP_MINUS OP_LOG_NOT OP_REFERENCE OP_LOG_NOT OP_PARENTHESES
           OP_BIT_AND OP_BIT_OR OP_BIT_XOR
           OP_QL_S OP_QL_M OP_QL_TR OP_QL_QR OP_QL_QX OP_QL_LT OP_QL_QW
           OP_BACKTICK OP_LOCAL

           OP_FT_EREADABLE OP_FT_EWRITABLE OP_FT_EEXECUTABLE OP_FT_EOWNED
           OP_FT_RREADABLE OP_FT_RWRITABLE OP_FT_REXECUTABLE OP_FT_ROWNED
           OP_FT_EXISTS OP_FT_EMPTY OP_FT_NONEMPTY OP_FT_ISFILE
           OP_FT_ISDIR OP_FT_ISSYMLINK OP_FT_ISPIPE OP_FT_ISSOCKET
           OP_FT_ISBLOCKSPECIAL OP_FT_ISCHARSPECIAL OP_FT_ISTTY
           OP_FT_SETUID OP_FT_SETGID OP_FT_STICKY OP_FT_ISASCII
           OP_FT_ISBINARY OP_FT_MTIME OP_FT_ATIME OP_FT_CTIME
           ) );
}

our @EXPORT_OK =
  ( qw(NUM_INTEGER NUM_FLOAT NUM_HEXADECIMAL NUM_OCTAL NUM_BINARY
       STRING_BARE CONST_STRING CONST_NUMBER

       CXT_CALLER CXT_VOID CXT_SCALAR CXT_LIST CXT_LVALUE
       CXT_VIVIFY CXT_CALL_MASK

       PROTO_DEFAULT PROTO_SCALAR PROTO_ARRAY PROTO_HASH PROTO_SUB
       PROTO_GLOB PROTO_BACKSLASH PROTO_BLOCK PROTO_AMPER PROTO_ANY
       PROTO_INDIROBJ PROTO_FILEHANDLE PROTO_MAKE_GLOB

       FLAG_IMPLICITARGUMENTS FLAG_ERASEFRAME
       FLAG_RX_MULTI_LINE FLAG_RX_SINGLE_LINE FLAG_RX_CASE_INSENSITIVE
       FLAG_RX_FREE_FORMAT FLAG_RX_ONCE FLAG_RX_GLOBAL FLAG_RX_KEEP
       FLAG_RX_EVAL FLAG_RX_COMPLEMENT FLAG_RX_DELETE FLAG_RX_SQUEEZE

       VALUE_SCALAR VALUE_ARRAY VALUE_HASH VALUE_SUB VALUE_GLOB
       VALUE_ARRAY_LENGTH

       DECLARATION_MY DECLARATION_OUR DECLARATION_STATE
       DECLARATION_CLOSED_OVER
       ), @OPERATIONS );
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

use constant
  { # numeric/string constants
    CONST_STRING       => 1,
    CONST_NUMBER       => 2,

    STRING_BARE        => 4,

    NUM_INTEGER        => 8,
    NUM_FLOAT          => 16,
    NUM_HEXADECIMAL    => 32,
    NUM_OCTAL          => 64,
    NUM_BINARY         => 128,

    # context
    CXT_CALLER         => 1,
    CXT_VOID           => 2,
    CXT_SCALAR         => 4,
    CXT_LIST           => 8,
    CXT_LVALUE         => 16,
    CXT_VIVIFY         => 32,
    CXT_CALL_MASK      => 2|4|8,

    PROTO_SCALAR       => 1,
    PROTO_ARRAY        => 2,
    PROTO_HASH         => 4,
    PROTO_SUB          => 8,
    PROTO_GLOB         => 16,
    PROTO_ANY          => 1|2|4|8|16,
    PROTO_BACKSLASH    => 32,
    PROTO_BLOCK        => 64,
    PROTO_AMPER        => 128,
    PROTO_INDIROBJ     => 256,
    PROTO_FILEHANDLE   => 512,
    PROTO_MAKE_GLOB    => 1024|16,
    PROTO_DEFAULT      => [ -1, -1, 0, 2 ],

    # sigils, anonymous array/hash constructors, dereferences
    VALUE_SCALAR       => 1,
    VALUE_ARRAY        => 2,
    VALUE_HASH         => 3,
    VALUE_SUB          => 4,
    VALUE_GLOB         => 5,
    VALUE_ARRAY_LENGTH => 6,

    # function calls
    FLAG_IMPLICITARGUMENTS => 1,
    FLAG_ERASEFRAME        => 2,

    # regular expressions
    FLAG_RX_MULTI_LINE       => 1,
    FLAG_RX_SINGLE_LINE      => 2,
    FLAG_RX_CASE_INSENSITIVE => 4,
    FLAG_RX_FREE_FORMAT      => 8,
    FLAG_RX_ONCE             => 16,
    FLAG_RX_GLOBAL           => 32,
    FLAG_RX_KEEP             => 64,
    FLAG_RX_EVAL             => 128,
    FLAG_RX_COMPLEMENT       => 1,
    FLAG_RX_DELETE           => 2,
    FLAG_RX_SQUEEZE          => 4,

    # declarations
    DECLARATION_MY           => 1,
    DECLARATION_OUR          => 2,
    DECLARATION_STATE        => 4,
    DECLARATION_CLOSED_OVER  => 8,
    DECLARATION_TYPE_MASK    => 7,

    map { $OPERATIONS[$_] => $_ + 1 } 0 .. $#OPERATIONS,
    };

package Language::P::ParseTree::Node;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Scalar::Util ();

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->set_parent_for_all_childs;

    return $self;
}

sub is_bareword { 0 }
sub is_constant { 0 }
sub is_symbol { 0 }
sub is_compound { 0 }
sub can_implicit_return { 1 }
sub is_declaration { 0 }
sub lvalue_context { Language::P::ParseTree::CXT_SCALAR }
sub parent { $_[0]->{parent} }

sub set_parent {
    my( $self, $parent ) = @_;

    $_[0]->{parent} = $parent;
    Scalar::Util::weaken( $_[0]->{parent} );
}

sub _fields {
    no strict 'refs';
    my @fields = @{$_[0] . '::FIELDS'};

    foreach my $base ( reverse @{$_[0] . '::ISA'} ) {
        unshift @fields, _fields( $base );
    }

    return @fields;
}

sub fields { _fields( ref( $_[0] ) ) }

sub set_parent_for_all_childs {
    my( $self ) = @_;

    foreach my $field ( $self->fields ) {
        my $v = $self->$field;
        next unless $v && ref( $v );

        if( ref( $v ) eq 'ARRAY' ) {
            $_->set_parent( $self ) foreach @$v;
        } elsif( ref( $v ) eq 'HASH' ) {
            die "No hash-ish field yet";
        } else {
            # can only be a node
            $v->set_parent( $self );
        }
    }
}

sub has_attribute  { $_[0]->{attributes} && exists $_[0]->{attributes}->{$_[1]} }
sub get_attribute  { $_[0]->{attributes} && $_[0]->{attributes}->{$_[1]} }
sub set_attribute  { $_[0]->{attributes}->{$_[1]} = $_[2] }
sub get_attributes { $_[0]->{attributes} }

package Language::P::ParseTree::Package;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Label;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name statement);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Constant;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(value flags);

sub is_constant { 1 }
sub is_bareword { $_[0]->{flags} & Language::P::ParseTree::STRING_BARE }
sub is_string   { $_[0]->{flags} & Language::P::ParseTree::CONST_STRING }
sub is_number   { $_[0]->{flags} & Language::P::ParseTree::CONST_NUMBER }

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::QuotedString;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(components);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::ReferenceConstructor;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expression type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::FunctionCall;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(function arguments);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub parsing_prototype { return Language::P::ParseTree::PROTO_DEFAULT }
sub runtime_context   { return undef }

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

our @FIELDS = qw(invocant method arguments indirect);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Identifier;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name sigil);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_symbol { 1 }
sub lvalue_context {
    my( $self ) = @_;

    return    $self->sigil == Language::P::ParseTree::VALUE_HASH
           || $self->sigil == Language::P::ParseTree::VALUE_ARRAY ?
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

our @FIELDS = qw(level);

__PACKAGE__->mk_ro_accessors( @FIELDS, qw(declaration) );

sub sigil { $_[0]->declaration->sigil }
sub name { $_[0]->declaration->name }

package Language::P::ParseTree::LexicalDeclaration;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Identifier);

our @FIELDS = qw(flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub symbol_name { return $_[0]->sigil . "\0" . $_[0]->name }
sub declaration_type { $_[0]->{flags} & Language::P::ParseTree::DECLARATION_TYPE_MASK }
sub closed_over { $_[0]->{flags} & Language::P::ParseTree::DECLARATION_CLOSED_OVER }
sub set_closed_over { $_[0]->{flags} |= Language::P::ParseTree::DECLARATION_CLOSED_OVER }

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

our @FIELDS = qw(lines);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::NamedSubroutine;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Subroutine);

our @FIELDS = qw(name);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_declaration { 1 }

package Language::P::ParseTree::SubroutineDeclaration;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_declaration { 1 }

package Language::P::ParseTree::AnonymousSubroutine;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Subroutine);

sub name { undef }

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

package Language::P::ParseTree::Parentheses;

use strict;
use warnings;
use base qw(Language::P::ParseTree::UnOp);

sub op { Language::P::ParseTree::OP_PARENTHESES }
sub lvalue_context { Language::P::ParseTree::CXT_LIST }

package Language::P::ParseTree::Local;

use strict;
use warnings;
use base qw(Language::P::ParseTree::UnOp);

sub op { Language::P::ParseTree::OP_LOCAL }
sub lvalue_context { $_[0]->left->lvalue_context }

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

our @FIELDS = qw(subscripted subscript type reference);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context { Language::P::ParseTree::CXT_LIST }

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

our @FIELDS = qw(condition iftrue iffalse);

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
  ( print       => [ -1, -1, Language::P::ParseTree::PROTO_FILEHANDLE, Language::P::ParseTree::PROTO_ARRAY ],
    defined     => [  0,  1, Language::P::ParseTree::PROTO_AMPER, Language::P::ParseTree::PROTO_AMPER|Language::P::ParseTree::PROTO_ANY ],
    return      => [ -1, -1, 0, Language::P::ParseTree::PROTO_ARRAY ],
    undef       => [  0,  1, 0, Language::P::ParseTree::PROTO_ANY ],
    eval        => [  0,  1, Language::P::ParseTree::PROTO_BLOCK, Language::P::ParseTree::PROTO_ANY ],
    map         => [  2, -1, Language::P::ParseTree::PROTO_INDIROBJ, Language::P::ParseTree::PROTO_ARRAY ],
    map { $_ => [ 0, 1, 0, Language::P::ParseTree::PROTO_MAKE_GLOB ] }
        ( Language::P::ParseTree::OP_FT_EREADABLE,
          Language::P::ParseTree::OP_FT_EWRITABLE,
          Language::P::ParseTree::OP_FT_EEXECUTABLE,
          Language::P::ParseTree::OP_FT_EOWNED,
          Language::P::ParseTree::OP_FT_RREADABLE,
          Language::P::ParseTree::OP_FT_RWRITABLE,
          Language::P::ParseTree::OP_FT_REXECUTABLE,
          Language::P::ParseTree::OP_FT_ROWNED,
          Language::P::ParseTree::OP_FT_EXISTS,
          Language::P::ParseTree::OP_FT_EMPTY,
          Language::P::ParseTree::OP_FT_NONEMPTY,
          Language::P::ParseTree::OP_FT_ISFILE,
          Language::P::ParseTree::OP_FT_ISDIR,
          Language::P::ParseTree::OP_FT_ISSYMLINK,
          Language::P::ParseTree::OP_FT_ISPIPE,
          Language::P::ParseTree::OP_FT_ISSOCKET,
          Language::P::ParseTree::OP_FT_ISBLOCKSPECIAL,
          Language::P::ParseTree::OP_FT_ISCHARSPECIAL,
          Language::P::ParseTree::OP_FT_ISTTY,
          Language::P::ParseTree::OP_FT_SETUID,
          Language::P::ParseTree::OP_FT_SETGID,
          Language::P::ParseTree::OP_FT_STICKY,
          Language::P::ParseTree::OP_FT_ISASCII,
          Language::P::ParseTree::OP_FT_ISBINARY,
          Language::P::ParseTree::OP_FT_MTIME,
          Language::P::ParseTree::OP_FT_ATIME,
          Language::P::ParseTree::OP_FT_CTIME,
          )
    );

my %context_bi =
  ( defined     => [ Language::P::ParseTree::CXT_SCALAR ],
    return      => [ Language::P::ParseTree::CXT_CALLER ],
    );

sub parsing_prototype { return $prototype_bi{$_[0]->function} }
sub runtime_context { return $context_bi{$_[0]->function} }
sub can_implicit_return { return $_[0]->function eq 'return' ? 0 : 1 }

package Language::P::ParseTree::BuiltinIndirect;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Builtin);

our @FIELDS = qw(indirect);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Overridable;

use strict;
use warnings;
use base qw(Language::P::ParseTree::FunctionCall);

my %prototype_ov =
  ( unlink      => [ -1, -1, 0, Language::P::ParseTree::PROTO_ARRAY ],
    die         => [ -1, -1, 0, Language::P::ParseTree::PROTO_ARRAY ],
    open        => [  1, -1, 0, Language::P::ParseTree::PROTO_MAKE_GLOB, Language::P::ParseTree::PROTO_SCALAR, Language::P::ParseTree::PROTO_ARRAY ],
    pipe        => [  2,  2, 0, Language::P::ParseTree::PROTO_MAKE_GLOB, Language::P::ParseTree::PROTO_MAKE_GLOB ],
    chdir       => [  0,  1, 0, Language::P::ParseTree::PROTO_SCALAR ],
    rmdir       => [  0,  1, 0, Language::P::ParseTree::PROTO_SCALAR ],
    readline    => [  0,  1, 0, Language::P::ParseTree::PROTO_SCALAR ],
    glob        => [ -1, -1, 0, Language::P::ParseTree::PROTO_ARRAY ],
    close       => [  0,  1, 0, Language::P::ParseTree::PROTO_MAKE_GLOB ],
    binmode     => [  0,  2, 0, Language::P::ParseTree::PROTO_MAKE_GLOB, Language::P::ParseTree::PROTO_SCALAR ],
    abs         => [  0,  1, 0, Language::P::ParseTree::PROTO_SCALAR ],
    wantarray   => [  0,  0, 0 ],
    );

my %context_ov =
  (
    );

sub parsing_prototype { return $prototype_ov{$_[0]->function} }
sub runtime_context { return $context_ov{$_[0]->function} }

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

package Language::P::ParseTree::RXSpecialClass;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXRange;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(start end);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXAlternation;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(left right);

__PACKAGE__->mk_ro_accessors( @FIELDS );

1;
