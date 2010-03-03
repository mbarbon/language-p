package Language::P::Lexer;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(stream buffer tokens runtime
                                 file line _start_of_line _heredoc_lexer
                                 ) );
__PACKAGE__->mk_accessors( qw(quote) );

sub data_handle {
    my( $self ) = @_;
    my $data = $self->{data_handle};

    $self->{data_handle} = undef;

    return $data;
}

use Language::P::ParseTree qw(:all);
use Language::P::Keywords;

our @TOKENS;
BEGIN {
  our @TOKENS =
    qw(T_ID T_FQ_ID T_SUB_ID T_EOF T_PACKAGE T_FILETEST
       T_PATTERN T_STRING T_NUMBER T_QUOTE T_OR T_XOR T_SHIFT_LEFT T_SHIFT_RIGHT
       T_SEMICOLON T_COLON T_COMMA T_OPPAR T_CLPAR T_OPSQ T_CLSQ
       T_OPBRK T_CLBRK T_OPHASH T_OPAN T_CLPAN T_INTERR
       T_NOT T_SLESS T_CLAN T_SGREAT T_EQUAL T_LESSEQUAL T_SLESSEQUAL
       T_GREATEQUAL T_SGREATEQUAL T_EQUALEQUAL T_SEQUALEQUAL T_NOTEQUAL
       T_SNOTEQUAL T_SLASH T_BACKSLASH T_DOT T_DOTDOT T_DOTDOTDOT T_PLUS
       T_MINUS T_STAR T_DOLLAR T_PERCENT T_AT T_AMPERSAND T_PLUSPLUS
       T_MINUSMINUS T_ANDAND T_OROR T_ARYLEN T_ARROW T_MATCH T_NOTMATCH
       T_ANDANDLOW T_ORORLOW T_NOTLOW T_XORLOW T_CMP T_SCMP T_SSTAR T_POWER
       T_PLUSEQUAL T_MINUSEQUAL T_STAREQUAL T_SLASHEQUAL T_LABEL T_TILDE
       T_VSTRING T_VERSION T_DOTEQUAL T_SSTAREQUAL T_PERCENTEQUAL
       T_POWEREQUAL T_AMPERSANDEQUAL T_OREQUAL T_XOREQUAL
       T_ANDANDEQUAL T_OROREQUAL

       T_CLASS_START T_CLASS_END T_CLASS T_QUANTIFIER T_ASSERTION T_ALTERNATE
       T_CLGROUP T_BACKREFERENCE T_POSIX
       );
};

use constant
  { X_NOTHING  => 0,
    X_STATE    => 1,  # at the start of a new line
    X_TERM     => 2,
    X_OPERATOR => 3,
    X_BLOCK    => 4,  # bracketed block
    X_REF      => 5,  # filehandle/indirect argument of print/map/grep
    X_METHOD_SUBSCRIPT => 6, # saw an arrow, expecting method/subscript
    X_OPERATOR_INDIROBJ => 7, # saw a bareword, expect operator/indirect object

    O_POS             => 0,
    O_TYPE            => 1,
    O_VALUE           => 2,
    O_ID_TYPE         => 3,
    O_FT_OP           => 3,
    O_QS_INTERPOLATE  => 3,
    O_QS_BUFFER       => 4,
    O_RX_REST         => 3,
    O_RX_SECOND_HALF  => 5,
    O_RX_FLAGS        => 6,
    O_RX_INTERPOLATED => 7,
    O_NUM_FLAGS       => 3,

    LEX_NO_PACKAGE    => 1,

    map { $TOKENS[$_] => $_ + 1 } 0 .. $#TOKENS,
    };

use Exporter 'import';

our @EXPORT_OK =
  ( qw(X_NOTHING X_STATE X_TERM X_OPERATOR X_BLOCK X_REF X_METHOD_SUBSCRIPT
       X_OPERATOR_INDIROBJ
       O_POS O_TYPE O_VALUE O_ID_TYPE O_FT_OP O_QS_INTERPOLATE O_QS_BUFFER
       O_RX_REST O_RX_SECOND_HALF O_RX_FLAGS O_RX_INTERPOLATED O_NUM_FLAGS
       LEX_NO_PACKAGE
       ), @TOKENS );
our %EXPORT_TAGS =
  ( all  => \@EXPORT_OK,
    );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );
    my $a = delete $self->{string} || "";

    $self->{buffer} = ref $a ? $a : \$a;
    $self->{tokens} = [];
    $self->{brackets} = 0;
    $self->{pending_brackets} = [];
    $self->{line} ||= 1;
    $self->{_start_of_line} = 1;
    $self->{pos} = [ $self->file, $self->line ];

    return $self;
}

sub peek {
    my( $self, $expect ) = ( @_, X_NOTHING );
    my $token = $self->lex( $expect );

    $self->unlex( $token );

    return $token;
}

sub unlex {
    my( $self, $token ) = @_;

    push @{$self->tokens}, $token;
}

sub _lexer_error {
    my( $self, $pos, $message, @args ) = @_;

    throw Language::P::Parser::Exception
        ( message  => sprintf( $message, @args ),
          position => $pos,
          );
}

my %ops =
  ( ';'   => T_SEMICOLON,
    ':'   => T_COLON,
    ','   => T_COMMA,
    '=>'  => T_COMMA,
    '('   => T_OPPAR,
    ')'   => T_CLPAR,
    '['   => T_OPSQ,
    ']'   => T_CLSQ,
    '{'   => T_OPBRK,
    '}'   => T_CLBRK,
    '?'   => T_INTERR,
    '!'   => T_NOT,
    '>>'  => T_SHIFT_RIGHT,
    '<<'  => T_SHIFT_LEFT,
    '<'   => T_OPAN,
    'lt'  => T_SLESS,
    '>'   => T_CLAN,
    'gt'  => T_SGREAT,
    '='   => T_EQUAL,
    '<='  => T_LESSEQUAL,
    'le'  => T_SLESSEQUAL,
    '>='  => T_GREATEQUAL,
    'ge'  => T_SGREATEQUAL,
    '=='  => T_EQUALEQUAL,
    'eq'  => T_SEQUALEQUAL,
    '!='  => T_NOTEQUAL,
    'ne'  => T_SNOTEQUAL,
    '<=>' => T_CMP,
    'cmp' => T_SCMP,
    '/'   => T_SLASH,
    '/='  => T_SLASHEQUAL,
    '\\'  => T_BACKSLASH,
    '.'   => T_DOT,
    '.='  => T_DOTEQUAL,
    '..'  => T_DOTDOT,
    '...' => T_DOTDOTDOT,
    '~'   => T_TILDE,
    '+'   => T_PLUS,
    '+='  => T_PLUSEQUAL,
    '-'   => T_MINUS,
    '-='  => T_MINUSEQUAL,
    '*'   => T_STAR,
    '*='  => T_STAREQUAL,
    'x'   => T_SSTAR,
    'x='  => T_SSTAREQUAL,
    '$'   => T_DOLLAR,
    '%'   => T_PERCENT,
    '%='  => T_PERCENTEQUAL,
    '**'  => T_POWER,
    '**=' => T_POWEREQUAL,
    '@'   => T_AT,
    '&'   => T_AMPERSAND,
    '&='  => T_AMPERSANDEQUAL,
    '|'   => T_OR,
    '|='  => T_OREQUAL,
    '^'   => T_XOR,
    '^='  => T_XOREQUAL,
    '++'  => T_PLUSPLUS,
    '--'  => T_MINUSMINUS,
    '&&'  => T_ANDAND,
    '&&=' => T_ANDANDEQUAL,
    '||'  => T_OROR,
    '||=' => T_OROREQUAL,
    '$#'  => T_ARYLEN,
    '->'  => T_ARROW,
    '=~'  => T_MATCH,
    '!~'  => T_NOTMATCH,
    'and' => T_ANDANDLOW,
    'or'  => T_ORORLOW,
    'not' => T_NOTLOW,
    'xor' => T_XORLOW,
    );

my %filetest =
  ( r => OP_FT_EREADABLE,
    w => OP_FT_EWRITABLE,
    x => OP_FT_EEXECUTABLE,
    o => OP_FT_EOWNED,
    R => OP_FT_RREADABLE,
    W => OP_FT_RWRITABLE,
    X => OP_FT_REXECUTABLE,
    O => OP_FT_ROWNED,
    e => OP_FT_EXISTS,
    z => OP_FT_EMPTY,
    s => OP_FT_NONEMPTY,
    f => OP_FT_ISFILE,
    d => OP_FT_ISDIR,
    l => OP_FT_ISSYMLINK,
    p => OP_FT_ISPIPE,
    S => OP_FT_ISSOCKET,
    b => OP_FT_ISBLOCKSPECIAL,
    c => OP_FT_ISCHARSPECIAL,
    t => OP_FT_ISTTY,
    u => OP_FT_SETUID,
    g => OP_FT_SETGID,
    k => OP_FT_STICKY,
    T => OP_FT_ISASCII,
    B => OP_FT_ISBINARY,
    M => OP_FT_MTIME,
    A => OP_FT_ATIME,
    C => OP_FT_CTIME,
    );

my %quoted_chars =
  ( 'n' => "\n",
    't' => "\t",
    'r' => "\r",
    'f' => "\f",
    'b' => "\b",
    'a' => "\a",
    'e' => "\e",
    );

my %quoted_pattern =
  ( w  => [ T_CLASS, 'WORDS' ],
    W  => [ T_CLASS, 'NON_WORDS' ],
    s  => [ T_CLASS, 'SPACES' ],
    S  => [ T_CLASS, 'NOT_SPACES' ],
    d  => [ T_CLASS, 'DIGITS' ],
    D  => [ T_CLASS, 'NOT_DIGITS' ],
    b  => [ T_ASSERTION, 'WORD_BOUNDARY' ],
    B  => [ T_ASSERTION, 'NON_WORD_BOUNDARY' ],
    A  => [ T_ASSERTION, 'BEGINNING' ],
    Z  => [ T_ASSERTION, 'END_OR_NEWLINE' ],
    z  => [ T_ASSERTION, 'END' ],
    G  => [ T_ASSERTION, 'POS' ],
    );

my %pattern_special =
  ( '^'  => [ T_ASSERTION, 'START_SPECIAL' ],
    '$'  => [ T_ASSERTION, 'END_SPECIAL' ],
    '.'  => [ T_ASSERTION, 'ANY_SPECIAL' ],
    '*'  => [ T_QUANTIFIER, 0, -1, 1 ],
    '+'  => [ T_QUANTIFIER, 1, -1, 1 ],
    '?'  => [ T_QUANTIFIER, 0,  1, 1 ],
    '*?' => [ T_QUANTIFIER, 0, -1, 0 ],
    '+?' => [ T_QUANTIFIER, 1, -1, 0 ],
    '??' => [ T_QUANTIFIER, 0,  1, 0 ],
    ')'  => [ T_CLGROUP ],
    '|'  => [ T_ALTERNATE ],
    '['  => [ T_CLASS_START ], # ']' handled in lex_charclass
    );

sub _skip_space {
    my( $self ) = @_;
    my $buffer = $self->buffer;
    my $retval = '';
    my $reset_pos = 0;

    for(;;) {
        $self->_fill_buffer unless length $$buffer;
        return unless length $$buffer;

        if(    $self->{_start_of_line}
            && $$buffer =~ s/^#[ \t]*line[ \t]+([0-9]+)(?:[ \t]+"([^"]+)")?[ \t]*[\r\n]// ) {
            $self->{line} = $1;
            $self->{file} = $2 if $2;
            $reset_pos = 1;
            next;
        } elsif(    $self->{_start_of_line}
                 && $$buffer =~ /^=[a-zA-Z]/ ) {
            $reset_pos = 1;
            do {
                ++$self->{line};
                $$buffer = '';
                $self->_fill_buffer;
            } while( $$buffer && $$buffer !~ /^=cut\b/ );
            ++$self->{line};
            $$buffer = '';
            next;
        } elsif(    $self->{_start_of_line}
                 && $$buffer =~ /^__(END|DATA)__\b/ ) {
            $$buffer = ''; # assumes the buffer contains at most one line
            $self->{data_handle} = [ $1, $self->{stream} ];
            $self->{stream} = undef;
            return;
        }

        $$buffer =~ s/^([ \t]+)// && defined wantarray and $retval .= $1;
        if( $$buffer =~ s/^([\r\n])// ) {
            $retval .= $1 if defined wantarray;
            $self->{_start_of_line} = 1;
            ++$self->{line};
            $reset_pos = 1;
            next;
        }
        if( $$buffer =~ s/^(#.*\n)// ) {
            $retval .= $1 if defined wantarray;
            $self->{_start_of_line} = 1;
            ++$self->{line};
            $reset_pos = 1;
            next;
        }

        last if length $$buffer;
    }

    if( $reset_pos ) {
        $self->{pos} = [ $self->{file}, $self->{line} ];
    }

    return $retval;
}

# taken from intuit_more in toke.c
sub _character_class_insanity {
    my( $self ) = @_;
    my $buffer = $self->buffer;

    if( $$buffer =~ /^\]|^\^/ ) {
        return 1;
    }

    my( $t ) = $$buffer =~ /^(.*\])/;
    my $w = 2;
    my( $un_char, $last_un_char, @seen ) = ( 255 );

    return 1 if !defined $t;

    if( $t =~ /^\$/ ) {
        $w -= 3;
    } elsif( $t =~ /^[0-9][0-9]\]/ ) {
        $w -= 10
    } elsif( $t =~ /^[0-9]\]/ ) {
        $w -= 100;
    } elsif( $t =~ /^\$\w+/ ) {
        # HACK, not in original
        $w -= 100;
    }

    for(;;) {
        last;
    }

    return $w >= 0 ? 1 : 0;
}

# taken from intuit_more in toke.c
sub _quoted_code_lookahead {
    my( $self ) = @_;
    my $buffer = $self->buffer;

    if( $$buffer =~ s/^->([{[])// ) {
        ++$self->{brackets};
        $self->unlex( [ $self->{pos}, $ops{$1}, $1 ] );
        $self->unlex( [ $self->{pos}, T_ARROW, '->' ] );
    } elsif( $$buffer =~ s/^{// ) {
        if( !$self->quote->{interpolated_pattern} ) {
            ++$self->{brackets};
            $self->unlex( [ $self->{pos}, T_OPBRK, '{' ] );
        } elsif( $$buffer =~ /^[0-9]+/ ) {
            $$buffer = '{' . $$buffer;
            my $token = $self->lex_quote;
            $self->unlex( $token );
        } else {
            ++$self->{brackets};
            $self->unlex( [ $self->{pos}, T_OPBRK, '{' ] );
        }
    } elsif( $$buffer =~ s/^\[// ) {
        if( !$self->quote->{interpolated_pattern} ) {
            ++$self->{brackets};
            $self->unlex( [ $self->{pos}, T_OPSQ, '[' ] );
        } else {
            if( _character_class_insanity( $self ) ) {
                $$buffer = '[' . $$buffer;
                my $token = $self->lex_quote;
                $self->unlex( $token );
            } else {
                ++$self->{brackets};
                $self->unlex( [ $self->{pos}, T_OPSQ, '[' ] );
            }
        }
    } else {
        my $token = $self->lex_quote;
        $self->unlex( $token );
    }
}

sub lex_pattern_group {
    my( $self ) = @_;
    my $buffer = $self->buffer;

    die unless length $$buffer; # no whitespace allowed after '(?'

    $$buffer =~ s/^(\#|:|[imsx]*\-[imsx]*:?|!|=|<=|<!|{|\?{|\?>)//x
      or die "Invalid character after (?";

    return [ $self->{pos}, T_PATTERN, $1 ];
}

sub lex_charclass {
    my( $self ) = @_;

    my $buffer = $self->buffer;
    my $c = substr $$buffer, 0, 1, '';
    if( $c eq '\\' ) {
        my $qc = substr $$buffer, 0, 1, '';

        if( my $qp = $quoted_pattern{$qc} ) {
            return [ $self->{pos}, $qp->[0], $qp->[1] ];
        }

        return [ $self->{pos}, T_STRING, $qc ];
    } elsif( $c eq '-' ) {
        return [ $self->{pos}, T_MINUS, '-' ];
    } elsif( $c eq ']' ) {
        return [ $self->{pos}, T_CLASS_END ];
    } elsif( $c eq '[' && $$buffer =~ s/^:(\w+):\]// ) {
        return [ $self->{pos}, T_POSIX, $1 ];
    } else {
        return [ $self->{pos}, T_STRING, $c ];
    }
}

sub lex_quote {
    my( $self ) = @_;

    return pop @{$self->tokens} if @{$self->tokens};

    my $buffer = $self->buffer;
    my $v = '';
    for(;;) {
        unless( length $$buffer ) {
            if( length $v ) {
                $self->unlex( [ $self->{pos}, T_EOF, '' ] );
                return [ $self->{pos}, T_STRING, $v, 1 ];
            } else {
                return [ $self->{pos}, T_EOF, '' ];
            }
        }

        my $to_return;
        my $pattern = $self->quote->{pattern};
        my $interpolated_pattern = $self->quote->{interpolated_pattern};
        my $substitution = $self->quote->{substitution};

        while( length $$buffer ) {
            my $c = substr $$buffer, 0, 1, '';

            if( $pattern || $interpolated_pattern ) {
                if( $c eq '\\' ) {
                    my $qc = substr $$buffer, 0, 1;

                    if( $interpolated_pattern ) {
                        substr $$buffer, 0, 1, ''; # eat character
                        $v .= $c . $qc;
                        next;
                    } elsif( my $qp = $quoted_pattern{$qc} ) {
                        substr $$buffer, 0, 1, ''; # eat character
                        $to_return = [ $self->{pos}, T_PATTERN, $qc, $qp ];
                    } elsif( $pattern_special{$qc} ) {
                        substr $$buffer, 0, 1, ''; # eat character
                        $v .= $qc;
                        next;
                    } elsif( $qc =~ /[1-9]/ ) {
                        $$buffer =~ s/^([0-9]+)//;

                        $to_return = [ $self->{pos}, T_PATTERN, $1,
                                       [ T_BACKREFERENCE, $1 ] ];
                    }
                } elsif(    $c eq '{'
                         && !$interpolated_pattern
                         && $$buffer =~ s/^([0-9]+)(?:(,)([0-9]+)?)?}(\?)?// ) {
                    my $from = $1;
                    my $to = !$2        ? $from :
                             defined $3 ? $3 :
                                          -1;
                    $to_return = [ $self->{pos}, T_PATTERN, '{',
                                   [ T_QUANTIFIER, $from, $to, $4 ? 0 : 1 ] ];
                } elsif( $c eq '(' && !$interpolated_pattern ) {
                    my $nc = substr $$buffer, 0, 1;

                    if( $nc eq '?' ) {
                        substr $$buffer, 0, 1, ''; # eat character
                        $to_return = [ $self->{pos}, T_PATTERN, '(?' ];
                    } else {
                        $to_return = [ $self->{pos}, T_PATTERN, '(' ];
                    }
                } elsif(     !$interpolated_pattern
                         and my $special = $pattern_special{$c} ) {
                    # check nongreedy quantifiers
                    if( $special->[0] == T_QUANTIFIER ) {
                        my $qc = substr $$buffer, 0, 1;

                        if( $qc eq '?' ) {
                            substr $$buffer, 0, 1, '';
                            $special = $pattern_special{$c . $qc};
                        }
                    }

                    $to_return = [ $self->{pos}, T_PATTERN, $c, $special ];
                }
            }

            if( $to_return ) {
                if( length $v ) {
                    $self->unlex( $to_return );
                    return [ $self->{pos}, T_STRING, $v, 1 ];
                } else {
                    return $to_return;
                }
            }

            if( $c eq '\\' && $self->quote->{interpolate} ) {
                my $qc = substr $$buffer, 0, 1, '';

                if( $qc =~ /^[a-zA-Z]$/ ) {
                    if( $quoted_chars{$qc} ) {
                        $v .= $quoted_chars{$qc};
                    } elsif( $qc eq 'c' ) {
                        my $next = uc substr $$buffer, 0, 1, '';
                        $v .= chr( ord( $next ) ^ 0x40 );
                    } elsif( $qc eq 'x' ) {
                        if( $$buffer =~ s/^([0-9a-fA-F]{1,2})// ) {
                            $v .= chr( oct '0x' . $1 );
                        } else {
                            $v .= "\0";
                        }
                    } elsif(    $qc eq 'Q' || $qc eq 'E' || $qc eq 'l'
                             || $qc eq 'u' || $qc eq 'L' || $qc eq 'U' ) {
                        if( $qc eq 'Q' ) {
                            $to_return = [ $self->{pos}, T_QUOTE, OP_QUOTEMETA ];
                        } elsif( $qc eq 'l' ) {
                            $to_return = [ $self->{pos}, T_QUOTE, OP_LCFIRST ];
                        } elsif( $qc eq 'u' ) {
                            $to_return = [ $self->{pos}, T_QUOTE, OP_UCFIRST ];
                        } elsif( $qc eq 'L' ) {
                            $to_return = [ $self->{pos}, T_QUOTE, OP_LC ];
                        } elsif( $qc eq 'U' ) {
                            $to_return = [ $self->{pos}, T_QUOTE, OP_UC ];
                        } elsif( $qc eq 'E' ) {
                            $to_return = [ $self->{pos}, T_QUOTE, 0 ];
                        }

                        if( length $v ) {
                            $self->unlex( $to_return );
                            return [ $self->{pos}, T_STRING, $v, 1 ];
                        } else {
                            return $to_return;
                        }
                    } else {
                        die "Invalid escape '$qc'";
                    }
                } elsif(    $substitution
                         && $qc =~ /^[1-9]$/
                         && $self->quote->{interpolate}
                         && $$buffer !~ /^[0-9]$/ ) {
                    _quoted_code_lookahead( $self );

                    # handle \1 backreference in substitution
                    $self->unlex( [ $self->{pos}, T_ID, $qc, T_ID ] );

                    if( length $v ) {
                        $self->unlex( [ $self->{pos}, T_DOLLAR, '$' ] );
                        return [ $self->{pos}, T_STRING, $v ];
                    } else {
                        return [ $self->{pos}, T_DOLLAR, '$' ];
                    }
                } elsif( $qc =~ /^[0-7]$/ ) {
                    if( $$buffer =~ s/^([0-7]{1,2})// ) {
                        $qc .= $1;
                    }

                    $v .= chr( oct '0' . $qc );
                } else {
                    $v .= $qc;
                }
            } elsif( $c =~ /^[\$\@]$/ && $self->quote->{interpolate} ) {
                if(    $c eq '$'
                    && (    substr( $$buffer, 0, 2 ) eq '#{'
                         || substr( $$buffer, 0, 2 ) eq '#$' ) ) {
                    $c .= substr $$buffer, 0, 1, '';
                } elsif( $c eq '$' && substr( $$buffer, 0, 1 ) eq '#' ) {
                    # same code as in 'lex' below, handle $# as variable
                    my $id = $self->lex_identifier( 0 );

                    if( $id ) {
                        $self->unlex( $id );
                    } else {
                        $c .= substr $$buffer, 0, 1, '';
                    }
                }

                if(    $interpolated_pattern
                    && (    !length( $$buffer )
                         || index( "()| \r\n\t",
                                   substr( $$buffer, 0, 1 ) ) != -1 ) ) {
                    $v .= $c;
                } elsif( length $v ) {
                    $self->unlex( [ $self->{pos}, $ops{$c}, $c ] );

                    return [ $self->{pos}, T_STRING, $v ];
                } else {
                    return [ $self->{pos}, $ops{$c}, $c ];
                }
            } else {
                $v .= $c;
            }
        }
    }

    die "Can't get there";
}

sub lex_version {
    my( $self ) = @_;

    local $_ = $self->buffer;

    _skip_space( $self )
      if defined( $$_ ) && $$_ =~ /^[ \t\r\n]/;

    return [ $self->{pos}, T_EOF, '' ] unless length $$_;

    # TODO review version comparing in 5.10
    if( $$_ =~ s/^v((?:\d+\.)*\d+)// ) {
        return [ $self->{pos}, T_VSTRING, $1 ]
    } elsif( $$_ =~ s/^((?:\d+\.)*\d+)// ) {
        return [ $self->{pos}, T_VERSION, $1 ]
    }

    return undef;
}

sub lex_alphabetic_identifier {
    my( $self, $flags ) = @_;

    if( @{$self->tokens} ) {
        return undef if $self->tokens->[-1]->[O_TYPE] != T_ID;
        return pop @{$self->tokens};
    }

    local $_ = $self->buffer;

    if( $flags & LEX_NO_PACKAGE ) {
        return undef unless $$_ =~ /^[ \t\r\n]*\w/;
    } else {
        return undef unless $$_ =~ /^[ \t\r\n]*[':\w]/;
    }

    return lex_identifier( $self, $flags );
}

sub lex_identifier {
    my( $self, $flags ) = @_;

    if( @{$self->tokens} ) {
        return undef if $self->tokens->[-1]->[O_TYPE] != T_ID;
        return pop @{$self->tokens};
    }

    local $_ = $self->buffer;

    _skip_space( $self )
      if defined( $$_ ) && $$_ =~ /^[ \t\r\n]/;

    return [ $self->{pos}, T_EOF, '' ] unless length $$_;

    my $id;
    $$_ =~ s/^\^([A-Z\[\\\]^_?])//x and do {
        $id = [ $self->{pos}, T_ID, chr( ord( $1 ) - ord( 'A' ) + 1 ), T_FQ_ID ];
    };
    $id or $$_ =~ s/^::(?=\W)//x and do {
        $id = [ $self->{pos}, T_ID, 'main::', T_FQ_ID ];
    };
    $id or $$_ =~ s/^(\'|::)?(\w+)//x and do {
        if( $flags & LEX_NO_PACKAGE ) {
            return [ $self->{pos}, T_ID, $2, T_ID ];
        }

        my $ids = defined $1 ? '::' . $2 : $2;
        my $idt = defined $1 ? T_FQ_ID : T_ID;

        while( $$_ =~ s/^::(\w*)|^\'(\w+)// ) {
            $ids .= '::' . ( defined $1 ? $1 : $2 );
            $idt = T_FQ_ID;
        }

        $id = [ $self->{pos}, T_ID, $ids, $idt ];
    };
    $id or $$_ =~ s/^{\^([A-Z\[\\\]^_?])(\w*)}//x and do {
        $id = [ $self->{pos}, T_ID, chr( ord( $1 ) - ord( 'A' ) + 1 ) . $2, T_FQ_ID ];
    };
    $id or $$_ =~ s/^{//x and do {
        my $spcbef = _skip_space( $self );
        my $maybe_id;
        if( $$_ =~ s/^(\w+)//x ) {
            $maybe_id = $1;
        } else {
            $$_ = '{' . $spcbef . $$_;
            return undef;
        }
        my $spcaft = _skip_space( $self );

        if( $$_ =~ s/^}//x ) {
            $id = [ $self->{pos}, T_ID, $maybe_id, T_ID ];
        } elsif( $$_ =~ /^\[|^\{/ ) {
            ++$self->{brackets};
            push @{$self->{pending_brackets}}, $self->{brackets};
            $id = [ $self->{pos}, T_ID, $maybe_id, T_ID ];
        } else {
            # not a simple identifier
            $$_ = '{' . $spcbef . $maybe_id . $spcaft . $$_;
            return undef;
        }
    };
    $id or $$_ =~ /^\$[\${:]/ and do {
        return;
    };
    $id or $$_ =~ s/^(\W)(?=\W|$)// and do {
        $id = [ $self->{pos}, T_ID, $1, T_FQ_ID ];
    };

    if( $id && $self->quote && $self->{brackets} == 0 ) {
        _quoted_code_lookahead( $self );
    }

    return $id;
}

sub lex_number {
    my( $self ) = @_;
    local $_ = $self->buffer;
    my( $num, $flags ) = ( '', 0 );

    $$_ =~ s/^0([xb]?)//x and do {
        if( $1 eq 'b' ) {
            # binary number
            if( $$_ =~ s/^([01]+)// ) {
                $flags = NUM_BINARY;
                $num .= $1;

                return [ $self->{pos}, T_NUMBER, $num, $flags ];
            } else {
                die "Invalid binary digit";
            }
        } elsif( $1 eq 'x' ) {
            # hexadecimal number
            if( $$_ =~ s/^([0-9a-fA-F]+)// ) {
                $flags = NUM_HEXADECIMAL;
                $num .= $1;

                return [ $self->{pos}, T_NUMBER, $num, $flags ];
            } else {
                die "Invalid hexadecimal digit";
            }
        } else {
            # maybe octal number
            if( $$_ =~ s/^([0-7]+)// ) {
                $flags = NUM_OCTAL;
                $num .= $1;
                $$_ =~ /^[89]/ and die "Invalid octal digit";

                return [ $self->{pos}, T_NUMBER, $num, $flags ];
            } else {
                $flags = NUM_INTEGER;
                $num = '0'
            }
        }
    };
    $$_ =~ s/^(\d+)//x and do {
        $flags = NUM_INTEGER;
        $num .= $1;
    };
    # '..' operator (es. 12..15)
    $$_ =~ /^\.\./ and return [ $self->{pos}, T_NUMBER, $num, $flags ];
    $$_ =~ s/^\.(\d*)//x and do {
        $flags = NUM_FLOAT;
        $num = '0' unless length $num;
        $num .= ".$1" if length $1;
    };
    $$_ =~ s/^[eE]([+-]?\d+)//x and do {
        $flags = NUM_FLOAT;
        $num .= "e$1";
    };

    return [ $self->{pos}, T_NUMBER, $num, $flags ];
}

my %quote_end = qw!( ) { } [ ] < >!;
my @rx_flags =
  ( FLAG_RX_MULTI_LINE, FLAG_RX_SINGLE_LINE, FLAG_RX_CASE_INSENSITIVE,
    FLAG_RX_FREE_FORMAT, FLAG_RX_ONCE, FLAG_RX_GLOBAL, FLAG_RX_KEEP,
    FLAG_RX_EVAL );
my @tr_flags = ( FLAG_RX_COMPLEMENT, FLAG_RX_DELETE, FLAG_RX_SQUEEZE );
my %regex_flags =
  ( m  => [ OP_QL_M,  'msixogc', @rx_flags ],
    qr => [ OP_QL_QR, 'msixo', @rx_flags ],
    s  => [ OP_QL_S,  'msixogce', @rx_flags ],
    tr => [ OP_QL_TR, 'cds', @tr_flags ],
    y  => [ OP_QL_TR, 'cds', @tr_flags ],
    );

sub _find_end {
    my( $self, $op, $quote_start ) = @_;

    local $_ = $self->buffer;

    if( $op && !$quote_start ) {
        if( $$_ =~ /^[ \t\r\n]/ ) {
            _skip_space( $self );
        }
        # if we find a fat comma, we got a string constant, not the
        # start of a quoted string!
        $$_ =~ /^=>/ and return ( undef, [ $self->{pos}, T_STRING, $op ] );
        $$_ =~ s/^([^ \t\r\n])// or die;
        $quote_start = $1;
    }

    my $quote_end = $quote_end{$quote_start} || $quote_start;
    my $paired = $quote_start eq $quote_end ? 0 : 1;
    my $is_regex = $regex_flags{$op};
    my $pos = $self->{pos};

    my( $interpolated, $delim_count, $str ) = ( 0, 1, '' );
    SCAN_END: for(;;) {
        $self->_fill_buffer unless length $$_;
        _lexer_error( $self, $pos, "Can't find string terminator '$quote_end' anywhere before EOF" ) unless length $$_;

        while( length $$_ ) {
            my $c = substr $$_, 0, 1, '';

            if( $c eq '\\' ) {
                my $qc = substr $$_, 0, 1, '';

                if( $qc eq $quote_start || $qc eq $quote_end ) {
                    $str .= $qc;
                } else {
                    $str .= "\\" . $qc;
                }

                next;
            } elsif( $c eq "\n" ) {
                ++$self->{line};
            } elsif( $paired && $c eq $quote_start ) {
                ++$delim_count;
            } elsif( $c eq $quote_end ) {
                --$delim_count;

                last SCAN_END unless $delim_count;
            } elsif(    $is_regex
                     && ( $c eq '$' || $c eq '@' )
                     && $quote_start ne "'" ) {
                my $nc = substr $$_, 0, 1;

                if(    length( $nc )
                    && $nc ne $quote_end
                    && index( "()| \r\n\t", $nc ) == -1 ) {
                    $interpolated = 1;
                }
            }

            $str .= $c;
        }
    }

    my $interpolate = $op eq 'qq'         ? 1 :
                      $op eq 'q'          ? 0 :
                      $op eq 'qw'         ? 0 :
                      $quote_start eq "'" ? 0 :
                                            1;
    return ( $quote_start,
             [ $pos, $is_regex ? T_PATTERN : T_QUOTE,
               0, $interpolate, \$str, undef, undef, $interpolated ] );
}

sub lex_proto_or_attr {
    my( $self ) = @_;
    my( $quote, $token ) = _find_end( $self, 'q', '(' );

    return $token->[4];
}

sub _prepare_sublex {
    my( $self, $op, $quote_start ) = @_;
    my( $quote, $token ) = _find_end( $self, $op, $quote_start );

    # oops, found fat comma: not a quote-like operator
    return $token if $token->[O_TYPE] == T_STRING;

    if( my $op_descr = $regex_flags{$op} ) {
        # scan second part of substitution/transliteration
        if( $op eq 's' || $op eq 'tr' || $op eq 'y' ) {
            my $quote_char = $quote_end{$quote} ? undef : $quote;
            my( undef, $rest ) = _find_end( $self, $op, $quote_char );
            $token->[O_RX_SECOND_HALF] = $rest;
        }

        # scan regexp flags
        $token->[O_VALUE] = $op_descr->[0];
        my $fl_str = $op_descr->[1];
        local $_ = $self->buffer;

        my $flags = 0;
        while(     length( $$_ )
               and ( my $idx = index( $fl_str, substr( $$_, 0, 1 ) ) ) >= 0 ) {
            substr $$_, 0, 1, '';
            $flags |= $op_descr->[$idx + 2];
        }
        $token->[O_RX_FLAGS] = $flags;
    } elsif( $op eq 'qx' || $op eq "`" ) {
        $token->[O_VALUE] = OP_QL_QX;
    } elsif( $op eq 'qw' ) {
        $token->[O_VALUE] = OP_QL_QW;
    } elsif( $op eq '<' ) {
        $token->[O_VALUE] = OP_QL_LT;
    }

    return $token;
}

sub _prepare_sublex_heredoc {
    my( $self ) = @_;
    my( $quote, $str, $end ) = ( '"', '' );

    local $_ = $self->buffer;
    my $pos = $self->{pos};

    if( $$_ =~ s/^[ \t]*(['"`])// ) {
        # << "EOT", << 'EOT', << `EOT`
        $quote = $1;

        while( $$_ =~ s/^(.*?)(\\)?($quote)// ) {
            $end .= $1;
            if( !$2 ) {
                last;
            } else {
                $end .= $quote;
            }
        }
    } else {
        # <<\EOT, <<EOT
        if( $$_ =~ s/\\// ) {
            $quote = "'";
        }

        $$_ =~ s/^(\w*)//;
        if( !$1 ) {
            $self->runtime->warning_if
              ( 'syntax', $self->file, $self->line,
                'Use of bare << to mean <<"" is deprecated' );
        }
        $end = $1;
    }
    $end .= "\n";

    my $lex = $self->_heredoc_lexer || $self;
    my $finished = 0;
    if( !$lex->stream ) {
        $_ = $lex->buffer;
        if( $$_ =~ s/(.*)^$end//m ) {
            $str .= $1;
            $finished = 1;
        }
    } else {
        # if the lexer reads from a stream, it buffers at most one line,
        # so by not using the buffer we skip the rest of the line
        my $stream = $lex->stream;
        while( defined( my $line = readline $stream ) ) {
            if( $line eq $end ) {
                $finished = 1;
                last;
            }
            $str .= $line;
        }
    }

    Carp::confess( "EOF while looking for terminator '$end'" ) unless $finished;

    return [ $pos, T_QUOTE, $quote eq "`" ? OP_QL_QX : 0, $quote ne "'", \$str ];
}

sub lex {
    my( $self, $expect ) = ( @_, X_NOTHING );

    return pop @{$self->tokens} if @{$self->tokens};

    # skip blanks and comments
    _skip_space( $self );

    local $_ = $self->buffer;
    return [ $self->{pos}, T_EOF, '' ] unless length $$_;
    my $indir;
    if( $expect == X_OPERATOR_INDIROBJ ) {
        $indir = 1;
        $expect = X_OPERATOR;
    }

    # numbers
    $$_ =~ /^\d|^\.\d/ and do {
        _lexer_error( $self, $self->{pos},
                      "Number found where operator expected" )
            if $expect == X_OPERATOR;
        return $self->lex_number;
    };
    # quote and quote-like operators
    $$_ =~ s/^(q|qq|qx|qw|m|qr|s|tr|y)(?=\W)//x and
        return _prepare_sublex( $self, $1, undef );
    # 'x' operator special case
    $$_ =~ /^x[0-9]/ && $expect == X_OPERATOR and do {
        $$_ =~ s/^.//;
        return [ $self->{pos}, T_SSTAR, 'x' ];
    };
    # anything that can start with alphabetic character: package name,
    # label, identifier, fully qualified identifier, keyword, named
    # operator
    $$_ =~ s/^(::)?(\w+)//x and do {
        my $ids = ( $1 || '' ) . $2;
        my $fqual = $1 ? 1 : 0;
        my $no_space = $$_ !~ /^[ \t\r\n]/;

        my $op = $ops{$ids};
        my $kw = $op || $fqual ? undef : $Language::P::Keywords::KEYWORDS{$ids};
        my $type = $fqual ? T_FQ_ID :
                   $op    ? -1 :
                   $kw    ? $kw :
                             T_ID;

        if( $no_space && (    $$_ =~ /^::/
                           || (    ( $type == T_ID || $type == T_FQ_ID )
                                && $$_ =~ /^'\w/ ) ) ) {
            while( $$_ =~ s/^::(\w*)|^\'(\w+)// ) {
                $ids .= '::' . ( defined $1 ? $1 : $2 );
            }
            if( $ids =~ s/::$// ) {
                # warn for nonexistent package
            }
            $op = undef;
            $type = T_FQ_ID;
        }
        # force subroutine call
        if( $no_space && $type == T_ID && $$_ =~ /^\(/ ) {
            $type = T_SUB_ID;
        }

        # look ahead for fat comma, save the original value for __LINE__
        my $line = $self->line;
        my $pos = $self->{pos};
        _skip_space( $self );
        if( $$_ =~ /^=>/ ) {
            # fully qualified name (foo::moo) is quoted only if not declared
            if(    $type == T_FQ_ID
                && $self->runtime->get_symbol( $ids, '*' ) ) {
                return [ $pos, T_ID, $ids, $type ];
            } else {
                return [ $pos, T_STRING, $ids ];
            }
        } elsif(    $expect == X_STATE && $type != T_FQ_ID
                 && $$_ =~ s/^:(?!:)// ) {
            return [ $pos, T_LABEL, $ids ];
        }

        if( $type == T_ID && $ids =~ /^__/ ) {
            if( $ids eq '__FILE__' ) {
                return [ $pos, T_STRING, $self->file ];
            } elsif( $ids eq '__LINE__' ) {
                return [ $pos, T_NUMBER, $line, NUM_INTEGER ];
            } elsif( $ids eq '__PACKAGE__' ) {
                return [ $pos, T_PACKAGE, '' ];
            }
        }

        if( $op ) {
            # 'x' is an operator only when we expect it
            if( $op == T_SSTAR && $expect != X_OPERATOR ) {
                return [ $pos, T_ID, $ids, T_ID ];
            }

            return [ $pos, $op, $ids ];
        }
        return [ $pos, T_ID, $ids, $type ];
    };
    $$_ =~ s/^(["'`])//x and do {
        _lexer_error( $self, $self->{pos},
                      "String found where operator expected" )
            if $expect == X_OPERATOR;
        return _prepare_sublex( $self, $1, $1 );
    };
    # < when not operator (<> glob, <> file read, << here doc)
    $$_ =~ /^</ and $expect != X_OPERATOR and do {
        $$_ =~ s/^(<<|<)//x;

        if( $1 eq '<' ) {
            return _prepare_sublex( $self, '<', '<' );
        } elsif( $1 eq '<<' ) {
            return _prepare_sublex_heredoc( $self );
        }
    };
    # multi char operators
    $$_ =~ s/^(<=|>=|==|!=|=>|->|<<|>>
                |=~|!~
                |\.\.|\.\.\.
                |\+\+|\-\-
                |\+=|\-=|\*=|\/=|\.=|x=|%=|\*\*=|&=|\|=|\^=|&&=|\|\|=
                |\&\&|\|\|)//x and return [ $self->{pos}, $ops{$1}, $1 ];
    $$_ =~ s/^\$//x and do {
        _lexer_error( $self, $self->{pos},
                      "Scalar found where operator expected" )
            if $expect == X_OPERATOR && !$indir;
        if( $$_ =~ s/^\#(?=[{\$])//x ) {
            return [ $self->{pos}, $ops{'$#'}, '$#' ];
        } elsif( $$_ =~ /^\#/ ) {
            my $id = $self->lex_identifier( 0 );

            if( $id ) {
                $self->unlex( $id );
            } else {
                $$_ =~ s/^\#//x;
                return [ $self->{pos}, $ops{'$#'}, '$#' ];
            }
        }
        return [ $self->{pos}, $ops{'$'}, '$' ];
    };
    # brackets (block, subscripting, anonymous ref constructors)
    $$_ =~ s/^([{}\[\]])// and do {
        my $brack = $1;

        if( $brack eq '[' || $brack eq '{' ) {
            ++$self->{brackets};
        } else {
            if(    $brack eq '}'
                && @{$self->{pending_brackets}}
                && $self->{pending_brackets}[-1] == $self->{brackets} ) {
                pop @{$self->{pending_brackets}};
                --$self->{brackets};

                return $self->lex( $expect );
            }

            --$self->{brackets};

            if( $self->{brackets} == 0 && $self->quote ) {
                _quoted_code_lookahead( $self );
            }
        }

        # disambiguate start of block from anonymous hash
        if( $brack eq '{' ) {
            if( $expect == X_TERM ) {
                return [ $self->{pos}, T_OPHASH, '{' ];
            } elsif( $expect == X_OPERATOR || $expect == X_METHOD_SUBSCRIPT ) {
                # autoquote literal strings in hash subscripts
                if( $$_ =~ s/^[ \t]*([[:alpha:]_]+)[ \t]*\}// ) {
                    $self->unlex( [ $self->{pos}, T_CLBRK, '}' ] );
                    $self->unlex( [ $self->{pos}, T_STRING, $1 ] );
                }
            } elsif( $expect != X_BLOCK ) {
                # try to guess if it is a block or anonymous hash
                $self->_skip_space;

                if( $$_ =~ /^}/ ) {
                    return [ $self->{pos}, T_OPHASH, '{' ];
                }

                # treat '<bareward> =>', '<string> ,/=>' lookahead
                # as indicators of anonymous hash
                if( $$_ =~ /^([\w"'`])/ ) {
                    my $first = $1;

                    # can only be a string literal, quote like operator
                    # or identifier
                    my $next = $self->peek( X_NOTHING );

                    $self->_skip_space;
                    if(    $$_ =~ /^=>/
                        || ( $$_ =~ /^,/ && $next->[O_TYPE] != T_ID ) ) {
                        return [ $self->{pos}, T_OPHASH, '{' ];
                    }
                }
            }
        }

        return [ $self->{pos}, $ops{$brack}, $brack ];
    };
    # / (either regex start or division operator)
    $$_ =~ s/^\///x and do {
        if( $expect == X_TERM || $expect == X_STATE || $expect == X_REF ) {
            return _prepare_sublex( $self, 'm', '/' );
        } else {
            return [ $self->{pos}, T_SLASH, '/' ];
        }
    };
    # filetest operators
    $$_ =~ s/^-([rwxoRWXOezsfdlpSugkbctTBMMAC])(?=\W)// and do {
        my $op = $1;
        if( $$_ =~ /^[ \t]*=>/ ) {
            $self->unlex( [ 'STRING', $1 ] );
            return [ $self->{pos}, T_MINUS, '-' ];
        }

        return [ $self->{pos}, T_FILETEST, $op, $filetest{$op} ];
    };
    $$_ =~ s/^\@// and do {
        _lexer_error( $self, $self->{pos},
                      "Array found where operator expected" )
            if $expect == X_OPERATOR;
        return [ $self->{pos}, T_AT, '@' ];
    };
    # single char operators
    $$_ =~ s/^([:;,()\?<>!~=\/\\\+\-\.\|^\*%@&])//x and return [ $self->{pos}, $ops{$1}, $1 ];

    die "Lexer error: '$$_'";
}

sub _fill_buffer {
    my( $self ) = @_;
    my $stream = $self->stream;
    return unless $stream;
    my $buffer = $self->buffer;
    my $l = readline $stream;

    if( defined $l ) {
        $$buffer .= $l;
    }
}

1;
