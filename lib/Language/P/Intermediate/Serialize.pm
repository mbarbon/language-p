package Language::P::Intermediate::Serialize;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Opcodes qw(:all);
use Language::P::Intermediate::SerializeGenerated;

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
    print $out pack 'V', scalar @{$code->scopes};
    print $out pack 'V', scalar @{$code->lexical_states};
    print $out pack 'V', scalar @$bb;

    # TODO serialize prototype

    my $index = 0;
    foreach my $l ( values %{$code->lexicals->{map}} ) {
        _write_lex_info( $self, $out, $l );
        $self->{li_map}{$l->{index} . "|" . $l->{in_pad}} = $index++;
    }

    foreach my $s ( @{$code->scopes} ) {
        _write_scope( $self, $out, $s );
    }

    foreach my $l ( @{$code->lexical_states} ) {
        _write_lex_state( $self, $out, $l );
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
    _write_string( $out, $lex_info->{name} );
    print $out pack 'C', $lex_info->{sigil};
    print $out pack 'C', $lex_info->{in_pad};
    print $out pack 'C', $lex_info->{from_main};
}

sub _write_scope {
    my( $self, $out, $scope ) = @_;

    print $out pack 'V', $scope->{outer};
    print $out pack 'V', $scope->{id};
    print $out pack 'V', $scope->{flags};
    print $out pack 'V', $scope->{context};
    print $out pack 'V', scalar @{$scope->{bytecode}};

    foreach my $bc ( @{$scope->{bytecode}} ) {
        print $out pack 'V', scalar @$bc;
        _write_op( $self, $out, $_ ) foreach @$bc;
    }
}

sub _write_lex_state {
    my( $self, $out, $lex_state ) = @_;

    print $out pack 'V', $lex_state->{scope};
    print $out pack 'V', $lex_state->{hints};
    _write_string( $out, $lex_state->{package} );
    _write_string( $out, $lex_state->{warnings} || '' );
}

sub _write_bb {
    my( $self, $out, $bb ) = @_;
    my $ops = $bb->bytecode;

    print $out pack 'V', $bb->lexical_state;
    print $out pack 'V', scalar( @$ops ) - 1; # skips label

    _write_op( $self, $out, $_ ) foreach @$ops;
}

sub _write_string {
    my( $out, $string ) = @_;

    utf8::upgrade( $string );
    utf8::encode( $string );

    print $out pack 'V', length $string;
    print $out $string;
}

sub _write_string_undef {
    my( $out, $string ) = @_;

    _write_string( $out, defined $string ? $string : '' );
}

1;
