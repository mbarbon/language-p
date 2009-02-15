package Language::P::Parrot::Generator;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(file_name _intermediate _options _pending) );
__PACKAGE__->mk_ro_accessors( qw(parrot _body _onload _body_segments
                                 _lexical_map _global_allocated _labels
                                 _temp_map
                                 runtime) );

use Language::P::ParseTree qw(:all);
use Language::P::Assembly qw(:all);
use Language::P::Intermediate::Generator;
use Language::P::Intermediate::Transform;
use Language::P::Opcodes qw(:all);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_intermediate( Language::P::Intermediate::Generator->new );
    $self->_options( {} );

    return $self;
}

sub set_option {
    my( $self, $option, $value ) = @_;

    if( $option eq 'dump-pir' ) {
        $self->_options->{$option} = 1;
    }
    if( $option eq 'dump-ir' ) {
        $self->_options->{$option} = 1;
        $self->_intermediate->set_option( 'dump-ir' );
    }

    return 0;
}

my $local = 0;
sub _local_name { sprintf "loc%d", ++$local }
sub _local_pmc_name { sprintf "\$P%d", ++$local }
sub _local_int_name { sprintf "\$I%d", ++$local }
my $constant = 0;
sub _const_name { sprintf "const%d", ++$constant }
my $label = 0;
sub _label_name { sprintf "lbl%d", ++$label }
sub local_pmc { literal( sprintf '  .local pmc %s', $_[0] ) }

sub _label {
    my( $self, $to ) = @_;
    return $self->_labels->{$to} if $self->_labels->{$to};
    return $self->_labels->{$to} = _label_name;
}

sub _confess {
    my( $self, $tree ) = @_;

    Carp::confess( ref( $tree ) );
}

sub _add {
    my( $self, @insns ) = @_;

    push @{$self->{_body}}, @insns;
}

sub start_code_generation {
    my( $self, $args ) = @_;

    $self->_intermediate->file_name( $args->{file_name} )
      if $args && $args->{file_name};
    $self->_pending( [] );
}

my %sigil_to_slot =
  ( VALUE_SCALAR() => 'scalar',
    VALUE_SUB()    => 'subroutine',
    VALUE_ARRAY()  => 'array',
    VALUE_HANDLE() => 'io',
    );

my %op_map =
  ( OP_CONSTANT_STRING()       => '_constant',
    OP_CONSTANT_INTEGER()      => '_constant',
    OP_CONSTANT_FLOAT()        => '_constant',
    OP_CONSTANT_UNDEF()        => '_constant',
    OP_PRINT()                 => '_print',
    OP_END()                   => '_end',
    OP_GLOBAL()                => '_symbol',
    OP_GLOB_SLOT()             => '_glob_slot',
    OP_GLOB_SLOT_SET()         => '_glob_slot_set',
    OP_LOCALIZE_GLOB_SLOT()    => '_localize_glob_slot',
    OP_RESTORE_GLOB_SLOT()     => '_restore_glob_slot',
    OP_ASSIGN()                => '_assign',
    OP_MAKE_LIST()             => '_make_list',
    OP_FRESH_STRING()          => '_fresh_string',
    OP_SET()                   => '_set',
    OP_GET()                   => '_get',
    OP_TEMPORARY_SET()         => '_temporary_set',
    OP_TEMPORARY()             => '_temporary_get',
    OP_CONCATENATE()           => '_concat',
    OP_CONCAT_ASSIGN()         => '_concat_assign',
    OP_JUMP_IF_S_EQ()          => '_conditional_jump',
    OP_JUMP_IF_S_NE()          => '_conditional_jump',
    OP_JUMP_IF_S_LT()          => '_conditional_jump',
    OP_JUMP_IF_S_LE()          => '_conditional_jump',
    OP_JUMP_IF_S_GT()          => '_conditional_jump',
    OP_JUMP_IF_S_GE()          => '_conditional_jump',
    OP_JUMP_IF_F_EQ()          => '_conditional_jump',
    OP_JUMP_IF_F_NE()          => '_conditional_jump',
    OP_JUMP_IF_F_LT()          => '_conditional_jump',
    OP_JUMP_IF_F_LE()          => '_conditional_jump',
    OP_JUMP_IF_F_GT()          => '_conditional_jump',
    OP_JUMP_IF_F_GE()          => '_conditional_jump',
    OP_JUMP()                  => '_jump',
    OP_ARRAY_LENGTH()          => '_array_size',
    OP_LOG_NOT()               => '_not',
    OP_MULTIPLY()              => '_multiply',
    OP_ADD()                   => '_addition',
    OP_SUBTRACT()              => '_subtract',
    OP_ARRAY_ELEMENT()         => '_array_element',
    OP_ITERATOR()              => '_iterator',
    OP_ITERATOR_NEXT()         => '_iterator_next',
    OP_JUMP_IF_NULL()          => '_jump_if_null',
    OP_JUMP_IF_TRUE()          => '_jump_if_true',
    OP_LEXICAL_SET()           => '_lexical_set',
    OP_LEXICAL_CLEAR()         => '_lexical_clear',
    OP_LEXICAL()               => '_lexical',
    OP_DEFINED()               => '_defined',
    OP_CALL()                  => '_call',
    OP_RETURN()                => '_return',
    OP_WANTARRAY()             => '_want',
    );

sub _dispatch {
    my( $self, $bc ) = @_;

    my $meth = $op_map{$bc->{opcode_n}};
    Carp::confess( $NUMBER_TO_NAME{$bc->{opcode_n}} ) unless $meth;

    $self->$meth( $bc );
}

sub _make_block {
    my( $self, $block ) = @_;

    _add $self, label( _label( $self, $block ) );

    foreach my $bc ( @{$block->bytecode} ) {
        next if $bc->{label};
        _dispatch( $self, $bc );
    }
}

sub end_code_generation {
    my( $self ) = @_;

    my $transform = Language::P::Intermediate::Transform->new;
    my $stack_segs = $self->_intermediate->generate_bytecode( $self->_pending );
    my $register_segs = [ map $transform->to_tree( $_ ), @$stack_segs ];

    open my $out, '| ' . $self->parrot . ' -L support/parrot --output-pbc -o ' .
                         $self->file_name . ' -' or die $!;
    my $pir_dump;

    if( $self->_options->{'dump-pir'} ) {
        ( my $outfile = $self->file_name ) =~ s/(\.\w+)?$/.pir/;
        open $pir_dump, '>', $outfile || die "Can't open '$outfile': $!";
    }

    $self->{_body} = [];
    $self->{_onload} = [];
    $self->{_body_segments} = [ $self->{_body} ];
    $self->{_labels} = {};
    $self->{_temp_map} = {};

    _add $self,
         literal( ".HLL 'P5'" ),
         literal( ".loadlib 'support/parrot/runtime/p5runtime.pbc'" ),
         literal( ".include 'support/parrot/runtime/p5macros.pir'" ),
         literal( ".HLL_map 'Integer' = 'P5Integer'" ),
         literal( ".HLL_map 'Float' = 'P5Float'" ),
         literal( ".HLL_map 'String' = 'P5String'" ),
         literal( ".namespace ['main']" );
    push @{$self->_onload},
         literal( "  load_bytecode 'support/parrot/runtime/p5runtime.pbc'" ),
         literal( "  .local pmc sym" ),
         literal( "  .local pmc body" ),
         literal( "  .local pmc slot" );

    $self->{_lexical_map} = {};
    $self->{_global_allocated} = {};

    foreach my $sub ( @$register_segs ) {
        next unless $sub->type == 2;
        next unless $sub->name;

        my $csub = _const_name;
        _add_global( $self, $sub->name, 'subroutine',
                     [ literal( sprintf '  .const "Sub" %s = "%s"',
                                        $csub, $sub->name ),
                       opcode( 'set', 'slot', $csub ) ] )
    }

    foreach my $sub ( @$register_segs ) {
        $self->{_body} = [];
        push @{$self->{_body_segments}}, $self->{_body};

        if( $sub->type == 1 ) {
            _add $self,
                 literal( ".sub main :main :lex" ),
                 literal( '  .local int context' ),
                 literal( '  context = ' . CXT_VOID );

            foreach my $lex ( values %{$sub->lexicals} ) {
                # only declared values need on-stack allocation,
                # closed-over values are in pads
                next unless $lex->{declaration};
                my $lname = _local_pmc_name;
                my $lvalue = $self->_lexical_map->{$lex->{lexical}} = _local_name;
                _add $self,
                     literal( sprintf '  .lex "%s", %s',
                                      $lex->{lexical}->{name}, $lname ),
                     local_pmc( $lvalue ),
                     literal( sprintf '  %s = %s', $lvalue, $lname ),
                     literal( sprintf '  .make_undef(%s)', $lvalue );
            }
        } else {
            _add $self,
                 literal( sprintf '.sub %s :outer(main)', $sub->name ),
                 literal( '  .param int context' ),
                 literal( '  .param pmc args' );

            foreach my $lex ( values %{$sub->lexicals} ) {
                # only declared values need on-stack allocation,
                # closed-over values are in pads
                next unless $lex->{declaration};
                my $name = _lex_name( $self, $lex->{lexical} );
                _add $self,
                     local_pmc( $name ),
                     literal( sprintf '  .make_undef(%s)', $name );
            }
        }

        foreach my $block ( @{$sub->basic_blocks} ) {
            _make_block( $self, $block );
        }

        _add $self, literal( '.end' );
    }

    foreach my $sub ( @{$self->_body_segments} ) {
        foreach ( @$sub ) {
            print $pir_dump $_->as_string if $pir_dump;
            print $out $_->as_string;
        }
    }

    if( $pir_dump ) {
        print $pir_dump ".sub on_load :init :load\n";
        print $pir_dump $_->as_string foreach @{$self->_onload};
        print $pir_dump ".end\n";
    }
    print $out ".sub on_load :init :load\n";
    print $out $_->as_string foreach @{$self->_onload};
    print $out ".end\n";

    close $out;

    return $self->file_name;
}

sub add_declaration {
    my( $self, $name ) = @_;

    # needs to pass-through to a Toy runtime when bootstrapping
}

sub process {
    my( $self, $tree ) = @_;

    push @{$self->_pending}, $tree;
}

sub _context {
    my( $op ) = @_;
    my $cxt = $op->{attributes}{context};

    return ( $cxt & CXT_CALLER ) || !$cxt ? 'context' : $cxt;
}

sub _noop {
    my( $self, $op ) = @_;

    # do nothing
}

sub _create_list {
    my( $self, $list ) = @_;

    my $thelist = _local_name;
    _add $self,
         local_pmc( $thelist ),
         opcode( 'new', $thelist, '"P5List"' );

    foreach my $e ( @$list ) {
        _add $self, opcode( 'push', $thelist, _dispatch( $self, $e ) );
    }

    return $thelist;
}

sub _make_list {
    my( $self, $op ) = @_;

    return _create_list( $self, $op->{parameters} );
}

sub _end {
    my( $self, $op ) = @_;

    _add $self, opcode( 'end' );
}

sub _print {
    my( $self, $op ) = @_;

    die "No 'make_list' as child"
        unless $op->{parameters}[0]->{opcode_n} == OP_MAKE_LIST;

    my @orig_arg = @{$op->{parameters}[0]->{parameters}};
    # FIXME must handle output filehandle
    shift @orig_arg;
    my $args = _create_list( $self, \@orig_arg );
    my( $pr, $d ) = ( _local_name, _local_name );
    _add $self,
         local_pmc( $pr ),
         local_pmc( $d ),
         opcode( 'get_root_global', $pr, '["p5";"builtins"]', '"print"' ),
         literal( sprintf '  %s = %s(%s)', $d, $pr, $args );

    return $d;
}

sub _constant {
    my( $self, $op ) = @_;

    if( $op->{opcode_n} == OP_CONSTANT_STRING ) {
        my $const = _const_name;
        my $str = $op->{parameters}[0];
        $str =~ s/([^\x20-\x7f])/sprintf "\\x%02x", ord $1/eg;
        _add $self,
             local_pmc( $const ),
             literal( sprintf '  .make_string(%s, "%s")', $const, $str );

        return $const;
    } elsif( $op->{opcode_n} == OP_CONSTANT_FLOAT ) {
        my $const = _const_name;
        my $int = $op->{parameters}[0];
        _add $self,
             local_pmc( $const ),
             literal( sprintf '  .make_float(%s, %s)', $const, $int );

        return $const;
    } elsif( $op->{opcode_n} == OP_CONSTANT_INTEGER ) {
        my $const = _const_name;
        my $int = $op->{parameters}[0];
        _add $self,
             local_pmc( $const ),
             literal( sprintf '  .make_integer(%s, %s)', $const, $int );

        return $const;
    } elsif( $op->{opcode_n} == OP_CONSTANT_UNDEF ) {
        my $const = _const_name;
        _add $self,
             local_pmc( $const ),
             literal( sprintf '  .make_undef(%s)', $const );

        return $const;
    }
}

sub _defined {
    my( $self, $op ) = @_;

    my( $d, $t ) = ( _local_name, _local_name );
    _add $self,
         local_pmc( $d ),
         literal( sprintf "  .local int %s", $t ),
         opcode( 'defined', $t, _dispatch( $self, $op->{parameters}[0] ) ),
         literal( sprintf '  .make_bool(%s, %s)', $d, $t );

    return $d;
}

sub _not {
    my( $self, $op ) = @_;

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'not', $d, _dispatch( $self, $op->{parameters}[0] ) );

    return $d;
}

sub _array_size {
    my( $self, $op ) = @_;

    my( $res, $int ) = ( _local_name, _local_name );
    _add $self,
         local_pmc( $res ),
         literal( sprintf '  .local int %s', $int ),
         opcode( 'set', $int, _dispatch( $self, $op->{parameters}[0] ) ),
         opcode( 'sub', $int, $int, 1 ),
         literal( sprintf '  .make_float(%s, %s)', $res, $int );

    return $res;
}

sub _assign {
    my( $self, $op ) = @_;
    my $r = _dispatch( $self, $op->{parameters}[1] );
    my $l = _dispatch( $self, $op->{parameters}[0] );

    _add $self, opcode( 'assign', $l, $r );

    return $l;
}

sub _addition {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );
    my $r = _dispatch( $self, $op->{parameters}[1] );

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'add', $d, $l, $r );

    return $d;
}

sub _subtract {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );
    my $r = _dispatch( $self, $op->{parameters}[1] );

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'sub', $d, $l, $r );

    return $d;
}

sub _multiply {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );
    my $r = _dispatch( $self, $op->{parameters}[1] );

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'mul', $d, $l, $r );

    return $d;
}

sub _concat {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );
    my $r = _dispatch( $self, $op->{parameters}[1] );

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'concat', $d, $l, $r );

    return $d;
}

sub _concat_assign {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );
    my $r = _dispatch( $self, $op->{parameters}[1] );

    _add $self,
         opcode( 'concat', $l, $r );

    return $l;
}

sub _conditional_jump {
    my( $self, $op ) = @_;

    # FIXME use map, not match
    my $opname = $NUMBER_TO_NAME{$op->{opcode_n}};
    $opname =~ /jump_if_(\w)_(\w\w)/ or die $opname;
    my $suff = $1 eq 's' ? 'str' : 'num';
    my $cmp = $2;

    _add $self,
         opcode( "${cmp}_${suff}",
                 _dispatch( $self, $op->{parameters}[0] ),
                 _dispatch( $self, $op->{parameters}[1] ),
                 _label( $self, $op->{parameters}[2] ) );
}

sub _jump_if_null {
    my( $self, $op ) = @_;

    _add $self,
         opcode( 'if_null',
                 _dispatch( $self, $op->{parameters}[0] ),
                 _label( $self, $op->{parameters}[1] ) );
}

sub _jump_if_true {
    my( $self, $op ) = @_;

    _add $self,
         opcode( 'if',
                 _dispatch( $self, $op->{parameters}[0] ),
                 _label( $self, $op->{parameters}[1] ) );
}

sub _jump {
    my( $self, $op ) = @_;

    _add $self,
         opcode( "goto", _label( $self, $op->{parameters}[0] ) );
}

sub _list {
    my( $self, $tree ) = @_;

    return _make_list( $self, $tree->expressions );
}

sub _add_global {
    my( $self, $name, $slot, $bytecode ) = @_;
    my $qname = sprintf "'%s'", $name;

    my( $ok_glob, $ok_slot ) = ( _label_name, _label_name );

    if( !$self->_global_allocated->{$name}{VALUE_GLOB()} ) {
        push @{$self->_onload},
             opcode( 'get_root_global', 'sym', '["main"]', $qname ),
             opcode( 'unless_null', 'sym', $ok_glob ),
             opcode( 'new', 'sym', "'P5Typeglob'" ),
             opcode( 'set_root_global', '["main"]', $qname, 'sym' ),
             label( $ok_glob );
    } else {
        push @{$self->_onload},
             opcode( 'get_root_global', 'sym', '["main"]', $qname );
    }

    return if !defined $slot;

    push @{$self->_onload},
         opcode( 'getattribute', 'body', 'sym', "'body'" ),
         opcode( 'getattribute', 'slot', 'body', "'$slot'" ),
         opcode( 'unless_null', 'slot', $ok_slot ),
         @$bytecode,
         opcode( 'setattribute', 'body', "'$slot'", 'slot' ),
         label( $ok_slot );
}

sub _symbol {
    my( $self, $op ) = @_;

    my $symbol = _local_name;
    my $name = $op->{attributes}{name};
    my $slot = $op->{attributes}{slot};
    my $qname = sprintf "'%s'", $name;

    if( $slot == VALUE_GLOB ) {
        _add $self,
            local_pmc( $symbol ),
            opcode( 'get_root_global', $symbol, '["main"]', $qname );

        if( !$self->_global_allocated->{$name}{VALUE_GLOB()} ) {
            _add_global( $self, $name, undef );
            $self->_global_allocated->{$name}{VALUE_GLOB()} = 1;
        }
    } else {
        _add $self,
             local_pmc( $symbol ),
             opcode( 'get_root_global', $symbol, '["main"]', $qname ),
             opcode( 'getattribute', $symbol, $symbol, "'body'" ),
             opcode( 'getattribute', $symbol, $symbol,
                     "'$sigil_to_slot{$slot}'" );

        if( !$self->_global_allocated->{$name}{$slot} ) {
            _add_global( $self, $name, $sigil_to_slot{$slot},
                         [ literal( '  .make_undef(slot)' ) ] );
            $self->_global_allocated->{$name}{$slot} = 1;
        }
    }

    return $symbol;
}

sub _glob_slot {
    my( $self, $op ) = @_;

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'getattribute', $d,
                 _dispatch( $self, $op->{parameters}[0] ), "'body'" ),
         opcode( 'getattribute', $d, $d,
                 "'$sigil_to_slot{$op->{attributes}{slot}}'" );

    return $d;
}

sub _glob_slot_set {
    my( $self, $op ) = @_;

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'getattribute', $d,
                 _dispatch( $self, $op->{parameters}[0] ), "'body'" ),
         opcode( 'setattribute', $d,
                 "'$sigil_to_slot{$op->{attributes}{slot}}'",
                 _dispatch( $self, $op->{parameters}[1] ) );
}

sub _localize_glob_slot {
    my( $self, $op ) = @_;

    # FIXME de-duplicate!
    my $symbol = _local_name;
    my $name = $op->{attributes}{name};
    my $slot = $op->{attributes}{slot};
    my $qname = sprintf "'%s'", $name;

    # get typeglob
    _add $self,
         local_pmc( $symbol ),
         opcode( 'get_root_global', $symbol, '["main"]', $qname );

    if( !$self->_global_allocated->{$name}{VALUE_GLOB()} ) {
        _add_global( $self, $name, undef );
        $self->_global_allocated->{$name}{VALUE_GLOB()} = 1;
    }

    # get slot
    my $body = _local_name;
    my $slot_v = _local_name;
    _add $self,
         local_pmc( $body ),
         local_pmc( $slot_v ),
         opcode( 'getattribute', $body, $symbol, "'body'" ),
         opcode( 'getattribute', $slot_v, $body,
                 "'$sigil_to_slot{$op->{attributes}{slot}}'" );

    # localize
    my $value = _local_name;
    _add $self,
         local_pmc( $value ),
         literal( sprintf '  %s = %s."localize"()', $value, $slot_v );

    # save original value
    my $tmp = $self->_temp_map->{$op->{attributes}{index}} ||= _local_name;
    _add $self,
         local_pmc( $tmp ),
         opcode( 'set', $tmp, $slot_v );

    # set slot
    _add $self,
         opcode( 'setattribute', $body,
                 "'$sigil_to_slot{$op->{attributes}{slot}}'", $value );

    return $value;
}

sub _restore_glob_slot {
    my( $self, $op ) = @_;

    # FIXME de-duplicate!
    my $symbol = _local_name;
    my $name = $op->{attributes}{name};
    my $slot = $op->{attributes}{slot};
    my $qname = sprintf "'%s'", $name;

    # get typeglob
    _add $self,
         local_pmc( $symbol ),
         opcode( 'get_root_global', $symbol, '["main"]', $qname );

    if( !$self->_global_allocated->{$name}{VALUE_GLOB()} ) {
        _add_global( $self, $name, undef );
        $self->_global_allocated->{$name}{VALUE_GLOB()} = 1;
    }

    # get body
    my $body = _local_name;
    _add $self,
         local_pmc( $body ),
         opcode( 'getattribute', $body, $symbol, "'body'" );

    # restore value if saved
    my $tmp = $self->_temp_map->{$op->{attributes}{index}} ||= _local_name;
    my $if_null = _label_name;
    _add $self,
         local_pmc( $tmp ),
         opcode( 'if_null', $tmp, $if_null ),
         opcode( 'setattribute', $body,
                 "'$sigil_to_slot{$op->{attributes}{slot}}'", $tmp ),
         opcode( 'null', $tmp ),
         label( $if_null );
}

sub _array_element {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );
    my $r = _dispatch( $self, $op->{parameters}[1] );

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'set', $d, "$r\[$l\]" );

    return $d;
}

sub _iterator {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );

    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'new', $d, "'Iterator'", $l );

    return $d;
}

sub _iterator_next {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );

    my $d = _local_name;
    my $goto_end = _label_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'null', $d ),
         opcode( 'unless', $l, $goto_end ),
         opcode( 'shift', $d, $l ),
         label( $goto_end );

    return $d;
}

sub _lex_name {
    my( $self, $lex, $add_local ) = @_;

    return 'args' if $lex->name eq '_' && $lex->sigil == VALUE_ARRAY;

    return $self->_lexical_map->{$lex} ||= _local_name;
}

sub _lexical_set {
    my( $self, $op ) = @_;
    my $l = _dispatch( $self, $op->{parameters}[0] );

    my $d = _lex_name( $self, $op->{attributes}{lexical} );
    _add $self,
         local_pmc( $d ),
         opcode( 'set', $d, $l );

    return $d;
}

sub _lexical_clear {
    my( $self, $op ) = @_;

    my $d = _lex_name( $self, $op->{attributes}{lexical} );
    _add $self,
         opcode( 'null', $d );
}

sub _lexical {
    my( $self, $op ) = @_;

    return _lex_name( $self, $op->{attributes}{lexical} );
}

sub _get {
    my( $self, $op ) = @_;

    return $self->_temp_map->{$op->{parameters}[0]};
}

sub _set {
    my( $self, $op ) = @_;

    my $res = $self->_temp_map->{$op->{parameters}[0]} ||= _local_name;
    my $arg = _dispatch( $self, $op->{parameters}[1] );
    _add $self,
         local_pmc( $res ),
         literal( sprintf '  set %s, %s', $res, $arg );
}

sub _temporary_get {
    my( $self, $op ) = @_;

    return $self->_temp_map->{$op->{attributes}{index}};
}

sub _temporary_set {
    my( $self, $op ) = @_;

    my $res = $self->_temp_map->{$op->{attributes}{index}} ||= _local_name;
    my $arg = _dispatch( $self, $op->{parameters}[0] );
    _add $self,
         local_pmc( $res ),
         literal( sprintf '  set %s, %s', $res, $arg );
}

sub _fresh_string {
    my( $self, $op ) = @_;

    my $res = _local_name;
    _add $self,
         local_pmc( $res ),
         literal( sprintf '  .make_string(%s, "")', $res );

    return $res;
}

sub _call {
    my( $self, $op ) = @_;

    die "No 'make_list' as child"
        unless $op->{parameters}[0]->{opcode_n} == OP_MAKE_LIST;

    my $args = _create_list( $self, $op->{parameters}[0]->{parameters} );
    my $sub = _dispatch( $self, $op->{parameters}[1] );
    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         literal( sprintf '  %s = %s(%s, %s)', $d, $sub,
                          _context( $op ), $args );

    return $d;
}

sub _return {
    my( $self, $op ) = @_;

    my $args;
    if( $op->{parameters}[0]->{opcode_n} == OP_MAKE_LIST ) {
        $args = _create_list( $self, $op->{parameters}[0]->{parameters} );
    } elsif( $op->{parameters}[0]->{opcode_n} == OP_GET ) {
        $args = _get( $self, $op->{parameters}[0] );
    } else {
        die "Neither 'make_list' nor 'get' as child"
    }

    my( $scalar, $void, $list ) = ( _label_name, _label_name, _label_name );
    my( $not_empty ) = ( _label_name );
    my( $undef, $num ) = ( _local_name, _local_int_name );
    _add $self,
         opcode( 'eq_num', 'context', CXT_LIST, $list ),
         opcode( 'eq_num', 'context', CXT_VOID, $void ),
         # else fall through scalar

         label( $scalar ),
         opcode( 'set', $num, $args ),
         opcode( 'ne_num', $num, 0, $not_empty ),
         local_pmc( $undef ),
         literal( sprintf '  .make_undef(%s)', $undef ),
         opcode( 'set', "$args\[0]", $undef ),
         label( $not_empty ),
         opcode( 'set', $args, "$args\[0]" ),
         literal( sprintf '  .return (%s)', $args ),

         label( $void ),
         # empty the list
         opcode( 'assign', $args, 0 ),
         literal( sprintf '  .return (%s)', $args ),

         label( $list ),
         # do nothing
         literal( sprintf '  .return (%s)', $args );
}

sub _want {
    my( $self, $op ) = @_;

    my( $scalar, $void, $list, $end ) = ( _label_name, _label_name, _label_name,
                                          _label_name );
    my $d = _local_name;
    _add $self,
         local_pmc( $d ),
         opcode( 'eq_num', 'context', CXT_LIST, $list ),
         opcode( 'eq_num', 'context', CXT_VOID, $void ),
         # else fall through scalar

         label( $scalar ),
         literal( sprintf '  .make_string(%s, "")', $d ),
         opcode( 'goto', $end ),

         label( $void ),
         literal( sprintf '  .make_undef(%s)', $d ),
         opcode( 'goto', $end ),

         label( $list ),
         literal( sprintf '  .make_integer(%s, 1)', $d ),

         label( $end );

    return $d;
}

1;
