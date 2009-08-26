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
    v => 3, # variadic implies unary
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
        my( $opcode, $flags, $name, $in, $out, $attrs ) = split /\s+/, $line;

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

our @EXPORT = ( qw(%%KEYWORD_TO_OP %%OP_TO_KEYWORD %%NUMBER_TO_NAME @OPERATIONS
                   %%OP_ATTRIBUTES), @OPERATIONS );
our %%EXPORT_TAGS =
  ( all => \@EXPORT,
    );

use constant +
  { FLAG_UNARY    => 1,
    FLAG_VARIADIC => 2,
EOT

    my $index = 1;
    foreach my $k ( sort keys %op ) {
        print $out <<EOT;
    $k => $index,
EOT
        ++$index;
    }

    printf $out <<'EOT';
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
        $o =~ s/^OP_(PUSH|POP|SHIFT|UNSHIFT)/OP_ARRAY_$1/;
        printf $out <<'EOT', $k, $o;
    %s() => %s(),
EOT
    }

    printf $out <<'EOT';
    );

our %%OP_TO_KEYWORD = reverse %%KEYWORD_TO_OP;

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
# v: variadic

# opcode            flags   name                in out  attrs
abs                 u       same                 1   1  noattr
add                 0       same                 2   1  noattr
add_assign          0       same                 2   1  noattr
anonymous_array     0       same                 1   1  noattr
anonymous_hash      0       same                 1   1  noattr
array_element       0       same                 2   1  noattr
array_length        0       array_size           1   1  noattr
array_pop           u       same                 1   1  noattr
array_push          0       same                 2   1  noattr
array_shift         u       same                 1   1  noattr
array_slice         0       same                 2   1  noattr
array_unshift       0       same                 2   1  noattr
assign              0       same                 2   1  noattr
backtick            0       same                 1   1  noattr
binmode             u       same                 1   1  noattr
bit_and             0       same                 2   1  noattr
bit_and_assign      0       same                 2   1  noattr
bit_or              0       same                 2   1  noattr
bit_or_assign       0       same                 2   1  noattr
bit_not             0       same                 1   1  noattr
bit_xor             0       same                 2   1  noattr
bit_xor_assign      0       same                 2   1  noattr
bless               u       same                 2   1  noattr
call                0       same                 2   1  noattr
call_method         0       same                 1   1  noattr
call_method_indirect 0      same                 2   1  noattr
caller              v       same                -1   1  noattr
chdir               u       same                 1   1  noattr
chr                 u       same                 1   1  noattr
close               u       same                 1   1  noattr
concatenate_assign  0       concat_assign        2   1  noattr
concatenate         0       concat               2   1  noattr
constant_float      0       same                 0   1  value=f
constant_integer    0       same                 0   1  value=i
constant_regex      0       same                 0   1  value=r
constant_string     0       same                 0   1  value=s
constant_sub        0       same                 0   1  value=c
constant_undef      0       same                 0   1  noattr
defined             u       same                 1   1  noattr
dereference_array   0       same                 1   1  noattr
dereference_glob    0       same                 1   1  noattr
dereference_hash    0       same                 1   1  noattr
dereference_scalar  0       same                 1   1  noattr
dereference_sub     0       dereference_subroutine 1 1  noattr
die                 0       same                 1   1  noattr
divide              0       same                 2   1  noattr
divide_assign       0       same                 2   1  noattr
do_file             u       same                 1   1  noattr
dot_dot             0       same                 2   1  noattr
dot_dot_dot         0       same                 2   1  noattr
dup                 0       same                 1   2  noattr
end                 0       same                 0   0  noattr
eval                u       same                 1   1  noattr
eval_regex          u       same                 1   1  noattr
exists              u       same                 1   1  noattr
exists_array        u       same                 2   1  noattr
exists_hash         u       same                 2   1  noattr
find_method         u       same                 1   1  noattr
fresh_string        0       same                 0   1  value=s
ft_atime            u       same                 1   1  noattr
ft_ctime            u       same                 1   1  noattr
ft_eexecutable      u       same                 1   1  noattr
ft_empty            u       same                 1   1  noattr
ft_eowned           u       same                 1   1  noattr
ft_ereadable        u       same                 1   1  noattr
ft_ewritable        u       same                 1   1  noattr
ft_exists           u       same                 1   1  noattr
ft_isascii          u       same                 1   1  noattr
ft_isbinary         u       same                 1   1  noattr
ft_isblockspecial   u       same                 1   1  noattr
ft_ischarspecial    u       same                 1   1  noattr
ft_isdir            u       same                 1   1  noattr
ft_isfile           u       same                 1   1  noattr
ft_ispipe           u       same                 1   1  noattr
ft_issocket         u       same                 1   1  noattr
ft_issymlink        u       same                 1   1  noattr
ft_istty            u       same                 1   1  noattr
ft_mtime            u       same                 1   1  noattr
ft_nonempty         u       same                 1   1  noattr
ft_rexecutable      u       same                 1   1  noattr
ft_rowned           u       same                 1   1  noattr
ft_rreadable        u       same                 1   1  noattr
ft_rwritable        u       same                 1   1  noattr
ft_setgid           u       same                 1   1  noattr
ft_setuid           u       same                 1   1  noattr
ft_sticky           u       same                 1   1  noattr
get                 0       same                 0   1  index=i
glob                0       same                 1   1  noattr
glob_slot           0       same                 1   1  noattr
glob_slot_set       0       same                 2   0  noattr
global              0       same                 0   1  name=s,slot=i
grep                0       same                 1   1  noattr
hash_element        0       same                 2   1  noattr
hash_slice          0       same                 2   1  noattr
iterator            0       same                 1   1  noattr
iterator_next       0       same                 1   1  noattr
jump                0       same                 0   0  to=b
jump_if_f_eq        0       same                 2   0  to=b
jump_if_f_ge        0       same                 2   0  to=b
jump_if_f_gt        0       same                 2   0  to=b
jump_if_f_le        0       same                 2   0  to=b
jump_if_f_lt        0       same                 2   0  to=b
jump_if_f_ne        0       same                 2   0  to=b
jump_if_false       0       same                 1   0  to=b
jump_if_s_eq        0       same                 2   0  to=b
jump_if_s_ge        0       same                 2   0  to=b
jump_if_s_gt        0       same                 2   0  to=b
jump_if_s_le        0       same                 2   0  to=b
jump_if_s_lt        0       same                 2   0  to=b
jump_if_s_ne        0       same                 2   0  to=b
jump_if_true        0       same                 1   0  to=b
jump_if_null        0       same                 1   0  to=b
lexical             0       same                 0   1  index=i,slot=i
lexical_clear       0       same                 0   0  index=i,slot=i
lexical_set         0       same                 1   0  index=i
lexical_pad         0       same                 0   1  index=i,slot=i
lexical_pad_clear   0       same                 0   0  index=i,slot=i
lexical_pad_set     0       same                 1   0  index=i
list_slice          0       same                 2   1  noattr
local               0       same                 1   1  noattr
localize_glob_slot  0       same                 0   1  noattr
log_and             0       same                 2   1  noattr
log_and_assign      0       same                 2   1  noattr
log_not             0       not                  1   1  noattr
log_or              0       same                 2   1  noattr
log_or_assign       0       same                 2   1  noattr
log_xor             0       same                 2   1  noattr
make_closure        0       same                 1   1  noattr
make_list           0       same                -1   1  noattr
map                 0       same                 1   1  noattr
match               0       rx_match             2   1  noattr
minus               0       negate               1   1  noattr
modulus             0       same                 2   1  noattr
modulus_assign      0       same                 2   1  noattr
multiply            0       same                 2   1  noattr
multiply_assign     0       same                 2   1  noattr
negate              0       same                 1   1  noattr
noop                0       same                 0   0  noattr
not_match           0       rx_not_match         2   1  noattr
num_cmp             0       same                 2   1  noattr
num_eq              0       compare_f_eq_scalar  2   1  noattr
num_ge              0       compare_f_ge_scalar  2   1  noattr
num_gt              0       compare_f_gt_scalar  2   1  noattr
num_le              0       compare_f_le_scalar  2   1  noattr
num_lt              0       compare_f_lt_scalar  2   1  noattr
num_ne              0       compare_f_ne_scalar  2   1  noattr
open                0       same                 1   1  noattr
parentheses         0       same                -1  -1  noattr
phi                 0       same                -1  -1  noattr
pipe                0       same                 2   1  noattr
plus                0       same                 1   1  noattr
pop                 0       same                 1   0  noattr
postdec             0       same                 1   1  noattr
postinc             0       same                 1   1  noattr
power               0       same                 2   1  noattr
power_assign        0       same                 2   1  noattr
predec              0       same                 1   1  noattr
preinc              0       same                 1   1  noattr
print               0       same                 2   1  noattr
ql_lt               0       same                -1  -1  noattr
ql_m                0       same                -1  -1  noattr
ql_qr               0       same                -1  -1  noattr
ql_qw               0       same                -1  -1  noattr
ql_qx               0       same                -1  -1  noattr
ql_s                0       same                -1  -1  noattr
ql_tr               0       same                -1  -1  noattr
readline            u       same                 1   1  noattr
reference           u       same                 1   1  noattr
reftype             u       same                 1   1  noattr
repeat              0       same                 2   1  noattr
repeat_assign       0       same                 2   1  noattr
require_file        u       same                 1   1  noattr
restore_glob_slot   0       same                 0   0  noattr
return              0       same                 1   0  noattr
rmdir               u       same                 1   1  noattr
set                 0       same                 1   0  index=i
scope_enter         0       same                 0   0  scope=i
scope_leave         0       same                 0   0  scope=i
str_cmp             0       same                 2   1  noattr
str_eq              0       compare_s_eq_scalar  2   1  noattr
str_ge              0       compare_s_ge_scalar  2   1  noattr
str_gt              0       compare_s_gt_scalar  2   1  noattr
str_le              0       compare_s_le_scalar  2   1  noattr
str_lt              0       compare_s_lt_scalar  2   1  noattr
str_ne              0       compare_s_ne_scalar  2   1  noattr
stringify           0       same                 1   1  noattr
subtract            0       same                 2   1  noattr
subtract_assign     0       same                 2   1  noattr
swap                0       same                 2   2  noattr
temporary           0       same                 0   1  index=i
temporary_set       0       same                 1   0  noattr
undef               u       same                -1   1  noattr
unlink              0       same                 1   1  noattr
vivify_array        0       same                 1   1  noattr
vivify_hash         0       same                 1   1  noattr
vivify_scalar       0       same                 1   1  noattr
wantarray           u       want                 0   1  noattr

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
