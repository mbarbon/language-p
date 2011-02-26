package Language::P::Assembly;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(literal opcode opcode_n opcode_m opcode_nm
                    opcode_np opcode_npm opcode_nam opcode_npam);
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

sub i;

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

sub opcode_np {
    my( $number, $pos, @parameters ) = @_;

    return i { opcode_n   => $number,
               pos        => $pos,
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

sub opcode_npm {
    my( $number, $pos, %attributes ) = @_;

    return i { opcode_n   => $number,
               pos        => $pos,
               attributes => %attributes ? \%attributes : undef,
               };
}

sub opcode_nam {
    my( $number, $parameters, %attributes ) = @_;

    return i { opcode_n   => $number,
               parameters => $parameters,
               attributes => %attributes ? \%attributes : undef,
               };
}

sub opcode_npam {
    my( $number, $pos, $parameters, %attributes ) = @_;

    return i { opcode_n   => $number,
               pos        => $pos,
               parameters => $parameters,
               attributes => %attributes ? \%attributes : undef,
               };
}

1;
