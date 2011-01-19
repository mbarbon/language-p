package Language::P::ParseTree;

use strict;
use warnings;

use Language::P::Constants qw(:all);
use Language::P::Opcodes qw(:all);

package Language::P::ParseTree::Node;

use strict;
use warnings;
use parent qw(Language::P::Object);

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
sub is_pattern { 0 }
sub can_implicit_return { 1 }
sub always_void { 0 }
sub is_declaration { 0 }
sub lvalue_context { Language::P::Constants::CXT_SCALAR }
sub parent { $_[0]->{parent} }
sub pos   { $_[0]->{pos} || $_[0]->{pos_s} }
sub pos_s { $_[0]->{pos_s} || $_[0]->{pos} }
sub pos_e { $_[0]->{pos_e} || $_[0]->{pos} }

sub set_parent {
    my( $self, $parent ) = @_;

    $_[0]->{parent} = $parent;
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
    my( $self, $name, $value ) = @_;

    $self->{attributes}->{$name} = $value;
}

package Language::P::ParseTree::LexicalState;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(changed package hints warnings);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }

package Language::P::ParseTree::Use;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(package version import is_no lexical_state);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }

package Language::P::ParseTree::Empty;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

sub can_implicit_return { 0 }
sub is_empty { return !$_[0]->has_attribute( 'label' ) }

package Language::P::ParseTree::Constant;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(value flags);

sub is_constant { 1 }
sub is_bareword { $_[0]->{flags} & Language::P::Constants::STRING_BARE }
sub is_string   { $_[0]->{flags} & Language::P::Constants::CONST_STRING }
sub is_number   { $_[0]->{flags} & Language::P::Constants::CONST_NUMBER }

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::QuotedString;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(components);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::ReferenceConstructor;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expression type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::FunctionCall;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(function arguments);

__PACKAGE__->mk_ro_accessors( @FIELDS );

# quick and dirty mapping from parsing prototype to runtime context
sub _make_rtproto {
    my( $proto ) = @_;

    return [ map { $_ == Language::P::Constants::PROTO_SCALAR ?
                       Language::P::Constants::CXT_SCALAR :
                       Language::P::Constants::CXT_LIST }
                 @{$proto}[ 3 .. $#$proto ] ];
}

sub parsing_prototype { return $_[0]->{prototype} || Language::P::Constants::PROTO_DEFAULT }
sub runtime_context   { return $_[0]->{prototype} ? _make_rtproto( $_[0]->{prototype} ) : undef }
sub is_plain_function { 1 }

package Language::P::ParseTree::SpecialFunctionCall;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::FunctionCall);

our @FIELDS = qw(flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_plain_function { 0 }

package Language::P::ParseTree::MethodCall;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(invocant method arguments indirect);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Identifier;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name sigil);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_symbol { 1 }
sub lvalue_context {
    my( $self ) = @_;

    return    $self->sigil == Language::P::Constants::VALUE_HASH
           || $self->sigil == Language::P::Constants::VALUE_ARRAY ?
                 Language::P::Constants::CXT_LIST :
                 Language::P::Constants::CXT_SCALAR;
}

package Language::P::ParseTree::Symbol;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Identifier);

sub symbol_name { return $_[0]->{symbol_name} }
sub set_closed_over {}
sub closed_over { 0 }

package Language::P::ParseTree::LexicalSymbol;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Identifier);

our @FIELDS = qw(level);

__PACKAGE__->mk_ro_accessors( @FIELDS, qw(declaration) );

sub sigil { $_[0]->declaration->sigil }
sub name { $_[0]->declaration->name }

package Language::P::ParseTree::LexicalDeclaration;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Identifier);

our @FIELDS = qw(flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub level { 0 }
sub symbol_name { return $_[0]->sigil . "\0" . $_[0]->name }
sub declaration_type { $_[0]->{flags} & Language::P::Constants::DECLARATION_TYPE_MASK }
sub closed_over { $_[0]->{flags} & Language::P::Constants::DECLARATION_CLOSED_OVER }
sub set_closed_over { $_[0]->{flags} |= Language::P::Constants::DECLARATION_CLOSED_OVER }

package Language::P::ParseTree::Block;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(lines);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }
sub always_void { 1 }

package Language::P::ParseTree::DoBlock;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Block);

sub is_compound { 0 }
# the block is void, the value is produced by the statementd
sub always_void { 1 }

package Language::P::ParseTree::EvalBlock;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Block);

sub is_compound { 0 }

package Language::P::ParseTree::BareBlock;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Block);

our @FIELDS = qw(continue);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_loop { 1 }

package Language::P::ParseTree::Subroutine;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(lines prototype);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub set_parent_for_all_childs {
    return unless $_[0]->lines;
    $_->set_parent( $_[0] ) foreach @{$_[0]->lines};
}

package Language::P::ParseTree::NamedSubroutine;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Subroutine);

our @FIELDS = qw(name);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_declaration { 1 }

package Language::P::ParseTree::SubroutineDeclaration;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(name prototype);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_declaration { 1 }
sub set_parent_for_all_childs { }

package Language::P::ParseTree::AnonymousSubroutine;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Subroutine);

sub name { undef }

package Language::P::ParseTree::BinOp;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op left right);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub always_void {
    return    $_[0]->op == Language::P::Opcodes::OP_LOG_AND
           || $_[0]->op == Language::P::Opcodes::OP_LOG_OR
           || $_[0]->op == Language::P::Opcodes::OP_LOG_AND_ASSIGN
           || $_[0]->op == Language::P::Opcodes::OP_LOG_OR_ASSIGN ? 1 : 0 }

package Language::P::ParseTree::UnOp;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op left);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Parentheses;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::UnOp);

sub op { Language::P::ParseTree::OP_PARENTHESES }
sub lvalue_context { Language::P::Constants::CXT_LIST }

package Language::P::ParseTree::Local;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::UnOp);

sub op { Language::P::ParseTree::OP_LOCAL }
sub lvalue_context { $_[0]->left->lvalue_context }

package Language::P::ParseTree::Jump;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::UnOp);

sub always_void { 1 }

package Language::P::ParseTree::Dereference;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::UnOp);

package Language::P::ParseTree::List;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expressions);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context { Language::P::Constants::CXT_LIST }

package Language::P::ParseTree::Slice;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(subscripted subscript type reference);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context { Language::P::ParseTree::CXT_LIST }

package Language::P::ParseTree::Subscript;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(subscripted subscript type reference);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::Conditional;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(iftrues iffalse);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }
sub always_void { 1 }

package Language::P::ParseTree::ConditionalBlock;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition block block_type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }
sub always_void { 1 }

package Language::P::ParseTree::ConditionalLoop;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::ConditionalBlock);

our @FIELDS = qw(continue);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }
sub is_compound { 1 }
sub is_loop { 1 }
sub always_void { 1 }

package Language::P::ParseTree::For;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::ConditionalLoop);

our @FIELDS = qw(initializer step);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_compound { 1 }
sub is_loop { 1 }
sub always_void { 1 }

package Language::P::ParseTree::Foreach;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(expression block variable continue);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub can_implicit_return { 0 }
sub is_compound { 1 }
sub is_loop { 1 }
sub always_void { 1 }

package Language::P::ParseTree::Ternary;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(condition iftrue iffalse);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub lvalue_context {
    my( $self ) = @_;
    my $l = $self->iftrue->lvalue_context;
    my $r = $self->iffalse->lvalue_context;

    Carp::confess( "Assigning to both scalar and array" ) unless $r == $l;

    return $r;
}

sub always_void { 1 }

package Language::P::ParseTree::Builtin;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::FunctionCall);

sub parsing_prototype { return $Language::P::Opcodes::PROTOTYPE{$_[0]->function} }
sub runtime_context { return $Language::P::Opcodes::CONTEXT{$_[0]->function} }
sub can_implicit_return { return $_[0]->function == Language::P::ParseTree::OP_RETURN || $_[0]->function == Language::P::ParseTree::OP_DYNAMIC_GOTO ? 0 : 1 }
sub is_plain_function { 0 }
sub always_void { return $_[0]->function == Language::P::ParseTree::OP_DYNAMIC_GOTO ? 1 : 0 }

package Language::P::ParseTree::BuiltinIndirect;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Builtin);

our @FIELDS = qw(indirect);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub runtime_context {
    return $Language::P::Opcodes::CONTEXT{$_[0]->function} if $_[0]->function != Language::P::ParseTree::OP_GREP;
    return $_[0]->indirect ? [ Language::P::ParseTree::CXT_LIST ] :
                             [ Language::P::ParseTree::CXT_SCALAR, Language::P::ParseTree::CXT_LIST ];
}

package Language::P::ParseTree::Overridable;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::FunctionCall);

sub parsing_prototype { return $Language::P::Opcodes::PROTOTYPE{$_[0]->function} }
sub runtime_context { return $Language::P::Opcodes::CONTEXT{$_[0]->function} }
sub is_plain_function { 0 }

package Language::P::ParseTree::Glob;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Overridable);

sub function { Language::P::ParseTree::OP_GLOB }

package Language::P::ParseTree::InterpolatedPattern;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op string flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_pattern { 1 }

package Language::P::ParseTree::Pattern;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(op components flags original);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_pattern { 1 }

package Language::P::ParseTree::Substitution;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(pattern replacement);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_pattern { 1 }

package Language::P::ParseTree::Transliteration;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(match replacement flags);

__PACKAGE__->mk_ro_accessors( @FIELDS );

sub is_pattern { 1 }

package Language::P::ParseTree::RXConstant;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(value insensitive);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXGroup;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(components capture);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXQuantifier;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(node min max greedy);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXAssertion;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXAssertionGroup;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(components type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXClass;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(elements insensitive);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXSpecialClass;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXPosixClass;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(type);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXRange;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(start end);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXAlternation;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(left right);

__PACKAGE__->mk_ro_accessors( @FIELDS );

package Language::P::ParseTree::RXBackreference;

use strict;
use warnings;
use parent -norequire, qw(Language::P::ParseTree::Node);

our @FIELDS = qw(group);

__PACKAGE__->mk_ro_accessors( @FIELDS );

1;
