package Opcodes;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(write_opcodes);

use Language::P::Keywords qw(:all);
use Data::Dumper;

my %flag_map =
  ( 0 => 0,
    u => 1,
    );

sub write_opcodes {
    my( $file ) = @ARGV;

    open my $out, '>', $file;

    my( %op );
    my $num = 1;
    while( defined( my $line = readline Opcodes::DATA ) ) {
        $line =~ s/#.*$//;
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        next unless length $line;
        my( $opcode, $flags, $attrs, $name, $in, $out ) = split /\s+/, $line;

        my $int_flags = 0;
        $int_flags |= $flag_map{$_} foreach split //, $flags || '0';

        undef $attrs if $attrs && $attrs eq 'noattr';
        undef $name  if $name && $name eq 'same';

        if( $attrs ) {
            my( @positional, %named );

            foreach ( split /,/, $attrs ) {
                if( /(\w+)=(\w+)/ ) {
                    $named{$1} = $2;
                } else {
                    push @positional, $_;
                }
            }

            $attrs = [ \@positional, \%named ];
        } else {
            $attrs = [ [], {} ];
        }

        $name ||= $opcode;
        $in ||= 0;
        $out ||= 0;
        $opcode = 'OP_' . uc $opcode;

        $op{$opcode} = [ $name, $in, $out, $attrs, $int_flags ];

        ++$num;
    }

    printf $out <<'EOT';
package Language::P::Opcodes;

use Exporter 'import';
use Language::P::Keywords qw(:all);

our @OPERATIONS;
BEGIN {
    @OPERATIONS = ( qw(
EOT

    foreach my $k ( sort keys %op ) {
        print $out "$k\n";
    }

    printf $out <<'EOT';
    ) );
}

our @EXPORT = ( qw(%%KEYWORD_TO_OP %%NUMBER_TO_NAME @OPERATIONS
                   %%OP_ATTRIBUTES), @OPERATIONS );
our %%EXPORT_TAGS =
  ( all => \@EXPORT,
    );

use constant +
  { FLAG_UNARY => 1,
    map { $OPERATIONS[$_] => $_ + 1 } 0 .. $#OPERATIONS,
    };

our %%NUMBER_TO_NAME =
  (
EOT

    while( my( $k, $v ) = each %op ) {
        printf $out <<'EOT', $k, $v->[0];
    %s() => '%s',
EOT
    }

    printf $out <<'EOT';
    );

our %%KEYWORD_TO_OP =
  (
EOT

    foreach my $k ( sort @OVERRIDABLES, @BUILTINS ) {
        ( my $o = $k ) =~ s/KEY_/OP_/;
        printf $out <<'EOT', $k, $o;
    %s() => %s(),
EOT
    }

    printf $out <<'EOT';
    );

our %%OP_ATTRIBUTES =
  (
EOT

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    while( my( $k, $v ) = each %op ) {
        my $named = Dumper( $v->[3][1] );
        my $positional = Dumper( $v->[3][0] );
        printf $out <<'EOT',
    %s() =>
      { in_args    => %d,
        out_args   => %d,
        named      => %s,
        positional => %s,
        flags      => %d,
        },
EOT
            $k, $v->[1], $v->[2], $named, $positional, $v->[4];
    }

    printf $out <<'EOT';
    );

1;
EOT

}

__DATA__

# flags:
# u: named unary

# opcode            flags   attrs       name                in out
abs                 u       noattr      same                 1   1
add                 0       noattr      same                 2   1
add_assign
array_element       0       noattr      same                 2   1
array_length        0       noattr      array_size           1   1
assign              0       noattr      same                 2   1
backtick
binmode             
bit_and
bit_or
bit_not
bit_xor
call                0       noattr      same                 2   1
chdir               u       noattr      same                 1   1
chr                 u       noattr      same                 1   1
close               
concat_assign       0       noattr      same                 2   1
concatenate         0       noattr      concat               2   1
constant_float      0       noattr      same                 0   1
constant_integer    0       noattr      same                 0   1
constant_regex      0       noattr      same                 0   1
constant_string     0       s           same                 0   1
constant_sub        0       noattr      same                 0   1
constant_undef      0       noattr      same                 0   1
defined             u       noattr      same                 1   1
dereference_array   0       noattr      same                 1   1
dereference_glob    0       noattr      same                 1   1
dereference_hash    0       noattr      same                 1   1
dereference_scalar  0       noattr      same                 1   1
dereference_sub     0       noattr      dereference_subroutine 1 1
die                 
divide
divide_assign
do_file             u       noattr      same                 1   1
dot_dot
dot_dot_dot
dup
end
eval                u       noattr      same                 1   1
eval_regex          u       noattr      same                 1   1
fresh_string        0       s           same                 0   1
ft_atime            u       noattr      same                 1   1
ft_ctime            u       noattr      same                 1   1
ft_eexecutable      u       noattr      same                 1   1
ft_empty            u       noattr      same                 1   1
ft_eowned           u       noattr      same                 1   1
ft_ereadable        u       noattr      same                 1   1
ft_ewritable        u       noattr      same                 1   1
ft_exists           u       noattr      same                 1   1
ft_isascii          u       noattr      same                 1   1
ft_isbinary         u       noattr      same                 1   1
ft_isblockspecial   u       noattr      same                 1   1
ft_ischarspecial    u       noattr      same                 1   1
ft_isdir            u       noattr      same                 1   1
ft_isfile           u       noattr      same                 1   1
ft_ispipe           u       noattr      same                 1   1
ft_issocket         u       noattr      same                 1   1
ft_issymlink        u       noattr      same                 1   1
ft_istty            u       noattr      same                 1   1
ft_mtime            u       noattr      same                 1   1
ft_nonempty         u       noattr      same                 1   1
ft_rexecutable      u       noattr      same                 1   1
ft_rowned           u       noattr      same                 1   1
ft_rreadable        u       noattr      same                 1   1
ft_rwritable        u       noattr      same                 1   1
ft_setgid           u       noattr      same                 1   1
ft_setuid           u       noattr      same                 1   1
ft_sticky           u       noattr      same                 1   1
get
glob                
glob_slot           0       noattr      same                 1   1
glob_slot_set       0       noattr      same                 2   0
global              0       noattr      same                 0   1
grep                
hash_element        0       noattr      same                 2   1
iterator            0       noattr      same                 1   1
iterator_next       0       noattr      same                 1   1
jump
jump_if_f_eq        0       noattr      same                 2   0
jump_if_f_ge        0       noattr      same                 2   0
jump_if_f_gt        0       noattr      same                 2   0
jump_if_f_le        0       noattr      same                 2   0
jump_if_f_lt        0       noattr      same                 2   0
jump_if_f_ne        0       noattr      same                 2   0
jump_if_false       0       noattr      same                 1   0
jump_if_s_eq        0       noattr      same                 2   0
jump_if_s_ge        0       noattr      same                 2   0
jump_if_s_gt        0       noattr      same                 2   0
jump_if_s_le        0       noattr      same                 2   0
jump_if_s_lt        0       noattr      same                 2   0
jump_if_s_ne        0       noattr      same                 2   0
jump_if_true        0       noattr      same                 1   0
jump_if_null        0       noattr      same                 1   0
lexical             0       noattr      same                 0   1
lexical_clear       0       noattr      same                 0   0
lexical_set         0       noattr      same                 1   0
local               
localize_glob_slot  0       noattr      same                 0   1
log_and             0       noattr      same                 2   1
log_not             0       noattr      not                  1   1
log_or              0       noattr      same                 2   1
log_xor             0       noattr      same                 2   1
make_closure        0       noattr      same                 1   1
make_list           0       count=i     same                -1   1
map                 
match               0       noattr      rx_match
minus               0       noattr      negate
modulus
multiply            0       noattr      same                 2   1
multiply_assign
negate
noop
not_match           0       noattr      rx_not_match
num_cmp
num_eq              0       noattr      compare_f_eq_scalar
num_ge              0       noattr      compare_f_ge_scalar
num_gt              0       noattr      compare_f_gt_scalar
num_le              0       noattr      compare_f_le_scalar
num_lt              0       noattr      compare_f_lt_scalar
num_ne              0       noattr      compare_f_ne_scalar
open                
parentheses
phi
pipe                
plus                0       noattr      same                 1   1
pop                 0       noattr      same                 1   0
postdec             0       noattr      same                 1   1
postinc             0       noattr      same                 1   1
power
predec              0       noattr      same                 1   1
preinc              0       noattr      same                 1   1
print               0       noattr      same                 1   1
ql_lt
ql_m
ql_qr
ql_qw
ql_qx
ql_s
ql_tr
readline            u       noattr      same                 1   1
reference
reftype             u       noattr      same                 1   1
repeat
require_file        u       noattr      same                 1   1
restore_glob_slot   0       noattr      same                 0   0
return              0       noattr      same                 1   0
rmdir               
set                 0       noattr      same                 2   0
str_cmp
str_eq              0       noattr      compare_s_eq_scalar
str_ge              0       noattr      compare_s_ge_scalar
str_gt              0       noattr      compare_s_gt_scalar
str_le              0       noattr      compare_s_le_scalar
str_lt              0       noattr      compare_s_lt_scalar
str_ne              0       noattr      compare_s_ne_scalar
stringify
subtract            0       noattr      same                 2   1
subtract_assign
swap                0       noattr      same                 2   2
temporary           0       index=i     same                 0   1
temporary_set       0       noattr      same                 1   0
undef               u       noattr      same                 -1  1
unlink              
vivify_array        0       noattr      same                 1   1
vivify_hash         0       noattr      same                 1   1
vivify_scalar       0       noattr      same                 1   1
wantarray           u       noattr      want                 0   1

rx_accept
rx_capture_end
rx_capture_start
rx_end_special
rx_exact
rx_quantifier
rx_start_group
rx_start_match
rx_start_special
rx_try
