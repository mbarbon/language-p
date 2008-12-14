package Opcodes;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(write_opcodes);

use Language::P::Keywords qw(:all);

sub write_opcodes {
    my( $file ) = @ARGV;

    open my $out, '>', $file;

    my( %op );
    my $num = 1;
    while( defined( my $line = readline Opcodes::DATA ) ) {
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        next unless length $line;
        my( $opcode, $flags, $args, $name ) = split /\s+/, $line;
        undef $args if $args && $args eq '!';

        $name ||= $opcode;
        $opcode = 'OP_' . uc $opcode;

        $op{$opcode} = [ $name ];

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

our @EXPORT = ( qw(%%KEYWORD_TO_OP %%NUMBER_TO_NAME @OPERATIONS), @OPERATIONS );
our %%EXPORT_TAGS =
  ( all => \@EXPORT,
    );

use constant +
  { map { $OPERATIONS[$_] => $_ + 1 } 0 .. $#OPERATIONS,
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

1;
EOT

}

__DATA__

abs                 
add
add_assign
array_element
array_length        0       ! array_size
assign
backtick
binmode             
bit_and
bit_or
bit_xor
call
chdir               
close               
concat_assign
concatenate         0       ! concat
constant_float
constant_integer
constant_regex
constant_string
constant_sub
constant_undef
defined             
dereference_array
dereference_glob
dereference_hash
dereference_scalar
dereference_sub     0       ! dereference_subroutine
die                 
divide
divide_assign
dot_dot
dot_dot_dot
dup
eval                
fresh_string
ft_atime
ft_ctime
ft_eexecutable
ft_empty
ft_eowned
ft_ereadable
ft_ewritable
ft_exists
ft_isascii
ft_isbinary
ft_isblockspecial
ft_ischarspecial
ft_isdir
ft_isfile
ft_ispipe
ft_issocket
ft_issymlink
ft_istty
ft_mtime
ft_nonempty
ft_rexecutable
ft_rowned
ft_rreadable
ft_rwritable
ft_setgid
ft_setuid
ft_sticky
glob                
glob_slot           2       
glob_slot_set
global
grep                
hash_element
iterator
iterator_next
jump
jump_if_f_eq
jump_if_f_ge
jump_if_f_gt
jump_if_f_le
jump_if_f_lt
jump_if_f_ne
jump_if_false
jump_if_s_eq
jump_if_s_ge
jump_if_s_gt
jump_if_s_le
jump_if_s_lt
jump_if_s_ne
jump_if_true
jump_if_undef
lexical
lexical_clear
lexical_set
local
localize_glob_slot
log_and
log_not             0       ! not
log_or
log_xor
make_closure
make_list           1       count
map                 
match               0       ! rx_match
minus               0       ! negate
modulus
multiply
multiply_assign
negate
not
not_match
num_cmp
num_eq              0       ! compare_f_eq_scalar
num_ge              0       ! compare_f_ge_scalar
num_gt              0       ! compare_f_gt_scalar
num_le              0       ! compare_f_le_scalar
num_lt              0       ! compare_f_lt_scalar
num_ne              0       ! compare_f_ne_scalar
open                
parentheses
pipe                
plus
pop
power
print
print               
ql_lt
ql_m
ql_qr
ql_qw
ql_qx
ql_s
ql_tr
readline            
reference
repeat
restore_glob_slot
return              
rmdir               
str_cmp
str_eq              0       ! compare_s_eq_scalar
str_ge              0       ! compare_s_ge_scalar
str_gt              0       ! compare_s_gt_scalar
str_le              0       ! compare_s_le_scalar
str_lt              0       ! compare_s_lt_scalar
str_ne              0       ! compare_s_ne_scalar
stringify
subtract
subtract_assign
swap
temporary           1       index
temporary_set
undef               
unlink              
wantarray           0 ! want

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
