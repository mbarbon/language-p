package Language::P::Intermediate::Serialize;

use strict;
use warnings;
use parent qw(Language::P::Object);

use Language::P::Opcodes qw(:all);
use Language::P::Intermediate::SerializeGenerated;

sub serialize {
    my( $self, $tree, $file, $data_handle ) = @_;
    open my $out, '>', $file or die "Unable to write '$file': $! (maybe set \$ENV{P_BYTECODE_PATH} before running)";

    $self->{sub_map} = {};
    $self->{file_map} = {};
    for( my $i = 0; $i <= $#$tree; ++$i ) {
        $self->{sub_map}{$tree->[$i]} = $i;
    }

    # compilation unit
    print $out pack 'V', scalar @$tree;
    print $out pack 'V', $data_handle ? 1 : 0;

    for( my $i = 0; $i <= $#$tree; ++$i ) {
        _write_sub( $self, $out, $tree->[$i], $tree->[$i]->name );
    }

    if( $data_handle ) {
        _write_string( $out, $data_handle->[0] );
        _write_string( $out, $data_handle->[1] );
    }
}

sub _write_pos {
    my( $self, $out, $pos ) = @_;

    if( !$pos ) {
        print $out pack 'v', -2;
        return;
    }

    my $idx = $self->{file_map}{$pos->[0]};

    if( defined $idx ) {
        print $out pack 'v', $idx;
    } else {
        print $out pack 'v', -1;
        _write_string( $out, $pos->[0] );
        $self->{file_map}{$pos->[0]} = scalar keys %{$self->{file_map}};
    }

    print $out pack 'V', $pos->[1];
}

sub _write_sub {
    my( $self, $out, $code, $name ) = @_;
    my $bb = $code->basic_blocks;

    _write_string_undef( $out, $name );
    _write_string_undef( $out, $code->prototype );

    $self->{bb_map} = {};
    for( my $i = 0; $i <= $#$bb; ++$i ) {
        $self->{bb_map}{$bb->[$i]} = $i;
    }

    print $out pack 'C', $code->type;
    print $out pack 'V', $code->outer ? $self->{sub_map}{$code->outer} : -1;
    if( !$code->is_regex ) {
        print $out pack 'V', scalar @{$code->lexicals};
    } else {
        print $out pack 'V', 0;
        for( my $i = 0; $i <= $#$bb; ++$i ) {
            $bb->[$i]->{dead} = 0;
        }
    }
    print $out pack 'V', scalar @{$code->scopes};
    print $out pack 'V', scalar @{$code->lexical_states};
    print $out pack 'V', scalar @$bb;
    _write_string( $out, $code->regex_string ) if $code->is_regex;

    # TODO serialize prototype

    if( !$code->is_regex ) {
        my $index = 0;
        foreach my $l ( @{$code->lexicals} ) {
            _write_lex_info( $self, $out, $l );
            $self->{li_map}{$l} = $index++;
        }
    }

    foreach my $s ( @{$code->scopes} ) {
        _write_scope( $self, $out, $s );
    }

    foreach my $l ( @{$code->lexical_states} ) {
        _write_lex_state( $self, $out, $l );
    }

    for( my $i = 0; $i <= $#$bb; ++$i ) {
        _write_bb( $self, $out, $bb->[$i] );
    }
}

sub _write_lex_info {
    my( $self, $out, $lex_info ) = @_;

    print $out pack 'V', $lex_info->level;
    print $out pack 'V', $lex_info->index;
    print $out pack 'V', $lex_info->outer_index;
    _write_string( $out, $lex_info->name );
    print $out pack 'C', $lex_info->sigil;
    print $out pack 'C', $lex_info->in_pad;
    print $out pack 'C', $lex_info->from_main;
}

sub _write_scope {
    my( $self, $out, $scope ) = @_;

    print $out pack 'V', $scope->outer;
    print $out pack 'V', $scope->id;
    print $out pack 'V', $scope->flags;
    print $out pack 'V', $scope->context;
    _write_pos( $self, $out, $scope->pos_s );
    _write_pos( $self, $out, $scope->pos_e );
    print $out pack 'V', $scope->lexical_state;
    print $out pack 'V', $scope->exception ?
        $self->{bb_map}{$scope->exception} : -1;
    print $out pack 'V', scalar @{$scope->bytecode};

    foreach my $bc ( @{$scope->bytecode} ) {
        print $out pack 'V', scalar @$bc;
        _write_op( $self, $out, $_ ) foreach @$bc;
    }
}

sub _write_lex_state {
    my( $self, $out, $lex_state ) = @_;

    print $out pack 'V', $lex_state->scope;
    print $out pack 'V', $lex_state->hints;
    _write_string( $out, $lex_state->package );
    _write_string( $out, $lex_state->warnings || '' );
}

sub _write_bb {
    my( $self, $out, $bb ) = @_;
    my $ops = $bb->bytecode;

    if( $bb->dead ) {
        print $out pack 'V', 0;
        print $out pack 'V', 0;

        return;
    } elsif( !@$ops ) {
        die "Empty alive block";
    }

    print $out pack 'V', $bb->scope;
    print $out pack 'V', scalar( @$ops );

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

    if( !defined $string ) {
        print $out pack 'V', 0xffffffff;
    } else {
        _write_string( $out, $string );
    }
}

1;
