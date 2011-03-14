package Language::P::Parser::KeywordList;

use strict;
use warnings;
use Exporter 'import';

use Language::P::Constants qw(:all);

my %types =
  ( k    => 'T_KEYWORD',
    b    => 'T_BUILTIN',
    o    => 'T_OVERRIDABLE',
    );

my %special =
  ( topic        => PROTO_DEFAULT_ARG,
    handle       => PROTO_FILEHANDLE,
    block        => PROTO_BLOCK,
    indirect     => PROTO_INDIROBJ,
    pattern      => PROTO_PATTERN,
    unary_list   => PROTO_UNARY_LIST,
    sub_name     => PROTO_SUBNAME,
    );

my %proto =
  ( scalar       => PROTO_SCALAR,
    list         => PROTO_ARRAY,
    hash         => PROTO_HASH,
    code         => PROTO_SUB,
    glob         => PROTO_GLOB,
    reference    => PROTO_REFERENCE,
    make_glob    => PROTO_MAKE_GLOB,
    make_array   => PROTO_MAKE_ARRAY,
    make_hash    => PROTO_MAKE_HASH,
    any          => PROTO_ANY,
    amper        => PROTO_AMPER,
    );

sub parse_table {
    my( %kw, @keywords, @builtins, @overridables );
    while( defined( my $line = readline DATA ) ) {
        $line =~ s/#.*$//;
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        next unless length $line;
        my( $keyword, $type, $id, $min, $max, $special, $proto ) = split /\s+/, $line;
        my $has_proto = ( $id && $id eq 'default' ) || defined $min;

        if( $id && $id eq 'default' ) {
            $min = 0;
            $max = -1;
            $special = 0;
            $proto = [ PROTO_ARRAY ];
        } elsif( $has_proto ) {
            my $sp_temp = 0;
            foreach my $c ( split /\+/, $special ) {
                next if $c eq '0';
                die "Invalid special flag '$c'" unless exists $special{$c};
                $sp_temp |= $special{$c};
            }
            $special = $sp_temp;

            my @proto;
            foreach my $a ( split /,/, $proto ) {
                push @proto, 0;

                foreach my $c ( split /\+/, $a ) {
                    next if $c eq '0';
                    die "Invalid prototype flag '$c'" unless exists $proto{$c};
                    $proto[-1] |= $proto{$c};
                }
            }
            $proto = \@proto;

            die "Invalid min value: -1 with max != -1" if $min == -1 && $max != -1;
            die "Invalid max value: max < min" if $max != -1 && $max < $min;
        }

        if( !$id || $id eq 'same' || $id eq 'default' ) {
            $id = "KEY_" . uc $keyword;
        }

        push @keywords, $id if $type eq 'k';
        push @builtins, $id if $type eq 'b';
        push @overridables, $id if $type eq 'o';
        $kw{$keyword} = [ $types{$type}, $id, $min, $max, $special, $proto ];
    }

    return \%kw, \@keywords, \@builtins, \@overridables;
}

1;

__DATA__

# keyword type:
# k: keyword
# b: non-overridable builtin
# o: overridable builtin

# special:
# topic:       default to $_
# handle:      indirect filehandle (es. print)
# block:       may take a block (es. eval)
# indirect:    block or expression (es. map)
# pattern:     the first argument might be a pattern (es. split)
# unary_list:  unary operator that can take a list (es. scalar)

# prototype:
# scalar:      scalar value
# list:        list value
# hash:        hash value
# code:        subroutine value
# glob:        glob value
# reference:   take reference to arg
# force_glob:  force bareword to glob
# force_array: force bareword to array
# force_hash:  force bareword to hash
# any:         any espression
# amper:       take &foo as sub reference (es. defined)

# name,             type,   op name,          min/max,  special,  prototype

if                  k       
unless              k       
else                k       
elsif               k       
for                 k       
foreach             k       
while               k       
until               k       
continue            k       
do                  k       
use                 k       
no                  k       
last                k       OP_LAST
next                k       OP_NEXT
redo                k       OP_REDO
goto                k       OP_GOTO
my                  k       OP_MY
our                 k       OP_OUR
state               k       OP_STATE
local               k       
sub                 k       
eval                b       
package             k       
require             b       KEY_REQUIRE_FILE     1   1  0             any

defined             b       same                 1   1  topic         any+amper
delete              b       same                 1   1  0             scalar
eval                b       same                 1   1  topic+block   any
exists              b       same                 1   1  0             any+amper
grep                b       same                 2  -1  indirect      list
map                 b       same                 2  -1  indirect      list
pos                 b       same                 1   1  topic         scalar
print               b       same                 1  -1  topic+handle  list
return              b       default
scalar              b       same                 1   1  unary_list    any
sort                b       same                 1  -1  indirect+sub_name  list
split               b       KEY_RX_SPLIT         0   4  pattern       scalar,scalar,scalar,scalar
undef               b       same                 0   1  0             any
chop                b       same                 0  -1  topic         any

abs                 o       same                 1   1  topic         scalar
binmode             o       same                 1   2  0             make_glob,scalar
bless               o       same                 1   2  0             scalar,scalar
caller              o       same                 0   1  0             scalar
chdir               o       same                 0   1  0             scalar+make_glob
chr                 o       same                 1   1  topic         scalar
close               o       same                 0   1  0             make_glob
die                 o       default
each                o       same                 1   1  0             make_hash+reference
glob                o       same                 1  -1  topic         scalar
hex                 o       same                 1   1  topic         scalar
index               o       same                 2   3  0             scalar,scalar,scalar
int                 o       same                 1   1  topic         scalar
join                o       same                 1  -1  0             scalar,list
keys                o       same                 1   1  0             make_hash+reference
lc                  o       same                 1   1  topic         scalar
lcfirst             o       same                 1   1  topic         scalar
length              o       same                 1   1  topic         scalar
oct                 o       same                 1   1  topic         scalar
open                o       same                 1  -1  0             make_glob,scalar,list
ord                 o       same                 1   1  topic         scalar
pipe                o       same                 2   2  0             make_glob,make_glob
pop                 o       same                 1   1  topic         make_array+reference
push                o       same                 1  -1  0             make_array+reference
quotemeta           o       same                 1   1  topic         scalar
readline            o       same                 0   1  0             make_glob
ref                 o       KEY_REFTYPE          0   1  topic         scalar
reverse             o       default
rmdir               o       same                 1   1  topic         scalar
shift               o       same                 1   1  topic         make_array+reference
splice              o       same                 1  -1  0             make_array+reference,scalar,scalar,list
sprintf             o       same                 1  -1  0             scalar,list
substr              o       same                 2   4  0             scalar,scalar,scalar,scalar
uc                  o       same                 1   1  topic         scalar
ucfirst             o       same                 1   1  topic         scalar
unlink              o       same                 1  -1  topic         list
unshift             o       same                 1  -1  0             make_array+reference
values              o       same                 1   1  0             make_hash+reference
vec                 o       same                 3   3  0             scalar,scalar,scalar
wantarray           o       same                 0   0  0             0
warn                o       default
