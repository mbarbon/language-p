package Language::P::Lexer;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(stream buffer tokens
                                 ) );
__PACKAGE__->mk_accessors( qw(quote) );

use Language::P::ParseTree qw(:all);

our @TOKENS;
BEGIN {
  our @TOKENS =
    qw(T_ID T_KEYWORD T_OVERRIDABLE T_EOF T_PATTERN T_STRING T_NUMBER T_QUOTE
       T_SEMICOLON T_COLON T_COMMA T_OPPAR T_CLPAR T_OPSQ T_CLSQ
       T_OPBRK T_CLBRK T_OPHASH T_OPAN T_CLPAN T_INTERR
       T_NOT T_SLESS T_CLAN T_SGREAT T_EQUAL T_LESSEQUAL T_SLESSEQUAL
       T_GREATEQUAL T_SGREATEQUAL T_EQUALEQUAL T_SEQUALEQUAL T_NOTEQUAL
       T_SNOTEQUAL T_SLASH T_BACKSLASH T_DOT T_DOTDOT T_DOTDOTDOT T_PLUS
       T_MINUS T_STAR T_DOLLAR T_PERCENT T_AT T_AMPERSAND T_PLUSPLUS
       T_MINUSMINUS T_ANDAND T_OROR T_ARYLEN T_ARROW T_MATCH T_NOTMATCH
       T_ANDANDLOW T_ORORLOW T_NOTLOW T_XORLOW T_CMP T_SCMP T_SSTAR T_POWER
       T_PLUSEQUAL T_MINUSEQUAL T_STAREQUAL T_SLASHEQUAL

       T_CLASS_START T_CLASS_END T_CLASS T_QUANTIFIER T_ASSERTION T_ALTERNATE
       T_CLGROUP
       );
};

use constant
  { X_NOTHING  => 0,
    X_STATE    => 1,
    X_TERM     => 2,
    X_OPERATOR => 3,
    X_BLOCK    => 4,

    map { $TOKENS[$_] => $_ + 1 } 0 .. $#TOKENS,
    };

use Exporter qw(import);

our @EXPORT_OK =
  ( qw(X_NOTHING X_STATE X_TERM X_OPERATOR X_BLOCK
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
    '\\'  => T_BACKSLASH,
    '.'   => T_DOT,
    '..'  => T_DOTDOT,
    '...' => T_DOTDOTDOT,
    '+'   => T_PLUS,
    '-'   => T_MINUS,
    '*'   => T_STAR,
    '$'   => T_DOLLAR,
    '%'   => T_PERCENT,
    '**'  => T_POWER,
    '@'   => T_AT,
    '&'   => T_AMPERSAND,
    '++'  => T_PLUSPLUS,
    '--'  => T_MINUSMINUS,
    '&&'  => T_ANDAND,
    '||'  => T_OROR,
    '$#'  => T_ARYLEN,
    '->'  => T_ARROW,
    '=~'  => T_MATCH,
    '!~'  => T_NOTMATCH,
    'and' => T_ANDANDLOW,
    'or'  => T_ORORLOW,
    'not' => T_NOTLOW,
    'xor' => T_XORLOW,
    );

my %keywords = map { ( $_ => 1 ) }
  qw(if unless else elsif for foreach while until do last next redo
     my our state sub eval package
     ),
  qw(print defined return undef);
my %overridables = map { ( $_ => 1 ) }
  qw(unlink glob readline die open pipe chdir rmdir glob readline
     close binmode abs wantarray);

my %quoted_chars =
  ( 'n' => "\n",
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
    '*'  => [ T_QUANTIFIER, 0, -1, 1 ],
    '+'  => [ T_QUANTIFIER, 1, -1, 1 ],
    '?'  => [ T_QUANTIFIER, 0,  1, 1 ],
    '*?' => [ T_QUANTIFIER, 0, -1, 0 ],
    '+?' => [ T_QUANTIFIER, 1, -1, 0 ],
    '??' => [ T_QUANTIFIER, 0,  1, 0 ],
    ')'  => [ T_CLGROUP ],
    '|'  => [ T_ALTERNATE ],
    '['  => [ T_CLASS_START ],
    ']'  => [ T_CLASS_END ],
    );

sub _skip_space {
    my( $self ) = @_;
    my $buffer = $self->buffer;
    my $retval = '';

    for(;;) {
        $self->_fill_buffer unless length $$buffer;
        return unless length $$buffer;

        $$buffer =~ s/^([\s\r\n]+)// && defined wantarray and $retval .= $1;
        $$buffer =~ s/^(#.*\n)// && defined wantarray and $retval .= $1;

        last if length $$buffer;
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
        $self->unlex( [ $ops{$1}, $1 ] );
        $self->unlex( [ T_ARROW, '->' ] );
    } elsif( $$buffer =~ s/^{// ) {
        if( !$self->quote->{interpolated_pattern} ) {
            ++$self->{brackets};
            $self->unlex( [ T_OPBRK, '{' ] );
        } elsif( $$buffer =~ /^[0-9]+,[0-9]*}/ ) {
            die 'Quantifier!';
        } else {
            ++$self->{brackets};
            $self->unlex( [ T_OPBRK, '{' ] );
        }
    } elsif( $$buffer =~ s/^\[// ) {
        if( !$self->quote->{interpolated_pattern} ) {
            ++$self->{brackets};
            $self->unlex( [ T_OPSQ, '[' ] );
        } else {
            if( _character_class_insanity( $self ) ) {
                $$buffer = '[' . $$buffer;
                my $token = $self->lex_quote;
                $self->unlex( $token );
            } else {
                ++$self->{brackets};
                $self->unlex( [ T_OPSQ, '[' ] );
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

    return [ T_PATTERN, $1 ];
}

sub lex_charclass {
    my( $self ) = @_;

    my $buffer = $self->buffer;
    my $c = substr $$buffer, 0, 1, '';
    if( $c eq '\\' ) {
        my $qc = substr $$buffer, 0, 1, '';

        if( $quoted_pattern{$qc} ) {
            return $quoted_pattern{$qc};
        }

        return [ T_STRING, $qc ];
    } elsif( $c eq '-' ) {
        return [ T_MINUS, '-' ];
    } elsif( $c eq ']' ) {
        return [ T_CLASS_END ];
    } else {
        return [ T_STRING, $c ];
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
                $self->unlex( [ T_EOF, '' ] );
                return [ T_STRING, $v, 1 ];
            } else {
                return [ T_EOF, '' ];
            }
        }

        my $to_return;
        my $pattern = $self->quote->{pattern};
        my $interpolated_pattern = $self->quote->{interpolated_pattern};
        while( length $$buffer ) {
            my $c = substr $$buffer, 0, 1, '';

            if( $pattern || $interpolated_pattern ) {
                if( $c eq '\\' ) {
                    my $qc = substr $$buffer, 0, 1;

                    if( my $qp = $quoted_pattern{$qc} ) {
                        substr $$buffer, 0, 1, ''; # eat character
                        if( $pattern ) {
                            $to_return = [ T_PATTERN, $qc, $qp ];
                        } else {
                            $v .= $c . $qc;
                            next;
                        }
                    }
                } elsif( $c eq '(' && !$interpolated_pattern ) {
                    my $nc = substr $$buffer, 0, 1;

                    if( $nc eq '?' ) {
                        substr $$buffer, 0, 1, ''; # eat character
                        $to_return = [ T_PATTERN, '(?' ];
                    } else {
                        $to_return = [ T_PATTERN, '(' ];
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

                    $to_return = [ T_PATTERN, $c, $special ];
                }
            }

            if( $to_return ) {
                if( length $v ) {
                    $self->unlex( $to_return );
                    return [ T_STRING, $v, 1 ];
                } else {
                    return $to_return;
                }
            }

            if( $c eq '\\' && $self->quote->{interpolate} ) {
                my $qc = substr $$buffer, 0, 1, '';

                if( $qc =~ /^[a-zA-Z]$/ ) {
                    if( $quoted_chars{$qc} ) {
                        $v .= $quoted_chars{$qc};
                    } else {
                        die "Invalid escape '$qc'";
                    }
                } elsif( $qc =~ /^[0-9]$/ ) {
                    die "Unsupported numeric escape";
                } else {
                    $v .= $qc;
                }
            } elsif( $c =~ /^[\$\@]$/ && $self->quote->{interpolate} ) {
                if(    $interpolated_pattern
                    && (    !length( $$buffer )
                         || index( "()| \r\n\t",
                                   substr( $$buffer, 0, 1 ) ) != -1 ) ) {
                    $v .= $c;
                } elsif( length $v ) {
                    $self->unlex( [ $ops{$c}, $c ] );

                    return [ T_STRING, $v ];
                } else {
                    return [ $ops{$c}, $c ];
                }
            } else {
                $v .= $c;
            }
        }
    }

    die "Can't get there";
}

sub lex_identifier {
    my( $self ) = @_;

    if( @{$self->tokens} ) {
        return undef if $self->tokens->[-1]->[0] != T_ID;
        return pop @{$self->tokens};
    }

    local $_ = $self->buffer;

    _skip_space( $self )
      if defined( $$_ ) && $$_ =~ /^[\s\r\n]/;

    return [ T_EOF, '' ] unless length $$_;

    my $id;
    $$_ =~ s/^\^([A-Z\[\\\]^_?])//x and do {
        $id = [ T_ID, chr( ord( $1 ) - ord( 'A' ) + 1 ) ];
    };
    $id or $$_ =~ s/^::(?=\W)//x and do {
        $id = [ T_ID, 'main::' ];
    };
    $id or $$_ =~ s/^(\'|::)?(\w+)//x and do {
        my $ids = defined $1 ? '::' . $2 : $2;

        while( $$_ =~ s/^::(\w*)|^\'(\w+)// ) {
            $ids .= '::' . ( defined $1 ? $1 : $2 );
        }

        $id = [ T_ID, $ids ];
    };
    $id or $$_ =~ s/^{\^([A-Z\[\\\]^_?])(\w*)}//x and do {
        $id = [ T_ID, chr( ord( $1 ) - ord( 'A' ) + 1 ) . $2 ];
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
            $id = [ T_ID, $maybe_id ];
        } elsif( $$_ =~ /^\[|^\{/ ) {
            ++$self->{brackets};
            push @{$self->{pending_brackets}}, $self->{brackets};
            $id = [ T_ID, $maybe_id ];
        } else {
            # not a simple identifier
            $$_ = '{' . $spcbef . $maybe_id . $spcaft . $$_;
            return undef;
        }
    };
    $id or $$_ =~ s/^(\W)(?=\W)// and do {
        $id = [ T_ID, $1 ];
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

                return [ T_NUMBER, $num, $flags ];
            } else {
                die "Invalid binary digit";
            }
        } elsif( $1 eq 'x' ) {
            # hexadecimal number
            if( $$_ =~ s/^([0-9a-fA-F]+)// ) {
                $flags = NUM_HEXADECIMAL;
                $num .= $1;

                return [ T_NUMBER, $num, $flags ];
            } else {
                die "Invalid hexadecimal digit";
            }
        } else {
            # maybe octal number
            if( $$_ =~ s/^([0-7]+)// ) {
                $flags = NUM_OCTAL;
                $num .= $1;
                $$_ =~ /^[89]/ and die "Invalid octal digit";

                return [ T_NUMBER, $num, $flags ];
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
    $$_ =~ /^\.\./ and return [ T_NUMBER, $num, $flags ];
    $$_ =~ s/^\.(\d*)//x and do {
        $flags = NUM_FLOAT;
        $num = '0' unless length $num;
        $num .= ".$1" if length $1;
    };
    $$_ =~ s/^[eE]([+-]?\d+)//x and do {
        $flags = NUM_FLOAT;
        $num .= "e$1";
    };

    return [ T_NUMBER, $num, $flags ];
}

my %quote_end = qw!( ) { } [ ] < >!;
my %regex_flags =
  ( m  => 'msixopgc',
    qr => 'msixop',
    s  => 'msixopgce',
    tr => 'cds',
    y  => 'cds',
    );

sub _find_end {
    my( $self, $op, $quote_start ) = @_;

    local $_ = $self->buffer;

    if( $op && !$quote_start ) {
        if( $$_ =~ /^[\s\r\n]/ ) {
            _skip_space( $self );
        }
        # if we find a fat comma, we got a string constant, not the
        # start of a quoted string!
        $$_ =~ /^=>/ and return [ T_STRING, $op ];
        $$_ =~ s/^(\S)// or die;
        $quote_start = $1;
    }

    my $quote_end = $quote_end{$quote_start} || $quote_start;
    my $paired = $quote_start eq $quote_end ? 0 : 1;
    my $is_regex = $regex_flags{$op};

    my( $interpolated, $delim_count, $str ) = ( 0, 1, '' );
    SCAN_END: for(;;) {
        $self->_fill_buffer unless length $$_;
        die "EOF while parsing quoted string" unless length $$_;

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

    return [ $is_regex ? T_PATTERN : T_QUOTE,
             $op, $quote_start, \$str, undef, undef, $interpolated ];
}

sub _prepare_sublex {
    my( $self, $op, $quote_start ) = @_;
    my $token = _find_end( $self, $op, $quote_start );

    # oops, found fat comma: not a quote-like operator
    return $token if $token->[0] == T_STRING;

    # scan second part of substitution/transliteration
    if( $op eq 's' || $op eq 'tr' || $op eq 'y' ) {
        my $quote_char = $quote_end{$token->[2]} ? undef : $token->[2];
        my $rest = _find_end( $self, $op, $quote_char );
        $token->[4] = $rest;
    }
    if( my $flags = $regex_flags{$op} ) {
        local $_ = $self->buffer;

        my @flags;
        while( length( $$_ ) && index( $flags, substr( $$_, 0, 1 ) ) >= 0 ) {
            push @flags, substr $$_, 0, 1, '';
        }
        $token->[5] = \@flags if @flags;
    }

    return $token;
}

sub _prepare_sublex_heredoc {
    my( $self ) = @_;
    my( $quote, $str, $end ) = ( '"', '' );

    local $_ = $self->buffer;

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
        warn "Deprecated" unless $1;
        $end = $1;
    }
    $end .= "\n";

    my $stream = $self->stream;
    my $finished = 0;
    while( defined( my $line = readline $stream ) ) {
        if( $line eq $end ) {
            $finished = 1;
            last;
        }
        $str .= $line;
    }

    Carp::confess "EOF while looking for terminator '$end'" unless $finished;

    return [ T_QUOTE, $quote, $quote, \$str ];
}

sub lex {
    my( $self, $expect ) = ( @_, X_NOTHING );

    return pop @{$self->tokens} if @{$self->tokens};

    # skip blanks and comments
    _skip_space( $self );

    local $_ = $self->buffer;
    return [ T_EOF, '' ] unless length $$_;

    $$_ =~ /^\d|^\.\d/ and return $self->lex_number;
    $$_ =~ s/^(q|qq|qx|qw|m|qr|s|tr|y)(?=\W)//x and
        return _prepare_sublex( $self, $1, undef );
    $$_ =~ s/^(::)?(\w+)//x and do {
        my $ids = ( $1 || '' ) . $2;
        my $no_space = $$_ !~ /^[\s\r\n]/;

        # look ahead for fat comma
        _skip_space( $self );
        if( $$_ =~ /^=>/ ) {
            return [ T_STRING, $ids ];
        }
        my $op = $ops{$ids};
        my $type =  $op                 ? T_KEYWORD :
                    $keywords{$ids}     ? T_KEYWORD :
                    $overridables{$ids} ? T_OVERRIDABLE :
                                          T_ID;

        if( $no_space && (    $$_ =~ /^::/
                           || ( $type == T_ID && $$_ =~ /^'\w/ ) ) ) {
            while( $$_ =~ s/^::(\w*)|^\'(\w+)// ) {
                $ids .= '::' . ( defined $1 ? $1 : $2 );
            }
            if( $ids =~ s/::$// ) {
                # warn for nonexistent package
            }
            $op = undef;
            $type = T_ID;
        }

        if( $op ) {
            return [ $op, $ids ];
        }
        return [ T_ID, $ids, $type ];
    };
    $$_ =~ s/^(["'`])//x and return _prepare_sublex( $self, $1, $1 );
    $$_ =~ /^</ and $expect != X_OPERATOR and do {
        $$_ =~ s/^(<<|<)//x;

        if( $1 eq '<' ) {
            return _prepare_sublex( $self, '<', '<' );
        } elsif( $1 eq '<<' ) {
            return _prepare_sublex_heredoc( $self );
        }
    };
    $$_ =~ s/^(<=|>=|==|!=|=>|->
                |=~|!~
                |\.\.|\.\.\.
                |\+\+|\-\-
                |\+=|\-=|\*=|\/=
                |\&\&|\|\|)//x and return [ $ops{$1}, $1 ];
    $$_ =~ s/^\$//x and do {
        if( $$_ =~ /^\#/ ) {
            my $id = $self->lex_identifier;

            if( $id ) {
                $self->unlex( $id );
            } else {
                $$_ =~ s/^\#//x;
                return [ $ops{'$#'}, '$#' ];
            }
        }
        return [ $ops{'$'}, '$' ];
    };
    $$_ =~ s/^([\*%@&])//x and do {
        return [ $ops{$1}, $1 ];
    };
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
                return [ T_OPHASH, '{' ];
            } elsif( $expect == X_OPERATOR ) {
                # autoquote literal strings in hash subscripts
                if( $$_ =~ s/^\s*([[:alpha:]_]+)\s*\}// ) {
                    $self->unlex( [ T_CLBRK, '}' ] );
                    $self->unlex( [ T_STRING, $1 ] );
                }
            } elsif( $expect != X_BLOCK ) {
                # try to guess if it is a block or anonymous hash
                $self->_skip_space;

                if( $$_ =~ /^}/ ) {
                    return [ T_OPHASH, '{' ];
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
                        || ( $$_ =~ /^,/ && $next->[0] != T_ID ) ) {
                        return [ T_OPHASH, '{' ];
                    }
                }
            }
        }

        return [ $ops{$brack}, $brack ];
    };
    $$_ =~ s/^\///x and do {
        if( $expect == X_TERM || $expect == X_STATE ) {
            return _prepare_sublex( $self, 'm', '/' );
        } else {
            return [ T_SLASH, '/' ];
        }
    };
    $$_ =~ s/^([:;,()\?<>!=\/\\\+\-\.])//x and return [ $ops{$1}, $1 ];

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
