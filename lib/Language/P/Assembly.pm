package Language::P::Assembly;

use strict;
use warnings;
use Exporter; *import = \&Exporter::import;

our @EXPORT_OK = qw(label literal opcode opcode_n opcode_m opcode_nm);
our %EXPORT_TAGS =
  ( all   => \@EXPORT_OK,
    );

=head1 NAME

Language::P::Assembly - representation for generic assembly-like language

=head1 DESCRIPTION

Abstract representation for assembly-like languages, used internally
by backends.

=head1 FUNCTIONS

=cut

sub i { Language::P::Assembly::Instruction->new( $_[0] ) }

=head2 label

  my $l = label( 'lbl1' );

A label, rendered as a left-aligned C<lbl1:>.

=cut

sub label {
    my( $label ) = @_;

    return i { label => $label,
               };
}

=head2 literal

  my $l = literal( "foo: eq 123" );

A string rendered as-is in the final output.

=cut

sub literal {
    my( $string ) = @_;

    return i { literal => $string,
               };
}

=head2 opcode

  my $o = opcode( 'add', $res, $op1, $op2 );

A generic opcode with operands, rendered as C<  add arg1, arg2, ...>.

=cut

sub opcode {
    my( $name, @parameters ) = @_;

    return i { opcode     => $name,
               parameters => @parameters ? \@parameters : undef,
               };
}

sub opcode_n {
    my( $number, @parameters ) = @_;

    return i { opcode_n   => $number,
               parameters => @parameters ? \@parameters : undef,
               };
}

sub opcode_m {
    my( $name, %attributes ) = @_;

    return i { opcode     => $name,
               attributes => %attributes ? \%attributes : undef,
               };
}

sub opcode_nm {
    my( $number, %attributes ) = @_;

    return i { opcode_n   => $number,
               attributes => %attributes ? \%attributes : undef,
               };
}

package Language::P::Assembly::Instruction;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(label literal opcode opcode_n
                                 parameters attributes) );

use Scalar::Util qw(blessed);
use Language::P::ParseTree qw(VALUE_SCALAR VALUE_ARRAY VALUE_HASH);

my %sigil_to_name =
  ( VALUE_SCALAR() => 'scalar',
    VALUE_ARRAY()  => 'array',
    VALUE_HASH()   => 'hash',
    );

sub _p {
    my( $self, $arg, $name, $number_to_name, $attributes ) = @_;

    return 'undef' unless defined $arg;

    if( blessed( $arg ) ) {
        return $arg->start_label
            if $arg->isa( 'Language::P::Intermediate::BasicBlock' );
        return '(' . substr( $arg->as_string( $number_to_name, $attributes ), 2, -1 ) . ')'
            if $arg->isa( 'Language::P::Assembly::Instruction' );
        return $sigil_to_name{$arg->sigil} . '(' . $arg->name . ')'
            if $arg->isa( 'Language::P::ParseTree::LexicalDeclaration' );
        return 'anoncode'
            if $arg->isa( 'Language::P::Intermediate::Code' );
    }
    if( ref( $arg ) eq 'HASH' ) {
        return '{' . join( ', ', map "$_ => $arg->{$_}", keys %$arg ) . '}';
    }
    if(    $self->{opcode_n} && defined $name && $attributes
        && (my $named = $attributes->{$self->{opcode_n}}{named}) ) {
        my $type = $named->{$name};

        if( $type && $type eq 's' ) {
            ( my $v = $arg ) =~ s/([^\x20-\x7f])/sprintf "\\x%02x", ord $1/eg;

            return qq{"$v"};
        }
    }

    return $arg;
}

sub as_string {
    my( $self, $number_to_name, $attributes ) = @_;

    return $self->{literal} . "\n" if defined $self->{literal};

    my $str = defined $self->{label} ? $self->{label} . ':' : ' ';

    return $str . "\n" unless    defined $self->{opcode}
                              || defined $self->{opcode_n};
    $str .= ' ';

    if( defined $self->{opcode} ) {
        $str .= $self->{opcode};
    } elsif( defined $self->{opcode_n} ) {
        $str .= $number_to_name->{$self->{opcode_n}};
    }

    if( $self->{attributes} ) {
        die "Can't happen" unless %{$self->{attributes}};
        $str .= ' ' . join ', ',
                      map  { "$_=" . _p( $self, $self->{attributes}{$_}, $_, $number_to_name, $attributes ) }
                           keys %{$self->{attributes}};
    }

    if( $self->{parameters} ) {
        die "Can't happen" unless @{$self->{parameters}};
        $str .= ' ' . join ', ', map _p( $self, $_, undef, $number_to_name, $attributes ),
                                     @{$self->{parameters}};
    }

    return $str . "\n";
}

1;
