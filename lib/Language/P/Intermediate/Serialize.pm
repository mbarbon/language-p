package Language::P::Intermediate::Serialize;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Opcodes qw(:all);

sub serialize {
    my( $self, $tree, $file ) = @_;
    open my $out, '>', $file || die "open '$file': $!";

    $self->{sub_map} = {};
    for( my $i = 0; $i <= $#$tree; ++$i ) {
        $self->{sub_map}{$tree->[$i]} = $i;
    }

    # compilation unit
    print $out pack 'V', scalar @$tree;
    for( my $i = 0; $i <= $#$tree; ++$i ) {
        _write_sub( $self, $out, $tree->[$i], $tree->[$i]->name );
    }
}

sub _write_sub {
    my( $self, $out, $code, $name ) = @_;
    my $bb = $code->basic_blocks;

    _write_string( $out, defined $name ? $name : '' );

    print $out pack 'C', $code->type;
    print $out pack 'V', $code->outer ? $self->{sub_map}{$code->outer} : -1;
    print $out pack 'V', scalar values %{$code->lexicals->{map}};
    print $out pack 'V', scalar @$bb;

    my $index = 0;
    foreach my $l ( values %{$code->lexicals->{map}} ) {
        _write_lex_info( $self, $out, $l );
        $self->{li_map}{$l->{index} . "|" . $l->{in_pad}} = $index++;
    }

    $self->{bb_map} = {};
    for( my $i = 0; $i <= $#$bb; ++$i ) {
        $self->{bb_map}{$bb->[$i]} = $i;
    }

    for( my $i = 0; $i <= $#$bb; ++$i ) {
        _write_bb( $self, $out, $bb->[$i] );
    }
}

sub _write_lex_info {
    my( $self, $out, $lex_info ) = @_;

    print $out pack 'V', $lex_info->{level};
    print $out pack 'V', $lex_info->{index};
    print $out pack 'V', $lex_info->{outer_index};
    _write_string( $out, $lex_info->{lexical}->name );
    print $out pack 'C', $lex_info->{lexical}->sigil;
    print $out pack 'C', $lex_info->{in_pad};
    print $out pack 'C', $lex_info->{from_main};
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
    } elsif( $opn == OP_GET || $opn == OP_SET ) {
        print $out pack 'V', $op->{attributes}{index};
    } elsif(    $opn == OP_LEXICAL
             || $opn == OP_LEXICAL_SET
             || $opn == OP_LEXICAL_CLEAR ) {
        print $out pack 'V', $self->{li_map}{$op->{attributes}{index} . '|0'};
    } elsif(    $opn == OP_LEXICAL_PAD
             || $opn == OP_LEXICAL_PAD_SET
             || $opn == OP_LEXICAL_PAD_CLEAR ) {
        print $out pack 'V', $self->{li_map}{$op->{attributes}{index} . '|1'};
    } elsif( $opn == OP_GLOBAL ) {
        _write_string( $out, $op->{attributes}{name} );
        print $out pack 'C', $op->{attributes}{slot};
    } elsif( $opn == OP_CALL ) {
        print $out pack 'C', $op->{attributes}{context};
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
