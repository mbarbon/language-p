package Language::P::Assembly;

use strict;
use warnings;
use Exporter; *import = \&Exporter::import;

our @EXPORT_OK = qw(label literal opcode);
our %EXPORT_TAGS =
  ( all   => \@EXPORT_OK,
    );

=head1 NAME

Language::P::Assembly - representation for generic assembly-like language

=head1 DESCRIPTION

Abstract representation for assembly-like languages, used internally
by backends.

=cut

sub i { Language::P::Assembly::Instruction->new( $_[0] ) }

sub label {
    my( $label ) = @_;

    return i { label => $label,
               };
}

sub literal {
    my( $string ) = @_;

    return i { literal => $string,
               };
}

sub opcode {
    my( $name, @parameters ) = @_;

    return i { opcode     => $name,
               parameters => \@parameters,
               };
}

package Language::P::Assembly::Instruction;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(label literal opcode parameters) );

sub as_string {
    my( $self ) = @_;

    return $self->{literal} . "\n" if defined $self->{literal};

    my $str = defined $self->{label} ? $self->{label} . ': ' : '  ';

    if( defined $self->{opcode} ) {
        $str .= $self->{opcode};

        if( @{$self->{parameters}} ) {
            $str .= ' ' . join ', ', @{$self->{parameters}};
        }
    }

    return $str . "\n";
}

1;
