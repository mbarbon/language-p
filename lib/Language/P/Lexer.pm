package Language::P::Lexer;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(stream buffer tokens
                                 _start_of_line) );

use constant
  { X_NOTHING  => 0,
    X_STATE    => 1,
    X_TERM     => 2,
    X_OPERATOR => 3,
    };

use Exporter qw(import);

our @EXPORT_OK =
  qw(X_NOTHING X_STATE X_TERM X_OPERATOR
     T_ID T_SPECIAL T_NUMBER T_STRING T_KEYWORD);
our %EXPORT_TAGS =
  ( all  => \@EXPORT_OK,
    );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );
    my $a = "";

    $self->{buffer} = \$a;
    $self->{_start_of_line} = 1;
    $self->{tokens} = [];

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
    ','   => 'COMMA',
    '=>'  => 'FATARROW',
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
    );

my %keywords = map { ( $_ => 1 ) }
  qw(if unless else elsif for foreach while until do last next redo
     my our state sub
     );

my %quoted_chars =
  ( 'n' => "\n",
    );

sub lex_quote {
    my( $self, $interpolate, $terminator ) = @_;

    return pop @{$self->tokens} if @{$self->tokens};

    my $buffer = $self->buffer;
    my $v = '';
    for(;;) {
        $self->_fill_buffer unless length $$buffer;
        return [ 'SPECIAL', 'EOF' ] unless length $$buffer;

        while( length $$buffer ) {
            my $c = substr $$buffer, 0, 1, '';

            if( $c eq $terminator ) {
                $self->unlex( [ 'QUOTE', $c ] );
                return [ 'STRING', $v, 1 ];
            }

            if( $c eq '\\' ) {
                my $qc = substr $$buffer, 0, 1, '';

                if( $qc =~ /[a-zA-Z]/ ) {
                    if( $quoted_chars{$qc} ) {
                        $v .= $quoted_chars{$qc};
                    } else {
                        die "Invalid escape '$qc'";
                    }
                } elsif( $qc =~ /[0-9]/ ) {
                    die "Unsupported numeric escape";
                } else {
                    $v .= $qc;
                }
            } else {
                $v .= $c;
            }
        }
    }

    die "Can't get there";
}

sub lex {
    my( $self, $expect ) = ( @_, X_NOTHING );

    return pop @{$self->tokens} if @{$self->tokens};

    my $buffer = $self->buffer;

    # skip blanks and comments
    for(;;) {
        $self->_fill_buffer unless length $$buffer;
        return [ 'SPECIAL', 'EOF' ] unless length $$buffer;

        $$buffer =~ s/^[\s\r\n]+//;
        $$buffer =~ s/^#.*\n//;

        last if length $$buffer;
    }

    local $_ = $buffer;
    $$_ =~ s/^([\.\d]+)//x and return [ 'NUMBER', $1 ];
    $$_ =~ s/^(\w+)//x and do {
        if( $ops{$1} ) {
            return [ $ops{$1}, $1 ];
        }
        return [ $keywords{$1} ? 'KEYWORD' : 'ID', $1 ];
    };
    $$_ =~ s/^(["'])//x and return [ 'QUOTE', $1, $1 ];
    $$_ =~ s/^(<=|>=|==|!=|\$\#|=>|->
                |\.\.|\.\.\.
                |\+\+|\-\-
                |\&\&|\|\|)//x and return [ $ops{$1}, $1 ];
    $$_ =~ s/^([\*\$%@&])//x and do {
        return [ $ops{$1}, $1 ];
    };
    $$_ =~ s/^([;,(){}\[\]\?<>!=\/\\\+\-])//x and return [ $ops{$1}, $1 ];

    die "Lexer error: $$_";
}

sub _fill_buffer {
    my( $self ) = @_;
    my $buffer = $self->buffer;
    my $l = readline $self->stream;

    if( defined $l ) {
        $$buffer .= $l;
    }
}

1;
