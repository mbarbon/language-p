package Language::P::Instruction;

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_ro_accessors( qw(label literal opcode opcode_n
                                 parameters attributes) );

use Scalar::Util; # blessed
use Language::P::Constants qw(VALUE_SCALAR VALUE_ARRAY VALUE_HASH);

my %sigil_to_name =
  ( VALUE_SCALAR() => 'scalar',
    VALUE_ARRAY()  => 'array',
    VALUE_HASH()   => 'hash',
    );

sub _p {
    my( $self, $arg, $name, $number_to_name, $attributes ) = @_;

    return 'undef' unless defined $arg;

    if( Scalar::Util::blessed( $arg ) ) {
        return $arg->start_label
            if $arg->isa( 'Language::P::Intermediate::BasicBlock' );
        return '(' . substr( $arg->as_string( $number_to_name, $attributes ), 2, -1 ) . ')'
            if $arg->isa( 'Language::P::Instruction' );
        return $sigil_to_name{$arg->sigil} . '(' . $arg->name . ')'
            if $arg->isa( 'Language::P::ParseTree::LexicalDeclaration' );
        return 'anoncode'
            if $arg->isa( 'Language::P::Intermediate::Code' );
    }
    if( ref( $arg ) eq 'HASH' ) {
        return '{' . join( ', ', map "$_ => $arg->{$_}",
                                 sort keys %$arg ) . '}';
    }
    if( ref( $arg ) eq 'ARRAY' ) {
        return '[' . join( ', ', map _p( $self, $_ ), @$arg ) . ']';
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

    my $str = '  ';
    if( defined $self->{opcode} ) {
        $str .= $self->{opcode};
    } elsif( defined $self->{opcode_n} ) {
        $str .= $number_to_name->{$self->{opcode_n}};
    }

    if( $self->{attributes} ) {
        die "Can't happen ", $self->{opcode_n} unless %{$self->{attributes}};
        $str .= ' ' . join ', ',
                      map  { "$_=" . _p( $self, $self->{attributes}{$_}, $_, $number_to_name, $attributes ) }
                           sort keys %{$self->{attributes}};
    }

    if( $self->{parameters} ) {
        die "Can't happen ", $self->{opcode_n} unless @{$self->{parameters}};
        $str .= ' ' . join ', ', map _p( $self, $_, undef, $number_to_name, $attributes ),
                                     @{$self->{parameters}};
    }

    return $str . "\n";
}

1;
