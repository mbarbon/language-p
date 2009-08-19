package Language::P::ParseTree;

use strict;
use warnings;
use Exporter 'import';

use Language::P::Opcodes qw(:all);

our @EXPORT_OK =
  ( qw(NUM_INTEGER NUM_FLOAT NUM_HEXADECIMAL NUM_OCTAL NUM_BINARY
       STRING_BARE CONST_STRING CONST_NUMBER

       CXT_CALLER CXT_VOID CXT_SCALAR CXT_LIST CXT_LVALUE
       CXT_VIVIFY CXT_CALL_MASK

       PROTO_DEFAULT PROTO_SCALAR PROTO_ARRAY PROTO_HASH PROTO_SUB
       PROTO_GLOB PROTO_REFERENCE PROTO_BLOCK PROTO_AMPER PROTO_ANY
       PROTO_INDIROBJ PROTO_FILEHANDLE PROTO_MAKE_GLOB PROTO_MAKE_ARRAY
       PROTO_MAKE_HASH PROTO_DEFAULT_ARG

       FLAG_IMPLICITARGUMENTS FLAG_ERASEFRAME
       FLAG_RX_MULTI_LINE FLAG_RX_SINGLE_LINE FLAG_RX_CASE_INSENSITIVE
       FLAG_RX_FREE_FORMAT FLAG_RX_ONCE FLAG_RX_GLOBAL FLAG_RX_KEEP
       FLAG_RX_EVAL FLAG_RX_COMPLEMENT FLAG_RX_DELETE FLAG_RX_SQUEEZE

       VALUE_SCALAR VALUE_ARRAY VALUE_HASH VALUE_SUB VALUE_GLOB VALUE_HANDLE
       VALUE_ARRAY_LENGTH

       DECLARATION_MY DECLARATION_OUR DECLARATION_STATE
       DECLARATION_CLOSED_OVER

       CHANGED_HINTS CHANGED_WARNINGS CHANGED_PACKAGE CHANGED_ALL
       %KEYWORD_TO_OP), @OPERATIONS );
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
    PROTO_REFERENCE    => 32,
    PROTO_BLOCK        => 64,
    PROTO_AMPER        => 128,
    PROTO_INDIROBJ     => 256,
    PROTO_FILEHANDLE   => 512,
    PROTO_MAKE_ARRAY   => 1024|2,
    PROTO_MAKE_HASH    => 1024|4,
    PROTO_MAKE_GLOB    => 1024|16,
    PROTO_DEFAULT_ARG  => 2048,
    PROTO_DEFAULT      => [ -1, -1, 0, 2 ],

    # sigils, anonymous array/hash constructors, dereferences
    VALUE_SCALAR       => 1,
    VALUE_ARRAY        => 2,
    VALUE_HASH         => 3,
    VALUE_SUB          => 4,
    VALUE_GLOB         => 5,
    VALUE_ARRAY_LENGTH => 6,
    VALUE_HANDLE       => 7,

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

    # lexical state
    CHANGED_HINTS      => 1,
    CHANGED_WARNINGS   => 2,
    CHANGED_PACKAGE    => 4,
    CHANGED_ALL        => 7,
    };

our %PROTOTYPE =
  ( OP_PRINT()       => [  0, -1, PROTO_FILEHANDLE|PROTO_DEFAULT_ARG, PROTO_ARRAY ],
    OP_DEFINED()     => [  1,  1, PROTO_AMPER|PROTO_DEFAULT_ARG, PROTO_AMPER|PROTO_ANY ],
    OP_RETURN()      => [  0, -1, 0, PROTO_ARRAY ],
    OP_UNDEF()       => [  0,  1, 0, PROTO_ANY ],
    OP_EVAL()        => [  1,  1, PROTO_BLOCK|PROTO_DEFAULT_ARG, PROTO_ANY ],
    OP_DO_FILE()     => [  1,  1, 0, PROTO_ANY ],
    OP_REQUIRE_FILE()=> [  1,  1, 0, PROTO_ANY ],
    OP_MAP()         => [  2, -1, PROTO_INDIROBJ, PROTO_ARRAY ],
    ( map { $_ => [ 1, 1, PROTO_DEFAULT_ARG, PROTO_MAKE_GLOB ] }
          ( OP_FT_EREADABLE,
            OP_FT_EWRITABLE,
            OP_FT_EEXECUTABLE,
            OP_FT_EOWNED,
            OP_FT_RREADABLE,
            OP_FT_RWRITABLE,
            OP_FT_REXECUTABLE,
            OP_FT_ROWNED,
            OP_FT_EXISTS,
            OP_FT_EMPTY,
            OP_FT_NONEMPTY,
            OP_FT_ISFILE,
            OP_FT_ISDIR,
            OP_FT_ISSYMLINK,
            OP_FT_ISPIPE,
            OP_FT_ISSOCKET,
            OP_FT_ISBLOCKSPECIAL,
            OP_FT_ISCHARSPECIAL,
            OP_FT_ISTTY,
            OP_FT_SETUID,
            OP_FT_SETGID,
            OP_FT_STICKY,
            OP_FT_ISASCII,
            OP_FT_ISBINARY,
            OP_FT_MTIME,
            OP_FT_ATIME,
            OP_FT_CTIME,
            ) ),
    OP_UNLINK()      => [  1, -1, PROTO_DEFAULT_ARG, PROTO_ARRAY ],
    OP_DIE()         => [  0, -1, 0, PROTO_ARRAY ],
    OP_OPEN()        => [  1, -1, 0, PROTO_MAKE_GLOB, PROTO_SCALAR, PROTO_ARRAY ],
    OP_PIPE()        => [  2,  2, 0, PROTO_MAKE_GLOB, PROTO_MAKE_GLOB ],
    OP_CHDIR()       => [  0,  1, 0, PROTO_SCALAR ],
    OP_RMDIR()       => [  1,  1, PROTO_DEFAULT_ARG, PROTO_SCALAR ],
    OP_READLINE()    => [  0,  1, 0, PROTO_MAKE_GLOB ],
    OP_GLOB()        => [  1, -1, PROTO_DEFAULT_ARG, PROTO_ARRAY ],
    OP_CLOSE()       => [  0,  1, 0, PROTO_MAKE_GLOB ],
    OP_BINMODE()     => [  0,  2, 0, PROTO_MAKE_GLOB, PROTO_SCALAR ],
    OP_ABS()         => [  1,  1, PROTO_DEFAULT_ARG, PROTO_SCALAR ],
    OP_CHR()         => [  1,  1, PROTO_DEFAULT_ARG, PROTO_SCALAR ],
    OP_WANTARRAY()   => [  0,  0, 0 ],
    OP_REFTYPE()     => [  1,  1, PROTO_DEFAULT_ARG, PROTO_SCALAR ],
    OP_BLESS()       => [  1,  2, 0, PROTO_SCALAR, PROTO_SCALAR ],
    OP_ARRAY_PUSH()  => [  1, -1, 0, PROTO_MAKE_ARRAY|PROTO_REFERENCE, PROTO_ARRAY ],
    OP_ARRAY_UNSHIFT()=>[  1, -1, 0, PROTO_MAKE_ARRAY|PROTO_REFERENCE, PROTO_ARRAY ],
    OP_ARRAY_POP()   => [  1,  1, PROTO_DEFAULT_ARG, PROTO_MAKE_ARRAY|PROTO_REFERENCE ],
    OP_ARRAY_SHIFT() => [  1,  1, PROTO_DEFAULT_ARG, PROTO_MAKE_ARRAY|PROTO_REFERENCE ],
    OP_EXISTS()      => [  1,  1, PROTO_AMPER, PROTO_AMPER ],
    );

our %CONTEXT =
  ( OP_DEFINED()     => [ CXT_SCALAR ],
    OP_RETURN()      => [ CXT_CALLER ],
    OP_DO_FILE()     => [ CXT_SCALAR ],
    OP_REQUIRE_FILE()=> [ CXT_SCALAR ],
    );

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
sub is_loop { 0 }
sub is_plain_function { 0 }
sub is_empty { 0 }
sub can_implicit_return { 1 }
sub is_declaration { 0 }
sub lvalue_context { Language::P::ParseTree::CXT_SCALAR }
sub parent { $_[0]->{parent} }
sub pos   { $_[0]->{pos} || $_[0]->{pos_s} }
sub pos_s { $_[0]->{pos_s} || $_[0]->{pos} }
sub pos_e { $_[0]->{pos_e} || $_[0]->{pos} }

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
sub get_attributes { $_[0]->{attributes} }
sub set_attribute  {
    my( $self, $name, $value, $weak ) = @_;

    $self->{attributes}->{$name} = $value;
    Scalar::Util::weaken( $self->{attributes}->{$name} ) if $weak;
}

package Language::P::ParseTree::LexicalState;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(changed package hints warnings);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Use;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(package version import is_no);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Empty;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

sub can_implicit_return { 0 }
sub is_empty { return !$_[0]->has_attribute( 'label' ) }

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

# quick and dirty mapping from parsing prototype to runtime context
sub _make_rtproto {
    my( $proto ) = @_;

    return [ map { $_ == Language::P::ParseTree::PROTO_SCALAR ?
                       Language::P::ParseTree::CXT_SCALAR :
                       Language::P::ParseTree::CXT_LIST }
                 @{$proto}[ 3 .. $#$proto ] ];
}

sub parsing_prototype { return $_[0]->{prototype} || Language::P::ParseTree::PROTO_DEFAULT }
sub runtime_context   { return $_[0]->{prototype} ? _make_rtproto( $_[0]->{prototype} ) : undef }
sub is_plain_function { 1 }

package Language::P::ParseTree::SpecialFunctionCall;

use strict;
use warnings;
use base qw(Language::P::ParseTree::FunctionCall);

our @FIELDS = qw(flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_plain_function { 0 }

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

sub symbol_name { return $_[0]->{symbol_name} }
sub set_closed_over {}
sub closed_over { 0 }

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

sub level { 0 }
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

package Language::P::ParseTree::DoBlock;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Block);

sub is_compound { 0 }

package Language::P::ParseTree::EvalBlock;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Block);

sub is_compound { 0 }

package Language::P::ParseTree::BareBlock;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Block);

our @FIELDS = qw(continue);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_loop { 1 }

package Language::P::ParseTree::Subroutine;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(lines);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub set_parent_for_all_childs {
    return unless $_[0]->lines;
    $_->set_parent( $_[0] ) foreach @{$_[0]->lines};
}

package Language::P::ParseTree::NamedSubroutine;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Subroutine);

our @FIELDS = qw(name prototype);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_declaration { 1 }

package Language::P::ParseTree::SubroutineDeclaration;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name prototype);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_declaration { 1 }
sub set_parent_for_all_childs { }

package Language::P::ParseTree::AnonymousSubroutine;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Subroutine);

sub name { undef }
sub prototype { undef }

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

package Language::P::ParseTree::Jump;

use strict;
use warnings;
use base qw(Language::P::ParseTree::UnOp);

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

our @FIELDS = qw(continue);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }
sub is_compound { 1 }
sub is_loop { 1 }

package Language::P::ParseTree::For;

use strict;
use warnings;
use base qw(Language::P::ParseTree::ConditionalLoop);

our @FIELDS = qw(initializer step);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }
sub is_loop { 1 }

package Language::P::ParseTree::Foreach;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expression block variable continue);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }
sub is_compound { 1 }
sub is_loop { 1 }

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

sub parsing_prototype { return $PROTOTYPE{$_[0]->function} }
sub runtime_context { return $CONTEXT{$_[0]->function} }
sub can_implicit_return { return $_[0]->function == Language::P::ParseTree::OP_RETURN ? 0 : 1 }
sub is_plain_function { 0 }

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

sub parsing_prototype { return $PROTOTYPE{$_[0]->function} }
sub runtime_context { return $CONTEXT{$_[0]->function} }
sub is_plain_function { 0 }

package Language::P::ParseTree::Glob;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Overridable);

sub function { Language::P::ParseTree::OP_GLOB }

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
