package Language::P::Lexer;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(stream buffer tokens
                                 ) );
__PACKAGE__->mk_accessors( qw(quote) );

use constant
  { X_NOTHING  => 0,
    X_STATE    => 1,
    X_TERM     => 2,
    X_OPERATOR => 3,

    LEX_NORMAL => 1,
    LEX_QUOTED => 2,

    T_ID          => 1,
    T_KEYWORD     => 2,
    T_OVERRIDABLE => 3,
    };

use Exporter qw(import);

our @EXPORT_OK =
  qw(X_NOTHING X_STATE X_TERM X_OPERATOR
     T_ID T_SPECIAL T_NUMBER T_STRING T_KEYWORD T_OVERRIDABLE);
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
  ( ';'   => 'SEMICOLON',
    ':'   => 'COLON',
    ','   => 'COMMA',
    '=>'  => 'COMMA',
    '('   => 'OPPAR',
    ')'   => 'CLPAR',
    '['   => 'OPSQ',
    ']'   => 'CLSQ',
    '{'   => 'OPBRK',
    '}'   => 'CLBRK',
    '?'   => 'INTERR',
    '!'   => 'NOT',
    '<'   => 'OPAN',
    'lt'  => 'SLESS',
    '>'   => 'CLAN',
    'gt'  => 'SGREAT',
    '='   => 'EQUAL',
    '<='  => 'LESSEQUAL',
    'le'  => 'SLESSEQUAL',
    '>='  => 'GREATEQUAL',
    'ge'  => 'SGREATEQUAL',
    '=='  => 'EQUALEQUAL',
    'eq'  => 'SEQUALEQUAL',
    '!='  => 'NOTEQUAL',
    'ne'  => 'SNOTEQUAL',
    '/'   => 'SLASH',
    '\\'  => 'BACKSLASH',
    '..'  => 'DOTDOT',
    '...' => 'DOTDOTDOT',
    '+'   => 'PLUS',
    '-'   => 'MINUS',
    '*'   => 'STAR',
    '$'   => 'DOLLAR',
    '%'   => 'PERCENT',
    '@'   => 'AT',
    '&'   => 'AMPERSAND',
    '++'  => 'PLUSPLUS',
    '--'  => 'MINUSMINUS',
    '&&'  => 'ANDAND',
    '||'  => 'OROR',
    '$#'  => 'ARYLEN',
    '->'  => 'ARROW',
    'and' => 'ANDANDLOW',
    'or'  => 'ORORLOW',
    'not' => 'NOTLOW',
    'xor' => 'XORLOW',
    );

my %keywords = map { ( $_ => 1 ) }
  qw(if unless else elsif for foreach while until do last next redo
     my our state sub
     ),
  qw(print defined return undef);
my %overridables = map { ( $_ => 1 ) }
  qw(unlink glob readline die open pipe chdir rmdir glob readline
     close binmode);

my %quoted_chars =
  ( 'n' => "\n",
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

sub _quoted_code_lookahead {
    my( $self ) = @_;

    # FIXME intuit_more
    # force the parser to stop parsing code
    my $token = $self->lex_quote;
    $self->unlex( $token );

    return 0;
}

sub lex_quote {
    my( $self ) = @_;

    return pop @{$self->tokens} if @{$self->tokens};

    my $buffer = $self->buffer;
    my $v = '';
    for(;;) {
        $self->_fill_buffer unless length $$buffer;
        unless( length $$buffer ) {
            if( length $v ) {
                $self->unlex( [ 'SPECIAL', 'EOF' ] );
                return [ 'STRING', $v, 1 ];
            } else {
                return [ 'SPECIAL', 'EOF' ];
            }
        }

        my $to_return;
        while( length $$buffer ) {
            my $c = substr $$buffer, 0, 1, '';

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
                if( length $v ) {
                    $self->unlex( [ $ops{$c}, $c ] );

                    return [ 'STRING', $v ];
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
        return undef if $self->tokens->[-1]->[0] ne 'ID';
        return pop @{$self->tokens};
    }

    local $_ = $self->buffer;

    _skip_space( $self )
      if defined( $$_ ) && $$_ =~ /^[\s\r\n]/;

    return [ 'SPECIAL', 'EOF' ] unless length $$_;

    my $id;
    $$_ =~ s/^\^([A-Z\[\\\]^_?])//x and do {
        $id = [ 'ID', chr( ord( $1 ) - ord( 'A' ) + 1 ) ];
    };
    $id or $$_ =~ s/^(\w+)//x and do {
        $id = [ 'ID', $1 ];
    };
    $id or $$_ =~ s/^{\^([A-Z\[\\\]^_?])(\w*)}//x and do {
        $id = [ 'ID', chr( ord( $1 ) - ord( 'A' ) + 1 ) . $2 ];
    };
    $id or $$_ =~ s/^{//x and do {
        my $spcbef = _skip_space( $self );
        $$_ =~ s/^(\w+)//x and my $maybe_id = $1;
        my $spcaft = _skip_space( $self );

        if( $$_ =~ s/^}//x ) {
            $id = [ 'ID', $maybe_id ];
        } else {
            # not a simple identifier
            $$_ = '{' . $spcbef . $maybe_id . $spcaft . $$_;
            return undef;
        }
    };
    $id or $$_ =~ s/^(\W)(?=\W)// and do {
        $id = [ 'ID', $1 ];
    };

    if( $id && $self->quote && $self->{brackets} == 0 ) {
        _quoted_code_lookahead( $self );
    }

    return $id;
}

my %quote_end = qw!( ) { } [ ] < >!;

sub _find_end {
    my( $self, $op, $quote_start ) = @_;

    local $_ = $self->buffer;

    if( $op && !$quote_start ) {
        if( $$_ =~ /^[\s\r\n]/ ) {
            _skip_space( $self );
        }
        $$_ =~ s/(\S)// or die;
        $quote_start = $1;
    }

    my $quote_end = $quote_end{$quote_start} || $quote_start;
    my $paired = $quote_start eq $quote_end ? 0 : 1;

    my( $delim_count, $str ) = ( 1, '' );
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
            }

            $str .= $c;
        }
    }

    my $lexer = Language::P::Lexer->new( { string => \$str } );

    return [ 'QUOTE',
             $op, $quote_start, $lexer ];
}

sub _prepare_sublex {
    my( $self, $op, $quote_start ) = @_;
    my $token = _find_end( $self, $op, $quote_start );

    return $token;
}

sub lex {
    my( $self, $expect ) = ( @_, X_NOTHING );

    return pop @{$self->tokens} if @{$self->tokens};

    # skip blanks and comments
    _skip_space( $self );

    local $_ = $self->buffer;
    return [ 'SPECIAL', 'EOF' ] unless length $$_;

    $$_ =~ s/^([-+]?[\.\d]+)//x and return [ 'NUMBER', $1 ];
    $$_ =~ s/^(q|qq|qx|qw|m|qr|s|tr|y)(?=\W)//x and
        return _prepare_sublex( $self, $1, undef );
    $$_ =~ s/^(\w+)//x and do {
        if( $ops{$1} ) {
            return [ $ops{$1}, $1 ];
        }
        return [ 'ID', $1, $keywords{$1}     ? T_KEYWORD :
                           $overridables{$1} ? T_OVERRIDABLE :
                                               T_ID
                 ];
    };
    $$_ =~ s/^(["'`])//x and return _prepare_sublex( $self, $1, $1 );
    $$_ =~ /^</ and $expect != X_OPERATOR and do {
        $$_ =~ s/^(<<|<)//x;

        if( $1 eq '<' ) {
            return _prepare_sublex( $self, '<', '<' );
        }
    };
    $$_ =~ s/^(<=|>=|==|!=|=>|->
                |\.\.|\.\.\.
                |\+\+|\-\-
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
    if( $self->quote ) {
        $$_ =~ s/^([{}\[\]])// and do {
            if( $1 eq '[' || $1 eq '{' ) {
                ++$self->{brackets};
            } else {
                --$self->{brackets};

                if( $self->{brackets} == 0 ) {
                    _quoted_code_lookahead( $self );
                }
            }

            return [ $ops{$1}, $1 ];
        };
    }
    $$_ =~ s/^([:;,(){}\[\]\?<>!=\/\\\+\-])//x and return [ $ops{$1}, $1 ];

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
