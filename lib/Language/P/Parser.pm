package Language::P::Parser;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Exporter 'import';

use Language::P::Lexer qw(:all);
use Language::P::ParseTree qw(:all);
use Language::P::Parser::Regex;
use Language::P::Parser::Lexicals;
use Language::P::Parser::Exception;
use Language::P::Keywords;
use Language::P::Opcodes qw(%OP_TO_KEYWORD);

our @EXPORT_OK = qw(PARSE_MAIN PARSE_ADD_RETURN);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

__PACKAGE__->mk_ro_accessors( qw(lexer generator runtime) );
__PACKAGE__->mk_accessors( qw(_lexicals _pending_lexicals
                              _in_declaration _lexical_state
                              _options) );

sub _lexical_sub_state { $_[0]->{_lexical_state}->[-1]->{sub} }

use constant
  { PREC_HIGHEST       => 0,
    PREC_NAMED_UNOP    => 10,
    PREC_TERNARY       => 18,
    PREC_TERNARY_COLON => 40,
    PREC_LISTEXPR      => 19,
    PREC_COMMA         => 20,
    PREC_LISTOP        => 21,
    PREC_LOWEST        => 50,

    BLOCK_OPEN_SCOPE      => 1,
    BLOCK_IMPLICIT_RETURN => 2,
    BLOCK_BARE            => 4,
    BLOCK_DO              => 8,
    BLOCK_EVAL            => 16,

    ASSOC_LEFT         => 1,
    ASSOC_RIGHT        => 2,
    ASSOC_NON          => 3,

    PARSE_ADD_RETURN   => 1,
    PARSE_MAIN         => 2,
    };

my %token_to_sigil =
  ( T_DOLLAR()    => VALUE_SCALAR,
    T_AT()        => VALUE_ARRAY,
    T_PERCENT()   => VALUE_HASH,
    T_STAR()      => VALUE_GLOB,
    T_AMPERSAND() => VALUE_SUB,
    T_ARYLEN()    => VALUE_ARRAY_LENGTH,
    );

my %declaration_to_flags =
  ( OP_MY()       => DECLARATION_MY,
    OP_OUR()      => DECLARATION_OUR,
    OP_STATE()    => DECLARATION_STATE,
    );

my %prec_assoc_bin =
  ( # T_ARROW()           => [ 2,  ASSOC_LEFT ],
    T_POWER()           => [ 4,  ASSOC_RIGHT, OP_POWER ],
    T_MATCH()           => [ 6,  ASSOC_LEFT,  OP_MATCH ],
    T_NOTMATCH()        => [ 6,  ASSOC_LEFT,  OP_NOT_MATCH ],
    T_STAR()            => [ 7,  ASSOC_LEFT,  OP_MULTIPLY ],
    T_SLASH()           => [ 7,  ASSOC_LEFT,  OP_DIVIDE ],
    T_PERCENT()         => [ 7,  ASSOC_LEFT,  OP_MODULUS ],
    T_SSTAR()           => [ 7,  ASSOC_LEFT,  OP_REPEAT ],
    T_PLUS()            => [ 8,  ASSOC_LEFT,  OP_ADD ],
    T_MINUS()           => [ 8,  ASSOC_LEFT,  OP_SUBTRACT ],
    T_DOT()             => [ 8,  ASSOC_LEFT,  OP_CONCATENATE ],
    T_SHIFT_LEFT()      => [ 9,  ASSOC_LEFT,  OP_SHIFT_LEFT ],
    T_SHIFT_RIGHT()     => [ 9,  ASSOC_LEFT,  OP_SHIFT_RIGHT ],
    T_OPAN()            => [ 11, ASSOC_NON,   OP_NUM_LT ],
    T_CLAN()            => [ 11, ASSOC_NON,   OP_NUM_GT ],
    T_LESSEQUAL()       => [ 11, ASSOC_NON,   OP_NUM_LE ],
    T_GREATEQUAL()      => [ 11, ASSOC_NON,   OP_NUM_GE ],
    T_SLESS()           => [ 11, ASSOC_NON,   OP_STR_LT ],
    T_SGREAT()          => [ 11, ASSOC_NON,   OP_STR_GT ],
    T_SLESSEQUAL()      => [ 11, ASSOC_NON,   OP_STR_LE ],
    T_SGREATEQUAL()     => [ 11, ASSOC_NON,   OP_STR_GE ],
    T_EQUALEQUAL()      => [ 12, ASSOC_NON,   OP_NUM_EQ ],
    T_NOTEQUAL()        => [ 12, ASSOC_NON,   OP_NUM_NE ],
    T_CMP()             => [ 12, ASSOC_NON,   OP_NUM_CMP ],
    T_SEQUALEQUAL()     => [ 12, ASSOC_NON,   OP_STR_EQ ],
    T_SNOTEQUAL()       => [ 12, ASSOC_NON,   OP_STR_NE ],
    T_SCMP()            => [ 12, ASSOC_NON,   OP_STR_CMP ],
    T_AMPERSAND()       => [ 13, ASSOC_LEFT,  OP_BIT_AND ],
    T_OR()              => [ 14, ASSOC_LEFT,  OP_BIT_OR ],
    T_XOR()             => [ 14, ASSOC_LEFT,  OP_BIT_XOR ],
    T_ANDAND()          => [ 15, ASSOC_LEFT,  OP_LOG_AND ],
    T_OROR()            => [ 16, ASSOC_LEFT,  OP_LOG_OR ],
    T_DOTDOT()          => [ 17, ASSOC_NON,   OP_DOT_DOT ],
    T_DOTDOTDOT()       => [ 17, ASSOC_NON,   OP_DOT_DOT_DOT ],
    T_INTERR()          => [ 18, ASSOC_RIGHT ], # ternary
    T_EQUAL()           => [ 19, ASSOC_RIGHT, OP_ASSIGN ],
    T_PLUSEQUAL()       => [ 19, ASSOC_RIGHT, OP_ADD_ASSIGN ],
    T_MINUSEQUAL()      => [ 19, ASSOC_RIGHT, OP_SUBTRACT_ASSIGN ],
    T_STAREQUAL()       => [ 19, ASSOC_RIGHT, OP_MULTIPLY_ASSIGN ],
    T_SLASHEQUAL()      => [ 19, ASSOC_RIGHT, OP_DIVIDE_ASSIGN ],
    T_DOTEQUAL()        => [ 19, ASSOC_RIGHT, OP_CONCATENATE_ASSIGN ],
    T_SSTAREQUAL()      => [ 19, ASSOC_RIGHT, OP_REPEAT_ASSIGN ],
    T_PERCENTEQUAL()    => [ 19, ASSOC_RIGHT, OP_MODULUS_ASSIGN ],
    T_POWEREQUAL()      => [ 19, ASSOC_RIGHT, OP_POWER_ASSIGN ],
    T_AMPERSANDEQUAL()  => [ 19, ASSOC_RIGHT, OP_BIT_AND_ASSIGN ],
    T_OREQUAL()         => [ 19, ASSOC_RIGHT, OP_BIT_OR_ASSIGN ],
    T_XOREQUAL()        => [ 19, ASSOC_RIGHT, OP_BIT_XOR_ASSIGN ],
    T_ANDANDEQUAL()     => [ 19, ASSOC_RIGHT, OP_LOG_AND_ASSIGN ],
    T_OROREQUAL()       => [ 19, ASSOC_RIGHT, OP_LOG_OR_ASSIGN ],
    T_COMMA()           => [ 20, ASSOC_LEFT ],
    # 21, list ops
    T_ANDANDLOW()       => [ 23, ASSOC_LEFT,  OP_LOG_AND ],
    T_ORORLOW()         => [ 24, ASSOC_LEFT,  OP_LOG_OR ],
    T_XORLOW()          => [ 24, ASSOC_LEFT,  OP_LOG_XOR ],
    T_COLON()           => [ 40, ASSOC_RIGHT ], # ternary, must be lowest,
    );

my %prec_assoc_un =
  ( T_PLUSPLUS()    => [ 3,  ASSOC_NON,   OP_PREINC ],
    T_MINUSMINUS()  => [ 3,  ASSOC_NON,   OP_PREDEC ],
    T_PLUS()        => [ 5,  ASSOC_RIGHT, OP_PLUS ],
    T_MINUS()       => [ 5,  ASSOC_RIGHT, OP_MINUS ],
    T_NOT()         => [ 5,  ASSOC_RIGHT, OP_LOG_NOT ],
    T_TILDE()       => [ 5,  ASSOC_RIGHT, OP_BIT_NOT ],
    T_BACKSLASH()   => [ 5,  ASSOC_RIGHT, OP_REFERENCE ],
    T_NOTLOW()      => [ 22, ASSOC_RIGHT, OP_LOG_NOT ],
    );

my %dereference_type =
  ( VALUE_SCALAR()       => OP_DEREFERENCE_SCALAR,
    VALUE_ARRAY()        => OP_DEREFERENCE_ARRAY,
    VALUE_HASH()         => OP_DEREFERENCE_HASH,
    VALUE_SUB()          => OP_DEREFERENCE_SUB,
    VALUE_GLOB()         => OP_DEREFERENCE_GLOB,
    VALUE_ARRAY_LENGTH() => OP_ARRAY_LENGTH,
    );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_options( {} ) unless $self->_options;

    return $self;
}

sub safe_instance {
    my( $self ) = @_;

    return $self unless $self->is_parsing || $self->generator->is_generating;
    return ref( $self )->new
               ( { _options  => { %{$self->{_options}} },
                   runtime   => $self->runtime,
                   generator => $self->generator->safe_instance,
                   } );
}

sub set_option {
    my( $self, $option, $value ) = @_;

    if( $option eq 'dump-parse-tree' ) {
        $self->_options->{$option} = 1;
    }

    return 0;
}

sub parse_string {
    my( $self, $string, $flags, $program_name, $lexical_state ) = @_;

    open my $fh, '<', \$string;

    $self->parse_stream( $fh, $program_name, $flags, $lexical_state );
}

sub parse_file {
    my( $self, $file, $flags ) = @_;

    open my $fh, '<', $file or
        throw Language::P::Exception
                  ( message => "Can't open perl script \"$file\": $!" );

    $self->parse_stream( $fh, $file, $flags );
}

sub parse_stream {
    my( $self, $stream, $filename, $flags, $lexical_state ) = @_;

    $self->{lexer} = Language::P::Lexer->new
                         ( { stream       => $stream,
                             file         => $filename,
                             runtime      => $self->runtime,
                             } );
    $self->{_lexical_state} = [];
    $self->_parse( $flags, $lexical_state );
}

sub set_hints {
    my( $self, $hints ) = @_;

    $self->{_lexical_state}[-1]{hints} = $hints;
    $self->{_lexical_state}[-1]{changed} |= CHANGED_HINTS;
}

sub set_warnings {
    my( $self, $warnings ) = @_;

    $self->{_lexical_state}[-1]{warnings} = $warnings;
    $self->{_lexical_state}[-1]{changed} |= CHANGED_WARNINGS;
}

sub _qualify {
    my( $self, $name, $type ) = @_;
    if( $type == T_FQ_ID ) {
        ( my $normalized = $name ) =~ s/^(?:::)?(?:main::)?//;
        return $normalized;
    }
    my $package = $self->{_lexical_state}[-1]{package};
    my $prefix = $package eq 'main' ? '' : $package . '::';
    return $prefix . $name;
}

my %default_state =
  ( package  => 'main',
    hints    => 0,
    warnings => undef,
    lexicals => undef,
    );

sub _parse {
    my( $self, $flags, $lexical_state ) = @_;
    $lexical_state ||= \%default_state;

    my $dumper;
    if(    $self->_options->{'dump-parse-tree'}
        && -f $self->lexer->file ) {
        require Language::P::ParseTree::DumpYAML;
        ( my $outfile = $self->lexer->file ) =~ s/(\.\w+)?$/.pt/;
        open my $out, '>', $outfile || die "Can't open '$outfile': $!";
        my $dumpyml = Language::P::ParseTree::DumpYAML->new;
        $dumper = sub {
            print $out $dumpyml->dump( $_[0] );
        };
    }

    $self->_pending_lexicals( [] );
    $self->_lexicals( $lexical_state->{lexicals} );
    $self->_enter_scope( $lexical_state->{lexicals} ? 1 : 0, 1 );
    $self->{_lexical_state}[-1]{package} = $lexical_state->{package};
    $self->{_lexical_state}[-1]{hints} = $lexical_state->{hints};
    $self->{_lexical_state}[-1]{warnings} = $lexical_state->{warnings};

    $self->generator->start_code_generation( { file_name => $self->lexer->file,
                                               } );
    my @lines;
    while( my $line = _parse_line( $self ) ) {
        $dumper->( $line ) if $dumper;
        if(    $line->isa( 'Language::P::ParseTree::NamedSubroutine' )
            || $line->isa( 'Language::P::ParseTree::Use' ) ) {
            $self->generator->process( $line );
        } elsif( !$line->is_empty ) {
            push @lines, $line;
        }
        my $lex_state = _lexical_state_node( $self );
        push @lines, $lex_state if $lex_state;
    }
    my $package = $self->{_lexical_state}[-1]{package};
    $self->_leave_scope;
    _lines_implicit_return( $self, \@lines ) if $flags & PARSE_ADD_RETURN;
    $self->generator->process( $_ ) foreach @lines;

    my $data = $self->lexer->data_handle;
    $self->generator->set_data_handle( $package, $data->[1] )
      if $data && ( ( $flags & PARSE_MAIN ) || $data->[0] eq 'DATA' );

    my $code = $self->generator->end_code_generation;

    return $code;
}

sub is_parsing {
    return $_[0]->{_lexical_state} && @{$_[0]->{_lexical_state}} ? 1 : 0;
}

sub _enter_scope {
    my( $self, $is_sub, $top_level ) = @_;

    push @{$self->{_lexical_state}}, { package  => undef,
                                       lexicals => $self->_lexicals,
                                       is_sub   => $is_sub,
                                       top_level=> $top_level,
                                       hints    => 0,
                                       warnings => undef,
                                       changed  => 0,
                                       };
    if( !$top_level ) {
        $self->{_lexical_state}[-1]{hints} = $self->{_lexical_state}[-2]{hints};
        $self->{_lexical_state}[-1]{warnings} = $self->{_lexical_state}[-2]{warnings};
        $self->{_lexical_state}[-1]{package} = $self->{_lexical_state}[-2]{package};
    }
    if( $is_sub || $top_level ) {
        $self->{_lexical_state}[-1]{sub} = { labels  => {},
                                             jumps   => [],
                                             };
    } elsif( @{$self->{_lexical_state}} > 1 ) {
        $self->{_lexical_state}[-1]{sub} = $self->{_lexical_state}[-2]{sub};
    }
    $self->_lexicals( Language::P::Parser::Lexicals->new
                          ( { outer         => $self->_lexicals,
                              is_subroutine => $is_sub || 0,
                              top_level     => $top_level,
                              } ) );
}

sub _leave_scope {
    my( $self ) = @_;

    my $state = pop @{$self->{_lexical_state}};
    $self->_lexicals( $state->{lexicals} );
    _patch_gotos( $self, $state ) if $state->{is_sub} || $state->{top_level};
}

sub _patch_gotos {
    my( $self, $state ) = @_;
    my $labels = $state->{sub}{labels};

    foreach my $goto ( @{$state->{sub}{jumps}} ) {
        if( $labels->{$goto->left} ) {
            $goto->set_attribute( 'target', $labels->{$goto->left}, 1 );
        }
    }
}

sub _parse_error {
    my( $self, $pos, $message, @args ) = @_;

    throw Language::P::Parser::Exception
        ( message  => sprintf( $message, @args ),
          position => $pos,
          );
}

sub _syntax_error {
    my( $self, $token ) = @_;
    my $message = sprintf "Unexpected token '%s' (%s)",
                          $token->[O_VALUE], $token->[O_TYPE];

    _parse_error( $self, $token->[O_POS], $message );
}

sub _lex_token {
    my( $self, $type, $value, $expect ) = @_;
    my $token = $self->lexer->lex( $expect || X_NOTHING );

    return if !$value && !$type;

    if(    ( $type && $type != $token->[O_TYPE] )
        || ( $value && $value eq $token->[O_VALUE] ) ) {
        _syntax_error( $self, $token );
    }

    return $token;
}

sub _lex_semicolon {
    my( $self ) = @_;
    my $token = $self->lexer->lex;

    if( $token->[O_TYPE] == T_EOF || $token->[O_TYPE] == T_SEMICOLON ) {
        return;
    } elsif( $token->[O_TYPE] == T_CLBRK ) {
        $self->lexer->unlex( $token );
        return;
    }

    _syntax_error( $self, $token );
}

my %special_sub = map { $_ => 1 }
  ( qw(AUTOLOAD DESTROY BEGIN UNITCHECK CHECK INIT END) );

sub _parse_line {
    my( $self ) = @_;
    my $label = $self->lexer->peek( X_STATE );

    if( $label->[O_TYPE] != T_LABEL ) {
        return _parse_line_rest( $self, 1 );
    } else {
        _lex_token( $self, T_LABEL );
        my $statement =    _parse_line_rest( $self, 0 )
                        || Language::P::ParseTree::Empty->new
                               ( { pos => $label->[O_POS] } );

        $statement->set_attribute( 'label', $label->[O_VALUE] );
        $self->_lexical_sub_state->{labels}{$label->[O_VALUE]} ||= $statement;

        return $statement;
    }
}

sub _parse_line_rest {
    my( $self, $no_empty ) = @_;
    my $token = $self->lexer->peek( X_STATE );
    my $tokidt = $token->[O_ID_TYPE];

    if( $token->[O_TYPE] == T_SEMICOLON ) {
        _lex_semicolon( $self );

        return $no_empty ? _parse_line_rest( $self, 1 ) : undef;
    } elsif( $token->[O_TYPE] == T_OPBRK ) {
        _lex_token( $self, T_OPBRK );

        return _parse_block_rest( $self, $token->[O_POS],
                                  BLOCK_OPEN_SCOPE|BLOCK_BARE );
    } elsif( $token->[O_TYPE] == T_ID && is_keyword( $tokidt ) ) {
        if( $tokidt == KEY_SUB ) {
            return _parse_sub( $self, 1 | 2, 0, $token->[O_POS] );
        } elsif( $tokidt == KEY_IF || $tokidt == KEY_UNLESS ) {
            return _parse_cond( $self );
        } elsif( $tokidt == KEY_WHILE || $tokidt == KEY_UNTIL ) {
            return _parse_while( $self );
        } elsif( $tokidt == KEY_FOR || $tokidt == KEY_FOREACH ) {
            return _parse_for( $self );
        } elsif( $tokidt == KEY_PACKAGE ) {
            _lex_token( $self, T_ID );
            my $id = $self->lexer->lex_identifier( 0 );
            _lex_semicolon( $self );

            $self->{_lexical_state}[-1]{package} = $id->[O_VALUE];
            $self->{_lexical_state}[-1]{changed} |= CHANGED_PACKAGE;

            return Language::P::ParseTree::Empty->new
                       ( { pos => $token->[O_POS] } );
        } elsif( $tokidt == KEY_USE || $tokidt == KEY_NO ) {
            _lex_token( $self );

            my $tok_ver = $self->lexer->lex_version;
            my $tok_id = $self->lexer->lex_alphabetic_identifier( 0 );
            my $package = $tok_id ? $tok_id->[2] : undef;

            if( $package && !$tok_ver ) {
                $tok_ver = $self->lexer->lex_version;
            }
            my $version = $tok_ver ? $tok_ver->[2] : undef;
            ( my $args, undef ) = _parse_arglist( $self, PREC_LOWEST, 0, 0 );

            return Language::P::ParseTree::Use->new
                       ( { package => $package,
                           version => $version,
                           import  => $args,
                           is_no   => $tokidt == KEY_NO ? 1 : 0,
                           pos     => $token->[O_POS],
                           } );
        } elsif(    $tokidt == OP_MY
                 || $tokidt == OP_OUR
                 || $tokidt == OP_STATE
                 || $tokidt == OP_GOTO
                 || $tokidt == OP_LAST
                 || $tokidt == OP_NEXT
                 || $tokidt == OP_REDO
                 || $tokidt == KEY_LOCAL ) {
            return _parse_sideff( $self );
        } elsif( $tokidt == KEY_DO ) {
            _lex_token( $self );
            return _parse_do( $self, $token );
        }
        _parse_error( $self, $token->[O_POS], "Unhandled keyword %s",
                      $token->[O_VALUE] );
    } elsif( $special_sub{$token->[O_VALUE]} ) {
        return _parse_sub( $self, 1, 1, $token->[O_POS] );
    } else {
        return _parse_sideff( $self );
    }

    _syntax_error( $self, $token );
}

sub _add_pending_lexicals {
    my( $self ) = @_;

    foreach my $lexical ( @{$self->_pending_lexicals} ) {
        $self->_lexicals->add_lexical( $lexical );
    }

    $self->_pending_lexicals( [] );
}

sub _lexical_state_node {
    my( $self, $force ) = @_;
    my $changed = $force ? CHANGED_ALL : $self->{_lexical_state}[-1]{changed};
    return unless $changed;

    my $node = Language::P::ParseTree::LexicalState->new
                   ( { hints    => $self->{_lexical_state}[-1]{hints},
                       warnings => $self->{_lexical_state}[-1]{warnings},
                       package  => $self->{_lexical_state}[-1]{package},
                       changed  => $changed,
                       } );

    $self->{_lexical_state}[-1]{changed} = 0;

    return $node;
}

sub _parse_sub {
    my( $self, $flags, $no_sub_token, $pos ) = @_;
    _lex_token( $self, T_ID ) unless $no_sub_token;
    my $name = $self->lexer->lex_alphabetic_identifier( 0 );
    my $fqname = $name ? _qualify( $self, $name->[O_VALUE], $name->[O_ID_TYPE] ) : undef;
    my( $proto, $next );

    if( $fqname ) {
        _parse_error( $self, $name->[O_POS], "Named sub not allowed" )
          unless $flags & 1;

        $next = $self->lexer->lex( X_BLOCK );
        if( $next->[O_TYPE] == T_OPPAR ) {
            $proto = _parse_sub_proto( $self );
            $next = $self->lexer->lex( X_BLOCK );
        }

        if( $next->[O_TYPE] == T_SEMICOLON ) {
            $self->generator->add_declaration( $fqname, $proto );

            return Language::P::ParseTree::SubroutineDeclaration->new
                       ( { name      => $fqname,
                           prototype => $proto,
                           pos       => $name->[O_POS],
                           } );
        } elsif( $next->[O_TYPE] != T_OPBRK ) {
            _syntax_error( $self, $next );
        }
    } else {
        $next = _lex_token( $self, T_OPBRK, undef, X_BLOCK );
        _parse_error( "Anonymous sub not allowed" )
          unless $flags & 2;
    }

    $self->_enter_scope( 1 );
    my $sub = $fqname ? Language::P::ParseTree::NamedSubroutine->new
                            ( { name      => $fqname,
                                prototype => $proto,
                                pos_s     => $pos,
                                } ) :
                        Language::P::ParseTree::AnonymousSubroutine->new
                            ( { pos_s     => $pos } );
    # add @_ to lexical scope
    $self->_lexicals->add_name( VALUE_ARRAY, '_' );
    my $lex_state = _lexical_state_node( $self, 1 );

    my $block = _parse_block_rest( $self, $next->[O_POS],
                                   BLOCK_IMPLICIT_RETURN );
    my $lines = $block->lines;
    # FIXME encapsulation
    $sub->{lines} = @$lines ? [ $lex_state, @$lines ] : $lines;
    $sub->{pos_e} = $block->pos_e;
    $sub->set_parent_for_all_childs;
    $self->_leave_scope;

    # add a subroutine declaration, the generator might
    # not create it until later
    if( $fqname ) {
        $self->generator->add_declaration( $fqname, $proto );
    }

    return $sub;
}

sub _parse_sub_proto {
    my( $self ) = @_;
    my $proto = $self->lexer->lex_proto_or_attr;
    my @proto = ( 0, 0, 0 );
    my $in_bracket = 0;
    my $saw_semicolon = 0;

    my $value = 0;
    while( length $$proto ) {
        $$proto =~ s/^;// and do {
            $saw_semicolon = 1;
            $proto[0] = $#proto - 2;
        };
        $$proto =~ s/^\\\[// and do {
            $in_bracket = 1;
            $value = PROTO_REFERENCE;
        };
        $$proto =~ s/^\]// and do {
            $in_bracket = 0;
            push @proto, $value;
            next;
        };
        $$proto =~ s/^\\// and do {
            $value = PROTO_REFERENCE;
        };
        $$proto =~ s/^([\$\@\%\&\*])// and do {
            if( $1 eq '$' ) {
                $value |= PROTO_SCALAR;
            } elsif( $1 eq '@' ) {
                $value |= PROTO_ARRAY;
            } elsif( $1 eq '%' ) {
                $value |= PROTO_HASH;
            } elsif( $1 eq '*' ) {
                $value |= PROTO_GLOB;
            } elsif( $1 eq '&' ) {
                $value |= PROTO_SUB;
                if( $#proto == 2 ) {
                    $proto[2] |= PROTO_SUB;
                }
            }
        };
        if( !$value ) {
            substr $$proto, 0, 1, '';
        }
        next if $in_bracket;
        push @proto, $value;
        if( $value == PROTO_ARRAY || $value == PROTO_HASH ) {
            $proto[1] = -1;
            last;
        }
        ++$proto[0] unless $saw_semicolon;
        ++$proto[1];
        $value = 0;
    }

    return \@proto;
}

sub _parse_cond {
    my( $self ) = @_;
    my $cond = _lex_token( $self, T_ID );

    _lex_token( $self, T_OPPAR );

    $self->_enter_scope;
    my $expr = _parse_expr( $self );
    $self->_add_pending_lexicals;

    _lex_token( $self, T_CLPAR );
    my $brack = _lex_token( $self, T_OPBRK, undef, X_BLOCK );

    my $block = _parse_block_rest( $self, $brack->[O_POS], BLOCK_OPEN_SCOPE );

    my $if = Language::P::ParseTree::Conditional->new
                 ( { iftrues => [ Language::P::ParseTree::ConditionalBlock->new
                                      ( { block_type => $cond->[O_VALUE],
                                          condition  => $expr,
                                          block      => $block,
                                          pos_s      => $cond->[O_POS],
                                          pos_e      => $block->pos_e,
                                          } )
                                  ],
                     pos_s   => $cond->[O_POS],
                     } );

    for(;;) {
        my $else = $self->lexer->peek( X_STATE );
        last if    $else->[O_TYPE] != T_ID
                || ( $else->[O_ID_TYPE] != KEY_ELSE && $else->[O_ID_TYPE] != KEY_ELSIF );
        _lex_token( $self );

        my $expr;
        if( $else->[O_ID_TYPE] == KEY_ELSIF ) {
            _lex_token( $self, T_OPPAR );
            $expr = _parse_expr( $self );
            _lex_token( $self, T_CLPAR );
        }
        my $brack = _lex_token( $self, T_OPBRK, undef, X_BLOCK );
        my $block = _parse_block_rest( $self, $brack->[O_POS],
                                       BLOCK_OPEN_SCOPE );

        if( $expr ) {
            # FIXME encapsulation
            push @{$if->iftrues}, Language::P::ParseTree::ConditionalBlock->new
                                      ( { block_type => 'if',
                                          condition  => $expr,
                                          block      => $block,
                                          pos_s      => $else->[O_POS],
                                          pos_e      => $block->pos_e,
                                          } );
            $if->{pos_e} = $block->pos_e;
        } else {
            # FIXME encapsulation
            $if->{iffalse} = Language::P::ParseTree::ConditionalBlock->new
                                      ( { block_type => 'else',
                                          condition  => undef,
                                          block      => $block,
                                          pos_s      => $else->[O_POS],
                                          pos_e      => $block->pos_e,
                                          } );
            $if->{pos_e} = $block->pos_e;
        }
    }

    $if->set_parent_for_all_childs;
    $self->_leave_scope;

    return $if;
}

sub _parse_for {
    my( $self ) = @_;
    my $keyword = _lex_token( $self, T_ID );
    my $token = $self->lexer->lex( X_NOTHING );
    my( $foreach_var, $foreach_expr );

    $self->_enter_scope;

    if( $token->[O_TYPE] == T_OPPAR ) {
        my $expr = _parse_expr( $self );
        my $sep = $self->lexer->lex( X_OPERATOR );

        if( $sep->[O_TYPE] == T_CLPAR ) {
            $foreach_var = _find_symbol( $self, $token->[O_POS],
                                         VALUE_SCALAR, '_', T_FQ_ID );
            $foreach_expr = $expr;
        } elsif( $sep->[O_TYPE] == T_SEMICOLON ) {
            # C-style for
            $self->_add_pending_lexicals;

            my $cond = _parse_expr( $self );
            _lex_token( $self, T_SEMICOLON );
            $self->_add_pending_lexicals;

            my $incr = _parse_expr( $self );
            _lex_token( $self, T_CLPAR );
            $self->_add_pending_lexicals;

            my $brack = _lex_token( $self, T_OPBRK, undef, X_BLOCK );
            my $block = _parse_block_rest( $self, $brack->[O_POS],
                                           BLOCK_OPEN_SCOPE );

            my $for = Language::P::ParseTree::For->new
                          ( { block_type  => 'for',
                              initializer => $expr,
                              condition   => $cond,
                              step        => $incr,
                              block       => $block,
                              pos_s       => $keyword->[O_POS],
                              pos_e       => $block->pos_e,
                              } );

            $self->_leave_scope;

            return $for;
        } else {
            _syntax_error( $self, $sep );
        }
    } elsif( $token->[O_TYPE] == T_ID && (    $token->[O_ID_TYPE] == OP_MY
                                           || $token->[O_ID_TYPE] == OP_OUR
                                           || $token->[O_ID_TYPE] == OP_STATE ) ) {
        _lex_token( $self, T_DOLLAR );
        my $name = $self->lexer->lex_identifier( 0 );
        _parse_error( $self, $token->[O_POS],
                      "Could not parse identifier name in for" )
          unless $name;

        # all the special handling for our() is done by _process_declaration
        $foreach_var = Language::P::ParseTree::Symbol->new
                           ( { name    => $name->[O_VALUE],
                               sigil   => VALUE_SCALAR,
                               pos     => $name->[O_POS],
                               } );
        $foreach_var = _process_declaration( $self, $foreach_var,
                                             $token->[O_ID_TYPE] );
    } elsif( $token->[O_TYPE] == T_DOLLAR ) {
        my $id = $self->lexer->lex_identifier( 0 );
        $foreach_var = _find_symbol( $self, $token->[O_POS], VALUE_SCALAR,
                                     $id->[O_VALUE], $id->[O_ID_TYPE] );
    } else {
        _syntax_error( $self, $token );
    }

    # if we get there it is not C-style for
    if( !$foreach_expr ) {
        _lex_token( $self, T_OPPAR );
        $foreach_expr = _parse_expr( $self );
        _lex_token( $self, T_CLPAR );
    }

    $self->_add_pending_lexicals;
    my $brack = _lex_token( $self, T_OPBRK, undef, X_BLOCK );

    my $block = _parse_block_rest( $self, $brack->[O_POS], BLOCK_OPEN_SCOPE );
    my $continue = _parse_continue( $self );
    my $for = Language::P::ParseTree::Foreach->new
                  ( { expression => $foreach_expr,
                      block      => $block,
                      variable   => $foreach_var,
                      continue   => $continue,
                      pos_s      => $keyword->[O_POS],
                      pos_e      => $block->pos_e,
                      } );

    $self->_leave_scope;

    return $for;
}

sub _parse_while {
    my( $self ) = @_;
    my $keyword = _lex_token( $self, T_ID );

    _lex_token( $self, T_OPPAR );

    $self->_enter_scope;
    my $expr = _parse_expr( $self );
    $self->_add_pending_lexicals;

    _lex_token( $self, T_CLPAR );
    my $brack = _lex_token( $self, T_OPBRK, undef, X_BLOCK );

    my $block = _parse_block_rest( $self, $brack->[O_POS], BLOCK_OPEN_SCOPE );
    my $continue = _parse_continue( $self );
    my $while = Language::P::ParseTree::ConditionalLoop
                    ->new( { condition  => $expr,
                             block      => $block,
                             block_type => $keyword->[O_VALUE],
                             continue   => $continue,
                             pos_s      => $keyword->[O_POS],
                             pos_e      => $block->pos_e,
                             } );

    $self->_leave_scope;

    return $while;
}

sub _parse_continue {
    my( $self ) = @_;
    my $token = $self->lexer->peek( X_STATE );
    return unless $token->[O_TYPE] == T_ID && $token->[O_ID_TYPE] == KEY_CONTINUE;

    _lex_token( $self, T_ID );
    my $brack = _lex_token( $self, T_OPBRK, undef, X_BLOCK );

    return _parse_block_rest( $self, $brack->[O_POS], BLOCK_OPEN_SCOPE );
}

sub _parse_statement_modifier {
    my( $self, $expr ) = @_;
    my $keyword = $self->lexer->peek( X_TERM );

    if( $keyword->[O_TYPE] == T_ID && is_keyword( $keyword->[O_ID_TYPE] ) ) {
        my $keyidt = $keyword->[O_ID_TYPE];

        if( $keyidt == KEY_IF || $keyidt == KEY_UNLESS ) {
            _lex_token( $self, T_ID );
            my $cond = _parse_expr( $self );

            $expr = Language::P::ParseTree::Conditional->new
                        ( { iftrues => [ Language::P::ParseTree::ConditionalBlock->new
                                             ( { block_type => $keyword->[O_VALUE],
                                                 condition  => $cond,
                                                 block      => $expr,
                                                 pos_s      => $keyword->[O_POS],
                                                 pos_e      => $expr->pos_e,
                                                 } )
                                         ],
                            } );
        } elsif( $keyidt == KEY_WHILE || $keyidt == KEY_UNTIL ) {
            _lex_token( $self, T_ID );
            my $cond = _parse_expr( $self );

            $expr = Language::P::ParseTree::ConditionalLoop->new
                        ( { condition  => $cond,
                            block      => $expr,
                            block_type => $keyword->[O_VALUE],
                            pos_s      => $keyword->[O_POS],
                            pos_e      => $expr->pos_e,
                            } );
        } elsif( $keyidt == KEY_FOR || $keyidt == KEY_FOREACH ) {
            _lex_token( $self, T_ID );
            my $cond = _parse_expr( $self );

            $expr = Language::P::ParseTree::Foreach->new
                        ( { expression => $cond,
                            block      => $expr,
                            variable   => _find_symbol( $self, undef, VALUE_SCALAR, '_', T_FQ_ID ),
                            pos_s      => $keyword->[O_POS],
                            pos_e      => $expr->pos_e,
                            } );
        }
    }

    return $expr;
}

sub _parse_sideff {
    my( $self ) = @_;
    my $expr = _parse_expr( $self );
    $expr = _parse_statement_modifier( $self, $expr );

    _lex_semicolon( $self );
    $self->_add_pending_lexicals;

    return $expr;
}

sub _parse_expr {
    my( $self ) = @_;

    return _parse_term( $self, PREC_LOWEST );
}

sub _find_lexical {
    my( $self, $sigil, $name ) = @_;
    my( $level, $lex ) = $self->_lexicals->find_name( $sigil . "\0" . $name );

    if( $lex ) {
        if( $lex->isa( 'Language::P::ParseTree::Symbol' ) ) {
            return Language::P::ParseTree::Symbol->new
                       ( { name  => $lex->name,
                           sigil => $lex->sigil,
                           pos   => $lex->pos,
                           } );
        }

        $lex->set_closed_over if $level > 0;

        return Language::P::ParseTree::LexicalSymbol->new
                   ( { declaration => $lex,
                       level       => $level,
                       pos         => $lex->pos,
                       } );
    }

    return undef;
}

sub _find_symbol {
    my( $self, $pos, $sigil, $name, $type ) = @_;

    if( $self->_in_declaration ) {
        return Language::P::ParseTree::Symbol->new
                   ( { name  => $name,
                       sigil => $sigil,
                       pos   => $pos,
                       } );
    } elsif( $type == T_FQ_ID ) {
        return Language::P::ParseTree::Symbol->new
                   ( { name  => _qualify( $self, $name, $type ),
                       sigil => $sigil,
                       pos   => $pos,
                       } );
    }
    my $lex = _find_lexical( $self, $sigil, $name );
    return $lex if $lex;

    if( $self->{_lexical_state}[-1]{hints} & 0x00000400 ) {
        _parse_error( $self, $pos,
                      "Global symbol %s requires explicit package name",
                      $name );
    }

    return Language::P::ParseTree::Symbol->new
               ( { name  => _qualify( $self, $name, $type ),
                   sigil => $sigil,
                   pos   => $pos,
                   } );
}

sub _parse_maybe_subscript_rest {
    my( $self, $subscripted, $arrow_only ) = @_;
    my $next = $self->lexer->peek( X_OPERATOR );

    # array/hash element
    if( $next->[O_TYPE] == T_ARROW ) {
        _lex_token( $self, T_ARROW );
        my $bracket = $self->lexer->peek( X_METHOD_SUBSCRIPT );

        if(    $bracket->[O_TYPE] == T_OPPAR
            || $bracket->[O_TYPE] == T_OPSQ
            || $bracket->[O_TYPE] == T_OPBRK ) {
            return _parse_dereference_rest( $self, $subscripted, $bracket );
        } else {
            return _parse_maybe_direct_method_call( $self, $subscripted );
        }
    } elsif( $arrow_only ) {
        return $subscripted;
    } elsif(    $next->[O_TYPE] == T_OPPAR
             || $next->[O_TYPE] == T_OPSQ
             || $next->[O_TYPE] == T_OPBRK ) {
        return _parse_dereference_rest( $self, $subscripted, $next );
    } else {
        return $subscripted;
    }
}

sub _parse_indirect_function_call {
    my( $self, $subscripted, $with_arguments, $ampersand ) = @_;

    my $args;
    if( $with_arguments ) {
        _lex_token( $self, T_OPPAR );
        ( $args, undef ) = _parse_arglist( $self, PREC_LOWEST, 0, 0 );
        _lex_token( $self, T_CLPAR );
    }

    # $foo->() requires an additional dereference, while
    # &{...}(...) does not construct a reference but might need it
    if( !$subscripted->is_symbol || $subscripted->sigil != VALUE_SUB ) {
        $subscripted = Language::P::ParseTree::Dereference->new
                           ( { left => $subscripted,
                               op   => OP_DEREFERENCE_SUB,
                               pos  => $subscripted->pos,
                               } );
    }

    # treat &foo; separately from all other cases
    if( $ampersand && !$with_arguments ) {
        return Language::P::ParseTree::SpecialFunctionCall->new
                   ( { function    => $subscripted,
                       flags       => FLAG_IMPLICITARGUMENTS,
                       pos         => $subscripted->pos,
                       } );
    } else {
        return Language::P::ParseTree::FunctionCall->new
                   ( { function    => $subscripted,
                       arguments   => $args,
                       pos         => $subscripted->pos,
                       } );
    }
}

sub _parse_dereference_rest {
    my( $self, $subscripted, $bracket ) = @_;
    my $term;

    if( $bracket->[O_TYPE] == T_OPPAR ) {
        $term = _parse_indirect_function_call( $self, $subscripted, 1, 0 );
    } else {
        my $subscript = _parse_bracketed_expr( $self, $bracket->[O_TYPE], 0 );
        $term = Language::P::ParseTree::Subscript->new
                    ( { subscripted => $subscripted,
                        subscript   => $subscript,
                        type        => $bracket->[O_TYPE] == T_OPBRK ?
                                           VALUE_HASH : VALUE_ARRAY,
                        reference   => 1,
                        pos         => $subscripted->pos,
                        } );
    }

    return _parse_maybe_subscript_rest( $self, $term );
}

sub _parse_bracketed_expr {
    my( $self, $bracket, $allow_empty, $no_consume_opening ) = @_;
    my $close = $bracket == T_OPBRK ? T_CLBRK :
                $bracket == T_OPSQ  ? T_CLSQ :
                                      T_CLPAR;

    _lex_token( $self, $bracket ) unless $no_consume_opening;
    if( $allow_empty ) {
        my $next = $self->lexer->peek( X_TERM );
        if( $next->[O_TYPE] == $close ) {
            _lex_token( $self, $close );
            return undef;
        }
    }
    my $subscript = _parse_expr( $self );
    _lex_token( $self, $close );

    return $subscript;
}

sub _parse_maybe_indirect_method_call {
    my( $self, $op, $next ) = @_;
    my $indir = _parse_indirobj( $self, 1 );

    if( $indir ) {
        # if FH -> no method
        # proto FH -> no method
        # Foo $bar (?) -> no method
        # foo $bar -> method

        # print xxx -> no method, but print is handled before getting
        # there, since it is a non-overridable builtin

        # foo pack:: -> method

        # use Data::Dumper;
        # print Dumper( $indir ) . ' ' . Dumper( $next );

        my $args = _parse_term( $self, PREC_COMMA );
        if( $args ) {
            if( $args->isa( 'Language::P::ParseTree::List' ) ) {
	        $args = @{$args->expressions} ? $args->expressions : undef;
            } else {
                $args = [ $args ];
            }
        }
        $indir = Language::P::ParseTree::Constant->new
                     ( { flags => CONST_STRING,
                         value => $indir->[O_VALUE],
                         pos   => $indir->[O_POS],
                         } )
            if ref( $indir ) eq 'ARRAY';
        my $term = Language::P::ParseTree::MethodCall->new
                       ( { invocant  => $indir,
                           method    => $op->[O_VALUE],
                           arguments => $args,
                           indirect  => 0,
                           pos       => $op->[O_POS],
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    }

    return Language::P::ParseTree::Constant->new
               ( { value => $op->[O_VALUE],
                   flags => CONST_STRING|STRING_BARE,
                   pos   => $op->[O_POS],
                   } );
}

sub _parse_maybe_direct_method_call {
    my( $self, $invocant ) = @_;
    my $token = $self->lexer->lex( X_TERM );
    my( $method, $indirect );

    if( $token->[O_TYPE] == T_ID ) {
        ( $method, $indirect ) = ( $token->[O_VALUE], 0 );
    } elsif( $token->[O_TYPE] == T_DOLLAR ) {
        my $id = $self->lexer->lex_identifier( 0 );
        $method = _find_symbol( $self, $token->[O_POS], VALUE_SCALAR,
                                $id->[O_VALUE], $id->[O_ID_TYPE] );
        $indirect = 1;
    } else {
        _syntax_error( $self, $token );
    }

    my $oppar = $self->lexer->peek( X_OPERATOR );
    my $args;
    if( $oppar->[O_TYPE] == T_OPPAR ) {
        _lex_token( $self, T_OPPAR );
        ( $args ) = _parse_arglist( $self, PREC_LOWEST, 0, 0 );
        _lex_token( $self, T_CLPAR );
    }

    my $term = Language::P::ParseTree::MethodCall->new
                   ( { invocant  => $invocant,
                       method    => $method,
                       arguments => $args,
                       indirect  => $indirect,
                       pos       => $invocant->pos,
                       } );

    return _parse_maybe_subscript_rest( $self, $term );
}

sub _parse_match {
    my( $self, $token ) = @_;

    if( $token->[O_RX_INTERPOLATED] ) {
        my $string = _parse_string_rest( $self, $token, 1 );
        my $match = Language::P::ParseTree::InterpolatedPattern->new
                        ( { string     => $string,
                            op         => $token->[O_VALUE],
                            flags      => $token->[O_RX_FLAGS],
                            pos        => $token->[O_POS],
                            } );

        return $match;
    } else {
        my $parts = Language::P::Parser::Regex->new
                        ( { generator   => $self->generator,
                            runtime     => $self->runtime,
                            interpolate => $token->[O_QS_INTERPOLATE],
                            flags       => $token->[O_RX_FLAGS],
                            } )->parse_string( $token->[O_QS_BUFFER] );
        my $match = Language::P::ParseTree::Pattern->new
                        ( { components => $parts,
                            op         => $token->[O_VALUE],
                            flags      => $token->[O_RX_FLAGS],
                            pos        => $token->[O_POS],
                            } );

        return $match;
    }
}

sub _parse_substitution {
    my( $self, $token ) = @_;
    my $match = _parse_match( $self, $token );

    my $replace;
    if( $match->flags & FLAG_RX_EVAL ) {
        local $self->{lexer} = Language::P::Lexer->new
                                   ( { string       => $token->[O_RX_SECOND_HALF]->[O_QS_BUFFER],
                                       file         => $match->pos->[0],
                                       line         => $match->pos->[1],
                                       runtime      => $self->runtime,
                                       _heredoc_lexer => $self->lexer,
                                       } );
        $replace = _parse_block_rest( $self, undef, BLOCK_OPEN_SCOPE, T_EOF );
    } else {
        $replace = _parse_string_rest( $self, $token->[O_RX_SECOND_HALF], 0, 1 );
    }

    my $sub = Language::P::ParseTree::Substitution->new
                  ( { pattern     => $match,
                      replacement => $replace,
                      pos         => $match->pos,
                      } );

    return $sub;
}

sub _parse_string_rest {
    my( $self, $token, $pattern, $substitution ) = @_;
    my @values;
    local $self->{lexer} = Language::P::Lexer->new
                               ( { string       => $token->[O_QS_BUFFER],
                                   file         => $token->[O_POS][0],
                                   line         => $token->[O_POS][1],
                                   runtime      => $self->runtime,
                                   } );

    $self->lexer->quote( { interpolate          => $token->[O_QS_INTERPOLATE],
                           pattern              => 0,
                           substitution         => $substitution,
                           interpolated_pattern => $pattern,
                           } );
    for(;;) {
        my $value = $self->lexer->lex_quote;

        if( $value->[O_TYPE] == T_STRING ) {
            push @values, Language::P::ParseTree::Constant->new
                              ( { flags => CONST_STRING,
                                  value => $value->[O_VALUE],
                                  pos   => $value->[O_POS],
                                  } );
        } elsif( $value->[O_TYPE] == T_EOF ) {
            last;
        } elsif(    $value->[O_TYPE] == T_DOLLAR
                 || $value->[O_TYPE] == T_AT
                 || $value->[O_TYPE] == T_ARYLEN ) {
            push @values, _parse_indirobj_maybe_subscripts( $self, $value );
        } else {
            _syntax_error( $self, $value );
        }
    }

    $self->lexer->quote( undef );

    my $string;
    if( @values == 1 && $values[0]->is_constant ) {
        $string = $values[0];
    } elsif( @values == 0 ) {
        $string = Language::P::ParseTree::Constant->new
                      ( { value => "",
                          flags => CONST_STRING,
                          pos   => $token->[O_POS],
                          } );
    } else {
        $string = Language::P::ParseTree::QuotedString->new
                      ( { components => \@values,
                          pos        => $token->[O_POS],
                          } );
    }

    my $quote = $token->[O_VALUE];
    if( $quote == OP_QL_QX ) {
        $string = Language::P::ParseTree::UnOp->new
                      ( { op   => OP_BACKTICK,
                          left => $string,
                          pos  => $token->[O_POS],
                          } );
    } elsif( $quote == OP_QL_QW ) {
        my @words = map Language::P::ParseTree::Constant->new
                            ( { value => $_,
                                flags => CONST_STRING,
                                } ),
                        split /[\s\r\n]+/, $string->value;

        $string = Language::P::ParseTree::List->new
                      ( { expressions => \@words,
                          pos         => $string->pos,
                          } );
    }

    return $string;
}

sub _parse_term_terminal {
    my( $self, $token, $is_bind ) = @_;

    if( $token->[O_TYPE] == T_QUOTE ) {
        my $qstring = _parse_string_rest( $self, $token, 0 );

        if( $token->[O_VALUE] == OP_QL_LT ) {
            # simple scalar: readline, anything else: glob
            if(    $qstring->isa( 'Language::P::ParseTree::QuotedString' )
                && $#{$qstring->components} == 0
                && $qstring->components->[0]->is_symbol ) {
                return Language::P::ParseTree::Overridable
                           ->new( { function  => OP_READLINE,
                                    arguments => [ $qstring->components->[0] ],
                                    pos       => $token->[O_POS],
                                    } );
            } elsif( $qstring->is_constant ) {
                if( $qstring->value =~ /^[a-zA-Z_]/ ) {
                    # FIXME simpler method, make lex_identifier static
                    my $lexer = Language::P::Lexer->new
                                    ( { string => $qstring->value,
                                        file   => $token->[O_POS][0],
                                        line   => $token->[O_POS][1],
                                        } );
                    my $id = $lexer->lex_identifier( 0 );

                    if( $id && !length( ${$lexer->buffer} ) ) {
                        my $glob = Language::P::ParseTree::Symbol->new
                                       ( { name  => _qualify( $self, $id->[O_VALUE], $id->[O_ID_TYPE] ),
                                           sigil => VALUE_GLOB,
                                           } );
                        return Language::P::ParseTree::Overridable
                                   ->new( { function  => OP_READLINE,
                                            arguments => [ $glob ],
                                            pos       => $token->[O_POS],
                                            } );
                    }
                }
                return Language::P::ParseTree::Glob
                           ->new( { arguments => [ $qstring ],
                                    pos       => $token->[O_POS],
                                    } );
            } else {
                return Language::P::ParseTree::Glob
                           ->new( { arguments => [ $qstring ],
                                    pos       => $token->[O_POS],
                                    } );
            }
        }

        return $qstring;
    } elsif( $token->[O_TYPE] == T_PATTERN ) {
        my $pattern;
        if( $token->[O_VALUE] == OP_QL_M || $token->[O_VALUE] == OP_QL_QR ) {
            $pattern = _parse_match( $self, $token );
        } elsif( $token->[O_VALUE] == OP_QL_S ) {
            $pattern = _parse_substitution( $self, $token );
        } else {
            _parse_error( $self, $token->[O_POS], "Unknown pattern" );
        }

        if( !$is_bind && $token->[O_VALUE] != OP_QL_QR ) {
            $pattern = Language::P::ParseTree::BinOp->new
                           ( { op    => OP_MATCH,
                               left  => _find_symbol( $self, $token->[O_POS],
                                                      VALUE_SCALAR, '_', T_FQ_ID ),
                               right => $pattern,
                               pos   => $token->[O_POS],
                               } );
        }

        return $pattern;
    } elsif( $token->[O_TYPE] == T_NUMBER ) {
        return Language::P::ParseTree::Constant->new
                   ( { value => $token->[O_VALUE],
                       flags => $token->[O_NUM_FLAGS]|CONST_NUMBER,
                       pos   => $token->[O_POS],
                       } );
    } elsif( $token->[O_TYPE] == T_PACKAGE ) {
        return Language::P::ParseTree::Constant->new
                   ( { value => $self->{_lexical_state}[-1]{package},
                       flags => CONST_STRING,
                       pos   => $token->[O_POS],
                       } );
    } elsif( $token->[O_TYPE] == T_STRING ) {
        return Language::P::ParseTree::Constant->new
                   ( { value => $token->[O_VALUE],
                       flags => CONST_STRING,
                       pos   => $token->[O_POS],
                       } );
    } elsif(    $token->[O_TYPE] == T_DOLLAR
             || $token->[O_TYPE] == T_AT
             || $token->[O_TYPE] == T_PERCENT
             || $token->[O_TYPE] == T_STAR
             || $token->[O_TYPE] == T_AMPERSAND
             || $token->[O_TYPE] == T_ARYLEN ) {
        return ( _parse_indirobj_maybe_subscripts( $self, $token ), 1 );
    } elsif(    $token->[O_TYPE] == T_ID ) {
        my $tokidt = $token->[O_ID_TYPE];

        if( $token->[O_ID_TYPE] == KEY_EVAL ) {
            return _parse_eval( $self, $token );
        } elsif( $token->[O_ID_TYPE] == KEY_REQUIRE_FILE ) {
            my $tree = _parse_listop( $self, $token );

            if(    $tree->arguments->[0]->is_constant
                && $tree->arguments->[0]->is_bareword ) {
                my $file = $tree->arguments->[0]->value;
                # FIXME add 'split_package' or similar
                $file =~ s{::}{/}g;

                return Language::P::ParseTree::Builtin->new
                           ( { function  => OP_REQUIRE_FILE,
                               arguments =>
                                   [ Language::P::ParseTree::Constant->new
                                         ( { value => $file . ".pm",
                                             flags => CONST_STRING,
                                             } ) ],
                               pos       => $token->[O_POS],
                               } );
            }

            return $tree;
        } elsif( !is_keyword( $token->[O_ID_TYPE] ) ) {
            return _parse_listop( $self, $token );
        } elsif(    $tokidt == OP_MY
                 || $tokidt == OP_OUR
                 || $tokidt == OP_STATE ) {
            return _parse_lexical( $self, $token->[O_ID_TYPE] );
        } elsif( $tokidt == KEY_SUB ) {
            return _parse_sub( $self, 2, 1, $token->[O_POS] );
        } elsif(    $tokidt == OP_GOTO
                 || $tokidt == OP_LAST
                 || $tokidt == OP_NEXT
                 || $tokidt == OP_REDO ) {
            my $id = $self->lexer->lex;
            my $dest;
            if( $id->[O_TYPE] == T_ID && $id->[O_ID_TYPE] == T_ID ) {
                $dest = $id->[O_VALUE];
            } else {
                $self->lexer->unlex( $id );
                $dest = _parse_term( $self, PREC_LOWEST );
                if( $dest ) {
                    $dest = $dest->left
                        if $dest->isa( 'Language::P::ParseTree::Parentheses' );
                    $dest = $dest->value if $dest->is_constant;
                }
            }

            my $jump = Language::P::ParseTree::Jump->new
                           ( { op   => $tokidt,
                               left => $dest,
                               pos  => $token->[O_POS],
                               } );
            push @{$self->_lexical_state->[-1]{sub}{jumps}}, $jump
              if $tokidt == OP_GOTO && !ref( $dest );

            return $jump;
        } elsif( $tokidt == KEY_LOCAL ) {
            return Language::P::ParseTree::Local->new
                       ( { left => _parse_term_list_if_parens( $self, PREC_NAMED_UNOP ),
                           pos  => $token->[O_POS],
                           } );
        } elsif( $tokidt == KEY_DO ) {
            return _parse_do( $self, $token );
        }
    } elsif( $token->[O_TYPE] == T_OPHASH ) {
        my $expr = _parse_bracketed_expr( $self, T_OPBRK, 1, 1 );

        return Language::P::ParseTree::ReferenceConstructor->new
                   ( { expression => $expr,
                       type       => VALUE_HASH,
                       pos        => $token->[O_POS],
                       } );
    } elsif( $token->[O_TYPE] == T_OPSQ ) {
        my $expr = _parse_bracketed_expr( $self, T_OPSQ, 1, 1 );

        return Language::P::ParseTree::ReferenceConstructor->new
                   ( { expression => $expr,
                       type       => VALUE_ARRAY,
                       pos        => $token->[O_POS],
                       } );
    }

    return undef;
}

sub _parse_term_terminal_maybe_subscripts {
    my( $self, $token, $is_bind ) = @_;
    my( $term, $no_subscr ) = _parse_term_terminal( $self, $token, $is_bind );

    return $term if $no_subscr || !$term;
    return _parse_maybe_subscript_rest( $self, $term, 1 );
}

sub _parse_indirobj_maybe_subscripts {
    my( $self, $token, $indir ) = @_;
    $indir ||= _parse_indirobj( $self, 0 );
    my $sigil = $token_to_sigil{$token->[O_TYPE]};
    my $is_id = ref( $indir ) eq 'ARRAY' && $indir->[O_TYPE] == T_ID;

    # no subscripting/slicing possible for '%'
    if( $sigil == VALUE_HASH ) {
        return $is_id ? _find_symbol( $self, $token->[O_POS],
                                      $sigil, $indir->[O_VALUE], $indir->[O_ID_TYPE] ) :
                        Language::P::ParseTree::Dereference->new
                            ( { left  => $indir,
                                op    => OP_DEREFERENCE_HASH,
                                pos   => $token->[O_POS],
                                } );
    }

    my $next = $self->lexer->peek( X_OPERATOR );

    if( $sigil == VALUE_SUB ) {
        my $deref = $is_id ? _find_symbol( $self, $token->[O_POS], $sigil, $indir->[O_VALUE], $indir->[O_ID_TYPE] ) :
                             $indir;

        return _parse_indirect_function_call( $self, $deref,
                                              $next->[O_TYPE] == T_OPPAR, 1 );
    }

    # simplify the code below by resolving the symbol here, so a
    # dereference will be constructed below (probably an unary
    # operator would be more consistent)
    if( $sigil == VALUE_ARRAY_LENGTH ) {
        $indir = $is_id ? _find_symbol( $self, $token->[O_POS], VALUE_ARRAY, $indir->[O_VALUE], $indir->[O_ID_TYPE] ) :
                          Language::P::ParseTree::Dereference->new
                              ( { left  => $indir,
                                  op    => OP_DEREFERENCE_ARRAY,
                                  pos   => $token->[O_POS],
                                  } );
        $is_id = 0;
    }

    if( $next->[O_TYPE] == T_ARROW ) {
        my $deref = $is_id ? _find_symbol( $self, $token->[O_POS], $sigil, $indir->[O_VALUE], $indir->[O_ID_TYPE] ) :
                             Language::P::ParseTree::Dereference->new
                                 ( { left  => $indir,
                                     op    => $dereference_type{$sigil},
                                     pos   => $token->[O_POS],
                                     } );

        return _parse_maybe_subscript_rest( $self, $deref );
    }

    my( $is_slice, $sym_sigil );
    if(    ( $sigil == VALUE_ARRAY || $sigil == VALUE_SCALAR )
        && ( $next->[O_TYPE] == T_OPSQ || $next->[O_TYPE] == T_OPBRK ) ) {
        $sym_sigil = $next->[O_TYPE] == T_OPBRK ? VALUE_HASH : VALUE_ARRAY;
        $is_slice = $sigil == VALUE_ARRAY;
    } elsif( $sigil == VALUE_GLOB && $next->[O_TYPE] == T_OPBRK ) {
        $sym_sigil = VALUE_GLOB;
    } else {
        return $is_id ? _find_symbol( $self, $token->[O_POS], $sigil, $indir->[O_VALUE], $indir->[O_ID_TYPE] ) :
                         Language::P::ParseTree::Dereference->new
                             ( { left  => $indir,
                                 op    => $dereference_type{$sigil},
                                 pos   => $token->[O_POS],
                                 } );
    }

    my $subscript = _parse_bracketed_expr( $self, $next->[O_TYPE], 0 );
    my $subscripted = $is_id ? _find_symbol( $self, $token->[O_POS], $sym_sigil, $indir->[O_VALUE], $indir->[O_ID_TYPE] ) :
                               $indir;
    my $subscript_type = $next->[O_TYPE] == T_OPBRK ? VALUE_HASH : VALUE_ARRAY;

    if( $is_slice ) {
        return Language::P::ParseTree::Slice->new
                   ( { subscripted => $subscripted,
                       subscript   => _make_list( $self, $subscript ),
                       type        => $subscript_type,
                       reference   => $is_id ? 0 : 1,
                       pos         => $token->[O_POS],
                       } );
    } else {
        my $term = Language::P::ParseTree::Subscript->new
                       ( { subscripted => $subscripted,
                           subscript   => $subscript,
                           type        => $subscript_type,
                           reference   => $is_id ? 0 : 1,
                           pos         => $token->[O_POS],
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    }
}

sub _parse_lexical {
    my( $self, $keyword ) = @_;

    die $keyword unless $keyword == OP_MY || $keyword == OP_OUR;

    local $self->{_in_declaration} = 1;
    my $term = _parse_term_list_if_parens( $self, PREC_NAMED_UNOP );
    my $force_closed = !$self->_lexical_state->[-1]{is_sub};

    return _process_declaration( $self, $term, $keyword, $force_closed );
}

# takes a my $foo or my( $foo, $bar ) declaration, turns each ::Symbol
# node into either a fully-qualified symbol (our) or a lexical
# declaration (my)
sub _process_declaration {
    my( $self, $decl, $keyword, $force_closed ) = @_;

    if( $decl->isa( 'Language::P::ParseTree::List' ) ) {
        foreach my $e ( @{$decl->expressions} ) {
            $e = _process_declaration( $self, $e, $keyword, $force_closed );
        }

        return $decl;
    } elsif( $decl->isa( 'Language::P::ParseTree::Symbol' ) ) {
        my $sym;
        if( $keyword == OP_OUR ) {
            $sym = Language::P::ParseTree::Symbol->new
                       ( { name        => _qualify( $self, $decl->name, T_ID ),
                           sigil       => $decl->sigil,
                           symbol_name => $decl->sigil . "\0" . $decl->name,
                           pos         => $decl->pos,
                           } );
        } else {
            $sym = Language::P::ParseTree::LexicalDeclaration->new
                       ( { name    => $decl->name,
                           sigil   => $decl->sigil,
                           flags   => $declaration_to_flags{$keyword},
                           pos     => $decl->pos,
                           } );
            # TODO maybe use a separate flag value, to decouple from
            #      current implementation
            $sym->set_closed_over if $force_closed;
        }
        push @{$self->_pending_lexicals}, $sym;

        return $sym;
    } elsif(    $decl->isa( 'Language::P::ParseTree::Builtin' )
             && $decl->function == OP_UNDEF ) {
        # allow undef in my declarations, to be able to assign lists
        return $decl;
    } else {
        die 'Invalid node ', ref( $decl ), ' in declaration';
    }
}

sub _parse_term_p {
    my( $self, $prec, $token, $lookahead, $is_bind ) = @_;
    my $terminal = _parse_term_terminal_maybe_subscripts( $self, $token, $is_bind );

    return $terminal if $terminal && !$lookahead;

    if( $terminal ) {
        my $la = $self->lexer->peek( X_OPERATOR );
        my $binprec = $prec_assoc_bin{$la->[O_TYPE]};

        if( !$binprec || $binprec->[0] > $prec ) {
            return $terminal;
        } elsif( $la->[O_TYPE] == T_INTERR ) {
            _lex_token( $self, T_INTERR );
            return _parse_ternary( $self, PREC_TERNARY, $terminal );
        } elsif( $binprec ) {
            return _parse_term_n( $self, $binprec->[0],
                                  $terminal );
        } else {
            _syntax_error( $self, $la );
        }
    } elsif( $token->[O_TYPE] == T_FILETEST ) {
        return _parse_listop_like( $self, $token, 1,
                                   Language::P::ParseTree::Builtin->new
                                       ( { function => $token->[O_FT_OP],
                                           pos      => $token->[O_POS],
                                           } ) );
    } elsif( my $p = $prec_assoc_un{$token->[O_TYPE]} ) {
        my $rest = _parse_term_n( $self, $p->[0] );

        return Language::P::ParseTree::UnOp->new
                   ( { op    => $p->[2],
                       left  => $rest,
                       pos   => $token->[O_POS],
                       } );
    } elsif( $token->[O_TYPE] == T_OPPAR ) {
        my $term = _parse_expr( $self );
        _lex_token( $self, T_CLPAR );

        # maybe list slice
        my $next = $self->lexer->peek( X_OPERATOR );
        if( $next->[O_TYPE] == T_OPSQ ) {
            my $subscript = _parse_bracketed_expr( $self, T_OPSQ, 0, 0 );

            return Language::P::ParseTree::Slice->new
                       ( { subscripted => _make_list( $self, $term ),
                           subscript   => _make_list( $self, $subscript ),
                           type        => VALUE_LIST,
                           reference   => 0,
                           pos         => $next->[O_POS],
                           } );
        }

        if( !$term ) {
            # empty list
            return Language::P::ParseTree::List->new
                       ( { expressions => [],
                           pos         => $token->[O_POS],
                           } );
        } elsif( !$term->isa( 'Language::P::ParseTree::List' ) ) {
            # record that there were prentheses, unless it is a list
            return Language::P::ParseTree::Parentheses->new
                       ( { left => $term,
                           pos  => $token->[O_POS],
                           } );
        } else {
            return $term;
        }
    }

    return undef;
}

sub _parse_ternary {
    my( $self, $prec, $terminal ) = @_;

    my $iftrue = _parse_term_n( $self, PREC_TERNARY_COLON - 1 );
    _lex_token( $self, T_COLON );
    my $iffalse = _parse_term( $self, $prec );

    return Language::P::ParseTree::Ternary->new
               ( { condition => $terminal,
                   iftrue    => $iftrue,
                   iffalse   => $iffalse,
                   pos_s     => $terminal->pos_s,
                   pos_e     => $iffalse->pos_e,
                   } );
}

sub _parse_term_n {
    my( $self, $prec, $terminal, $is_bind ) = @_;

    if( !$terminal ) {
        my $token = $self->lexer->lex( X_TERM );
        $terminal = _parse_term_p( $self, $prec, $token, undef, $is_bind );

        if( !$terminal ) {
            $self->lexer->unlex( $token );
            return undef;
        }
    }

    for(;;) {
        my $token = $self->lexer->lex( X_OPERATOR );

        if(    $token->[O_TYPE] == T_PLUSPLUS
            || $token->[O_TYPE] == T_MINUSMINUS ) {
            my $op = $token->[O_TYPE] == T_PLUSPLUS ? OP_POSTINC : OP_POSTDEC;
            $terminal = Language::P::ParseTree::UnOp->new
                            ( { op    => $op,
                                left  => $terminal,
                                pos   => $token->[O_POS],
                                } );
            $token = $self->lexer->lex( X_OPERATOR );
        }

        my $bin = $prec_assoc_bin{$token->[O_TYPE]};
        if( !$bin || $bin->[0] > $prec ) {
            $self->lexer->unlex( $token );
            last;
        } elsif( $token->[O_TYPE] == T_INTERR ) {
            $terminal = _parse_ternary( $self, PREC_TERNARY, $terminal );
        } else {
            # do not try to use colon as binary
            _syntax_error( $self, $token )
                if $token->[O_TYPE] == T_COLON;

            my $q = $bin->[1] == ASSOC_RIGHT ? $bin->[0] : $bin->[0] - 1;
            my $rterm = _parse_term_n( $self, $q, undef,
                                       (    $token->[O_TYPE] == T_MATCH
                                         || $token->[O_TYPE] == T_NOTMATCH ) );

            if( $token->[O_TYPE] == T_COMMA ) {
                if( $terminal->isa( 'Language::P::ParseTree::List' ) ) {
                    if( $rterm ) {
                        push @{$terminal->expressions}, $rterm;
                        $rterm->set_parent( $terminal );
                    }
                } else {
                    $terminal = Language::P::ParseTree::List->new
                        ( { expressions => [ $terminal, $rterm ? $rterm : () ],
                            pos         => $terminal->pos,
                            } );
                }
            } else {
                $terminal = Language::P::ParseTree::BinOp->new
                                ( { op    => $bin->[2],
                                    left  => $terminal,
                                    right => $rterm,
                                    pos   => $token->[O_POS],
                                    } );
            }
        }
    }

    return $terminal;
}

sub _parse_term {
    my( $self, $prec ) = @_;
    my $token = $self->lexer->lex( X_TERM );
    my $terminal = _parse_term_p( $self, $prec, $token, 1, 0 );

    if( $terminal ) {
        $terminal = _parse_term_n( $self, $prec, $terminal );

        return $terminal;
    }

    $self->lexer->unlex( $token );

    return undef;
}

sub _make_list {
    my( $self, $term, $pos ) = @_;

    if( !$term ) {
        return Language::P::ParseTree::List->new
                   ( { expressions => [],
                       pos         => $pos,
                       } );
    } elsif( $term->isa( 'Language::P::ParseTree::List' ) ) {
        return $term;
    } elsif( $term->isa( 'Language::P::ParseTree::Parentheses' ) ) {
        return Language::P::ParseTree::List->new
                   ( { expressions => [ $term->left ],
                       pos         => $term->pos,
                       } );
    } else {
        return Language::P::ParseTree::List->new
                   ( { expressions => [ $term ],
                       pos         => $term->pos,
                       } );
    }
}

sub _parse_term_list_if_parens {
    my( $self, $prec ) = @_;
    my $term = _parse_term( $self, $prec );

    if( $term->isa( 'Language::P::ParseTree::Parentheses' ) ) {
        return Language::P::ParseTree::List->new
                   ( { expressions => [ $term->left ],
                       pos         => $term->pos,
                       } );
    }

    return $term;
}

sub _lines_implicit_return {
    my( $self, $lines ) = @_;

    for( my $i = $#$lines; $i >= 0; --$i ) {
        next if $lines->[$i]->is_declaration;
        $lines->[$i] = _add_implicit_return( $lines->[$i] );
        last;
    }
}

sub _add_implicit_return {
    my( $line ) = @_;

    return $line unless $line->can_implicit_return;
    if( !$line->is_compound ) {
        return Language::P::ParseTree::Builtin->new
                   ( { arguments => [ $line ],
                       function  => OP_RETURN,
                       pos       => $line->pos,
                       } );
    }

    # compound and can implicitly return
    if( $line->isa( 'Language::P::ParseTree::Block' ) && @{$line->lines} ) {
        $line->lines->[-1] = _add_implicit_return( $line->lines->[-1] );
    } elsif( $line->isa( 'Language::P::ParseTree::Conditional' ) ) {
        _add_implicit_return( $_ ) foreach @{$line->iftrues};
        _add_implicit_return( $line->iffalse ) if $line->iffalse;
    } elsif( $line->isa( 'Language::P::ParseTree::ConditionalBlock' ) ) {
        _add_implicit_return( $line->block )
    } else {
        Carp::confess( "Unhandled statement type: ", ref( $line ) );
    }

    return $line;
}

sub _parse_block_rest {
    my( $self, $pos, $flags, $end_token ) = @_;

    $end_token ||= T_CLBRK;
    $self->_enter_scope if $flags & BLOCK_OPEN_SCOPE;

    my $has_lex_state = 0;
    my @lines;
    for(;;) {
        my $token = $self->lexer->lex( X_STATE );
        if( $token->[O_TYPE] == $end_token ) {
            _lines_implicit_return( $self, \@lines )
                if $flags & BLOCK_IMPLICIT_RETURN;
            $self->_leave_scope if $flags & BLOCK_OPEN_SCOPE;
            my $block;
            if( $flags & BLOCK_BARE ) {
                my $continue = _parse_continue( $self );
                $block = Language::P::ParseTree::BareBlock->new
                             ( { lines    => \@lines,
                                 continue => $continue,
                                 pos_s    => $pos,
                                 pos_e    => $token->[O_POS],
                                 } );
            } elsif( $flags & BLOCK_DO ) {
                $block = Language::P::ParseTree::DoBlock->new
                             ( { lines    => \@lines,
                                 pos_s    => $pos,
                                 pos_e    => $token->[O_POS],
                                 } );
            } elsif( $flags & BLOCK_EVAL ) {
                $block = Language::P::ParseTree::EvalBlock->new
                             ( { lines    => \@lines,
                                 pos_s    => $pos,
                                 pos_e    => $token->[O_POS],
                                 } );
            } else {
                $block = Language::P::ParseTree::Block->new
                             ( { lines => \@lines,
                                 pos_s => $pos,
                                 pos_e => $token->[O_POS],
                                 } );
            }

            if( $has_lex_state ) {
                $block->set_attribute( 'lexical_state' => 1 );
            }

            return $block;
        } else {
            $self->lexer->unlex( $token );
            my $line = _parse_line( $self );

            if(    $line
                && (    $line->isa( 'Language::P::ParseTree::NamedSubroutine' )
                     || $line->isa( 'Language::P::ParseTree::Use' ) ) ) {
                $self->generator->process( $line );
            } elsif( $line && !$line->is_empty ) {
                push @lines, $line;
            }
            my $lex_state = _lexical_state_node( $self );
            if( $lex_state ) {
                push @lines, $lex_state;
                $has_lex_state = 1;
            }
        }
    }
}

sub _parse_indirobj {
    my( $self, $allow_fail ) = @_;
    my $id = $self->lexer->lex_identifier( 0 );

    if( $id ) {
        return $id;
    }

    my $token = $self->lexer->lex( X_BLOCK );

    if( $token->[O_TYPE] == T_OPBRK ) {
        my $block = _parse_block_rest( $self, $token->[O_POS],
                                       BLOCK_OPEN_SCOPE );

        return $block;
    } elsif( $token->[O_TYPE] == T_DOLLAR ) {
        my $indir = _parse_indirobj( $self, 0 );

        if( ref( $indir ) eq 'ARRAY' && $indir->[O_TYPE] == T_ID ) {
            return _find_symbol( $self, $token->[O_POS], VALUE_SCALAR, $indir->[O_VALUE], $indir->[O_ID_TYPE] );
        } else {
            return Language::P::ParseTree::Dereference->new
                       ( { left  => $indir,
                           op    => OP_DEREFERENCE_SCALAR,
                           pos   => $token->[O_POS],
                           } );
        }
    } elsif( $allow_fail ) {
        $self->lexer->unlex( $token );

        return undef;
    } else {
        _syntax_error( $self, $token );
    }
}

sub _declared_id {
    my( $self, $op ) = @_;
    my $call;
    my $opidt = $op->[O_ID_TYPE];

    if( is_overridable( $opidt ) ) {
        my $rt = $self->runtime;

        if( $rt->get_symbol( _qualify( $self, $op->[O_VALUE], $opidt ), '&' ) ) {
            die "Overriding '" . $op->[O_VALUE] . "' not implemented";
        }
        $call = Language::P::ParseTree::Overridable->new
                    ( { function  => $KEYWORD_TO_OP{$opidt},
                        pos       => $op->[O_POS],
                        } );

        return ( $call, 1 );
    } elsif( is_builtin( $opidt ) ) {
        $call = Language::P::ParseTree::Builtin->new
                    ( { function  => $KEYWORD_TO_OP{$opidt},
                        pos       => $op->[O_POS],
                        } );

        return ( $call, 1 );
    } else {
        my $rt = $self->runtime;
        my $fqname = _qualify( $self, $op->[O_VALUE], $opidt );

        my $symbol = Language::P::ParseTree::Symbol->new
                         ( { name  => $fqname,
                             sigil => VALUE_SUB,
                             pos   => $op->[O_POS],
                             } );
        $call = Language::P::ParseTree::FunctionCall->new
                    ( { function  => $symbol,
                        arguments => undef,
                        pos       => $op->[O_POS],
                        } );

        if( my $decl = $rt->get_symbol( $fqname, '&' ) ) {
            # FIXME accessor
            $call->{prototype} = $decl->prototype;
            return ( $call, 1 );
        }
    }

    return ( $call, 0 );
}

sub _parse_listop {
    my( $self, $op ) = @_;
    my( $call, $declared ) = _declared_id( $self, $op );

    return _parse_listop_like( $self, $op, $declared, $call );
}

sub _parse_listop_like {
    my( $self, $op, $declared, $call ) = @_;
    my $proto = $call ? $call->parsing_prototype : undef;
    my $expect = !$declared                                      ? X_OPERATOR_INDIROBJ :
                 !$proto                                         ? X_TERM :
                 $proto->[2] & (PROTO_FILEHANDLE|PROTO_INDIROBJ) ? X_REF :
                 $proto->[2] & (PROTO_BLOCK|PROTO_SUB)           ? X_BLOCK :
                                                                   X_TERM;
    my $next = $self->lexer->peek( $expect );
    my( $args, $fh );

    if( !$call || !$declared || $call->is_plain_function ) {
        if( $next->[O_TYPE] == T_ARROW ) {
            _lex_token( $self, T_ARROW );
            my $la = $self->lexer->peek( X_METHOD_SUBSCRIPT );

            if( $la->[O_TYPE] == T_ID || $la->[O_TYPE] == T_DOLLAR ) {
                # here we are calling the method on a bareword
                my $invocant = Language::P::ParseTree::Constant->new
                                   ( { value => $op->[O_VALUE],
                                       flags => CONST_STRING,
                                       pos   => $op->[O_POS],
                                       } );

                return _parse_maybe_direct_method_call( $self, $invocant );
            } elsif( $la->[O_TYPE] == T_OPPAR ) {
                if( $declared ) {
                    $self->lexer->unlex( $next );
                } else {
                    # parsed as a normal sub call; go figure
                    $next = $la;
                }
            } else {
                _syntax_error( $self, $la );
            }
        } elsif( !$declared && $next->[O_TYPE] != T_OPPAR ) {
            # not a declared subroutine, nor followed by parenthesis
            # try to see if it is some sort of (indirect) method call
            return _parse_maybe_indirect_method_call( $self, $op, $next );
        } elsif(    $next->[O_TYPE] == T_ID
                 && $self->runtime->get_package( $next->[O_VALUE] ) ) {
            # foo Bar:: is always a method call
            return _parse_maybe_indirect_method_call( $self, $op, $next );
        }
    }

    if( !ref( $call->function ) && $call->function == OP_RETURN ) {
        ( $args, $fh ) = _parse_arglist( $self, PREC_LOWEST, 0, $proto->[2] );
    } elsif( $next->[O_TYPE] == T_OPPAR ) {
        _lex_token( $self, T_OPPAR );
        ( $args, $fh ) = _parse_arglist( $self, PREC_LOWEST, 0, $proto->[2] );
        _lex_token( $self, T_CLPAR );
    } elsif( $proto->[1] == 1 ) {
        ( $args, undef ) = _parse_arglist( $self, PREC_NAMED_UNOP, 1, $proto->[2] );
    } elsif( $proto->[1] != 0 ) {
        Carp::confess( "Undeclared identifier '" . $op->[O_VALUE] . "'" )
            unless $declared;
        ( $args, $fh ) = _parse_arglist( $self, PREC_COMMA, 0, $proto->[2] );
    }

    # FIXME avoid reconstructing the call?
    if( $proto->[2] & (PROTO_INDIROBJ|PROTO_FILEHANDLE) ) {
        $call = Language::P::ParseTree::BuiltinIndirect->new
                    ( { function  => $KEYWORD_TO_OP{$op->[O_ID_TYPE]},
                        arguments => $args,
                        indirect  => $fh,
                        pos       => $op->[O_POS],
                        } );
    } elsif( $args ) {
        # FIXME encapsulation
        $call->{arguments} = $args;
        $_->set_parent( $call ) foreach @$args;
    }

    _apply_prototype( $self, $op->[O_POS], $call );

    return $call;
}

sub _function_name {
    return !ref( $_[0] )    ? $ID_TO_KEYWORD{$OP_TO_KEYWORD{$_[0]}} :
           $_[0]->is_symbol ? $_[0]->name :
                              'unknown';
}

sub _apply_prototype {
    my( $self, $pos, $call ) = @_;
    my $proto = $call->parsing_prototype;
    my $args = $call->arguments || [];
    my $func = $call->function;
    my $is_opcode = !ref( $call->function );

    if( !$call->arguments && ( $proto->[2] & PROTO_DEFAULT_ARG ) ) {
        my $op = $is_opcode ? $func : 0;

        if( $op == OP_FT_ISTTY ) {
            $call->{arguments} = [ _find_symbol( $self, undef, VALUE_GLOB,
                                                 'STDIN', T_FQ_ID ) ];
        } elsif( $op == OP_ARRAY_SHIFT || $op == OP_ARRAY_POP ) {
            if( my $lex = _find_lexical( $self, VALUE_ARRAY, '_' ) ) {
                $call->{arguments} = [ $lex ];
            } else {
                $call->{arguments} = [ _find_symbol( $self, undef, VALUE_ARRAY,
                                                     'ARGV', T_FQ_ID ) ];
            }
        } else {
            $call->{arguments} = [ _find_symbol( $self, undef, VALUE_SCALAR,
                                                 '_', T_FQ_ID ) ];
        }
        $args = $call->arguments;
    }

    my $indirect =    $call->isa( 'Language::P::ParseTree::BuiltinIndirect' )
                   && $call->indirect ? 1 : 0;
    if( $indirect + @$args < $proto->[0] ) {
        _parse_error( $self, $pos, "Too few arguments for %s",
                      _function_name( $func ) );
    }
    if( $proto->[1] != -1 && @$args > $proto->[1] ) {
        _parse_error( $self, $pos, "Too many arguments for %s",
                      _function_name( $func ) );
    }

    if(    $is_opcode
        && $func == OP_EXISTS
        && !(    $args->[0]->isa( 'Language::P::ParseTree::SpecialFunctionCall' )
              || $args->[0]->isa( 'Language::P::ParseTree::Subscript' ) ) ) {
        _parse_error( $self, $pos, 'exists argument is not a HASH or ARRAY element or a subroutine' );
    } elsif(    $is_opcode
             && $func == OP_BLESS
             && @{$args} == 1 ) {
        $args->[1] = Language::P::ParseTree::Constant->new
                         ( { value => $self->{_lexical_state}[-1]{package},
                             flags => CONST_STRING,
                             pos   => $call->pos,
                             } );
    }

    foreach my $i ( 3 .. $#$proto ) {
        last if $i - 3 > $#$args;
        my $proto_char = $proto->[$i];
        my $term = $args->[$i - 3];

        # defined/exists &foo
        if(    ( $proto_char & PROTO_AMPER )
            && $term->isa( 'Language::P::ParseTree::SpecialFunctionCall' )
            && ( $term->flags & FLAG_IMPLICITARGUMENTS ) ) {
            $args->[$i - 3] = $term->function;
        }
        if(    ( $proto_char & PROTO_MAKE_GLOB ) == PROTO_MAKE_GLOB
            && $term->is_bareword ) {
            $args->[$i - 3] = Language::P::ParseTree::Symbol->new
                                  ( { name  => $term->value,
                                      sigil => VALUE_GLOB,
                                      pos   => $term->pos,
                                      } );
        }
        if(    ( $proto_char & PROTO_MAKE_ARRAY ) == PROTO_MAKE_ARRAY
            && $term->is_bareword ) {
            $args->[$i - 3] = Language::P::ParseTree::Symbol->new
                                  ( { name  => $term->value,
                                      sigil => VALUE_ARRAY,
                                      pos   => $term->pos,
                                      } );
        }
        if( $proto_char & PROTO_REFERENCE ) {
            my $arg = $args->[$i - 3];
            my $value = $arg->is_symbol ? $arg->sigil : 0;
            my $ref = $arg->isa( 'Language::P::ParseTree::Dereference' ) ?
                            $arg->op : 0;
            my $is_arr = $value == VALUE_ARRAY || $ref == OP_DEREFERENCE_ARRAY;
            my $is_hash = $value == VALUE_HASH || $ref == OP_DEREFERENCE_HASH;
            my $is_sc = $value == VALUE_SCALAR || $ref == OP_DEREFERENCE_SCALAR;
            my $is_glob = $value == VALUE_GLOB || $ref == OP_DEREFERENCE_GLOB;

            if(    ( ( $proto_char & PROTO_ARRAY ) && $is_arr )
                || ( ( $proto_char & PROTO_HASH ) && $is_hash )
                || ( ( $proto_char & PROTO_SCALAR ) && $is_sc )
                || ( ( $proto_char & PROTO_GLOB ) && $is_glob ) ) {
                # reference op added during code generation
            } else {
                _parse_error( $self, $pos,
                              "Invalid argument for reference prototype %s",
                              _function_name( $func ) );
            }
        }
    }
}

sub _parse_arglist {
    my( $self, $prec, $is_unary, $proto_char ) = @_;
    my $indirect_term = $proto_char & (PROTO_INDIROBJ|PROTO_FILEHANDLE);
    my $la = $self->lexer->peek( $indirect_term ? X_REF : X_TERM );
    my $term_prec = $prec > PREC_LISTEXPR ? PREC_LISTEXPR : $prec;

    my $term;
    if( $indirect_term ) {
        if( $la->[O_TYPE] == T_OPBRK ) {
            $term = _parse_indirobj( $self, 0 );
        } elsif(    $proto_char & PROTO_FILEHANDLE
                 && $la->[O_TYPE] == T_ID
                 && $la->[O_ID_TYPE] == T_ID ) {
            # check if it is a declared id
            my $declared = $self->runtime
                ->get_symbol( _qualify( $self, $la->[O_VALUE], $la->[O_ID_TYPE] ), '&' );
            # look ahead one more token
            _lex_token( $self );
            my $la2 = $self->lexer->peek( X_TERM );

            # approximate what would happen in Perl LALR parser
            my $tt = $la2->[O_TYPE];
            if( $declared || $tt == T_ARROW ) {
                $self->lexer->unlex( $la );
                $indirect_term = 0;
            } elsif(    $prec_assoc_bin{$tt}
                     && !$prec_assoc_un{$tt}
                     && $tt != T_STAR
                     && $tt != T_PERCENT
                     && $tt != T_DOLLAR
                     && $tt != T_AMPERSAND
                     ) {
                $self->lexer->unlex( $la );
                $indirect_term = 0;
            } elsif( $tt == T_ID && is_id( $la2->[O_ID_TYPE] ) ) {
                $self->lexer->unlex( $la );
                $indirect_term = 0;
            } else {
                $term = Language::P::ParseTree::Symbol->new
                            ( { name  => $la->[O_VALUE],
                                sigil => VALUE_GLOB,
                                pos   => $la->[O_POS],
                                } );
            }
        } elsif( $proto_char & PROTO_FILEHANDLE ) {
            if( $la->[O_TYPE] == T_DOLLAR ) {
                _lex_token( $self, T_DOLLAR );

                $term = _parse_indirobj( $self, 0 );
                # used to peek after the indirect object without failing
                # in the print $foo $bar case: _parse_term_n would lex using
                # X_OPERATOR and trigger the "Scalar found where operator
                # expected" check
                my $la2 = $self->lexer->peek( X_OPERATOR_INDIROBJ );
                my $tt = $la2->[O_TYPE];

                # TODO Perl disambiguates the second case for */% using
                # whitespace and some heuristics, while here it always
                # assumes that what looks like a binary operator, is a
                # binary operator
                $term = _parse_indirobj_maybe_subscripts( $self, $la, $term );
                if( $prec_assoc_bin{$tt}
                    || $tt == T_PLUSPLUS || $tt == T_MINUSMINUS ) {
                    $term = _parse_term_n( $self, $term_prec, $term );
                }
            } else {
                $term = _parse_term( $self, $term_prec );
            }

            if( !$term ) {
                $indirect_term = 0;
            } elsif(    !( $term->is_symbol && $term->sigil == VALUE_SCALAR )
                     && !$term->isa( 'Language::P::ParseTree::Block' ) ) {
                $indirect_term = 0;
            }
        }
    } elsif(    $proto_char & (PROTO_BLOCK|PROTO_SUB)
             && $la->[O_TYPE] == T_OPBRK ) {
        if( $proto_char & PROTO_BLOCK ) {
            _lex_token( $self );
            $term = _parse_block_rest( $self, $la->[O_POS], BLOCK_OPEN_SCOPE );
        } else {
            $term = _parse_sub( $self, 2, 1, $la->[O_POS] );
            # a very evil hack to make map-like sub parse as Perl does
            my $next = $self->lexer->peek( X_TERM );
            return [$term] if $next->[O_TYPE] == T_COMMA;
            $self->lexer->unlex( [ -1, T_COMMA, ',' ] );
        }
    }

    $term ||= _parse_term( $self, $term_prec );

    return unless $term;
    return [ $term ] if $is_unary;

    if( $indirect_term ) {
        my $la = $self->lexer->peek( X_TERM );

        if( $la->[O_TYPE] != T_COMMA ) {
            my $args = _parse_arglist( $self, $prec, 0, 0 );

            if( !$args && $term->is_symbol && $term->sigil == VALUE_SCALAR ) {
                return ( [ $term ] );
            } else {
                return ( $args, $term );
            }
        }
    }

    $term = _parse_term_n( $self, $prec, $term, 0 );

    return $term && $term->isa( 'Language::P::ParseTree::List' ) ?
               $term->expressions : [ $term ];
}

sub _parse_do {
    my( $self, $token ) = @_;

    my $next = $self->lexer->peek( X_BLOCK );
    if( $next->[O_TYPE] == T_OPBRK ) {
        _lex_token( $self );
        my $block = _parse_block_rest( $self, $next->[O_POS],
                                       BLOCK_OPEN_SCOPE|BLOCK_DO );
        return _parse_statement_modifier( $self, $block );
    }

    my $call = Language::P::ParseTree::Builtin->new
                   ( { function => OP_DO_FILE,
                       pos      => $token->[O_POS],
                       } );
    my $do = _parse_listop_like( $self, $token, 1, $call );
    my $first = $do->arguments->[0];
    if( $first->is_plain_function && $first->function->is_symbol ) {
        return $do->arguments->[0];
    } elsif(    ( $first->is_symbol && $first->sigil == VALUE_SCALAR )
             || (    $first->isa( 'Language::P::ParseTree::Dereference' )
                  && $first->op == OP_DEREFERENCE_SCALAR ) ) {
        my $oppar = $self->lexer->peek;
        if( $oppar->[O_TYPE] == T_OPPAR ) {
            return _parse_indirect_function_call( $self, $first, 1, 0 );
        }
    }

    return $do;
}

sub _parse_eval {
    my( $self, $token ) = @_;

    my $next = $self->lexer->peek( X_BLOCK );
    if( $next->[O_TYPE] == T_OPBRK ) {
        _lex_token( $self );
        return _parse_block_rest( $self, $next->[O_POS],
                                  BLOCK_OPEN_SCOPE|BLOCK_EVAL );
    }

    my( $lex, $glob ) = $self->_lexicals->all_visible_lexicals;
    my $lex_state = $self->{_lexical_state}[-1];
    my $tree = _parse_listop( $self, $token );
    $_->set_closed_over foreach values %$lex;
    $tree->set_attribute( 'lexicals', $lex );
    $tree->set_attribute( 'globals', $glob );
    $tree->set_attribute( 'environment',
                          { hints    => $lex_state->{hints},
                            warnings => $lex_state->{warnings},
                            package  => $lex_state->{package},
                            } );

    return $tree;
}

1;
