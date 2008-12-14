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
    my( $name, %parameters ) = @_;

    return i { opcode     => $name,
               parameters => %parameters ? \%parameters : undef,
               };
}

sub opcode_nm {
    my( $number, %parameters ) = @_;

    return i { opcode_n   => $number,
               parameters => %parameters ? \%parameters : undef,
               };
}

package Language::P::Assembly::Instruction;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(label literal opcode parameters) );

use Scalar::Util qw(blessed);

sub _p {
    return    blessed( $_[0] )
           && $_[0]->isa( 'Language::P::Intermediate::BasicBlock' ) ?
             $_[0]->start_label : $_[0];
}

sub as_string {
    my( $self, $number_to_name ) = @_;

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

    if(    $self->{parameters}
        && ref( $self->{parameters} ) eq 'ARRAY' ) {
        $str .= ' ' . join ', ', @{$self->{parameters}};
    } elsif(    $self->{parameters}
             && ref( $self->{parameters} ) eq 'HASH' ) {
        $str .= ' ' . join ', ',
                      map  { "$_=" . _p( $self->{parameters}{$_} ) }
                           keys %{$self->{parameters}};
    }

    return $str . "\n";
}

1;
