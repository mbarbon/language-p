package Language::P::Intermediate::Serialize;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Opcodes qw(:all);

sub serialize {
    my( $self, $tree, $file ) = @_;
    open my $out, '>', $file || die "open '$file': $!";

    # compilation unit
    print $out pack 'V', 1;

    # first is main
    _write_sub( $self, $out, $tree->[0], '' );
}

sub _write_sub {
    my( $self, $out, $code, $name ) = @_;

    _write_string( $out, '' );
    my $bb = $code->basic_blocks;

    $self->{bb_map} = {};
    for( my $i = 0; $i <= $#$bb; ++$i ) {
        $self->{bb_map}{$bb->[$i]} = $i;
    }

    print $out pack 'V', scalar @$bb;
    for( my $i = 0; $i <= $#$bb; ++$i ) {
        _write_bb( $self, $out, $bb->[$i] );
    }
}

sub _write_bb {
    my( $self, $out, $bb ) = @_;
    my $ops = $bb->bytecode;

    print $out pack 'V', scalar( @$ops ) - 1; # skips label
    _write_op( $self, $out, $_ ) foreach @$ops;
}

sub _write_op {
    my( $self, $out, $op ) = @_;
    return if $op->{label}; # skip label

    my $opn = $op->{opcode_n};

    print $out pack 'v', $opn;

    if( $opn == OP_CONSTANT_STRING || $opn == OP_FRESH_STRING ) {
        _write_string( $out, $op->{attributes}{value} );
    } elsif( $opn == OP_CONSTANT_INTEGER ) {
        print $out pack 'V', $op->{attributes}{value};
    } elsif( $opn == OP_GET ) {
        print $out pack 'V', $op->{attributes}{index};
    } elsif( $opn == OP_SET ) {
        print $out pack 'V', $op->{attributes}{index};
    } elsif( $opn == OP_GLOBAL ) {
        _write_string( $out, $op->{attributes}{name} );
        print $out pack 'C', $op->{attributes}{slot};
    } elsif( exists $op->{attributes}{to} ) {
        print $out pack 'V', $self->{bb_map}{$op->{attributes}{to}};
    }

    if( $op->{parameters} ) {
        print $out pack 'V', scalar @{$op->{parameters}};
        _write_op( $self, $out, $_ ) foreach @{$op->{parameters}};
    } else {
        print $out pack 'V', 0;
    }
}

sub _write_string {
    my( $out, $string ) = @_;

    utf8::upgrade( $string );
    utf8::encode( $string );

    print $out pack 'V', length $string;
    print $out $string;
}

1;
