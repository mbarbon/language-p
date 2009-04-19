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
    _write_sub( $out, $tree->[0], '' );
}

sub _write_sub {
    my( $out, $code, $name ) = @_;

    _write_string( $out, '' );
    my $bb = $code->basic_blocks;

    print $out pack 'V', scalar @$bb;
    _write_bb( $out, $_ ) foreach @$bb;
}

sub _write_bb {
    my( $out, $bb ) = @_;
    my $ops = $bb->bytecode;

    print $out pack 'V', scalar( @$ops ) - 1; # skips label
    _write_op( $out, $_ ) foreach @$ops;
}

sub _write_op {
    my( $out, $op ) = @_;
    return if $op->{label}; # skip label

    my $opn = $op->{opcode_n};

    print $out pack 'v', $opn;

    if( $opn == OP_CONSTANT_STRING ) {
        # FIXME move to attribute
        _write_string( $out, $op->{parameters}[0] );
        print $out pack 'V', 0;
        return;
    } elsif( $opn == OP_GLOBAL ) {
        _write_string( $out, $op->{attributes}{name} );
        print $out pack 'C', $op->{attributes}{slot};
    }

    if( $op->{parameters} ) {
        print $out pack 'V', scalar @{$op->{parameters}};
        _write_op( $out, $_ ) foreach @{$op->{parameters}};
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
