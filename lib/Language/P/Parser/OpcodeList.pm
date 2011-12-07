package Language::P::Parser::OpcodeList;

use strict;
use warnings;

use Language::P::Constants qw(:all);
#use Language::P::Keywords qw(:all);
use Language::P::Parser::KeywordList;

my %flag_map =
  ( 0 => 0,
    u => 1,
    v => 3, # variadic implies unary
    );

sub parse_opdesc {
    my( %op );
    my $num = 1;
    while( defined( my $line = readline DATA ) ) {
        $line =~ s/#.*$//;
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        next unless length $line;
        my( $opcode, $flags, $name, $in, $out, $attrs ) = split /\s+/, $line;
        my $class;
        my $int_flags = 0;
        $int_flags |= $flag_map{$_} foreach split //, $flags || '0';

        undef $attrs if $attrs && $attrs eq 'noattr';
        undef $name  if $name && $name eq 'same';

        if( $attrs ) {
            my( @positional, %named );

            foreach ( split /,/, $attrs ) {
                if( /(\w+)=(\w+)/ ) {
                    $class = $2, next if $1 eq 'class';
                    $named{$1} = $2;
                    push @positional, $1, $2;
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

        $op{$opcode} = [ $name, $in, $out, $attrs, $int_flags, $class ];

        ++$num;
    }

    return \%op;
}

sub group_opcode_numbers {
    my( $op ) = @_;

    my %classes;
    while( my( $k, $v ) = each %$op ) {
        my( $attrs, $class ) = ( $v->[3][0], $v->[5] );
        next unless $class;
        push @{$classes{$class} ||= []}, $k;
    }

    return \%classes;
}

sub group_opcode_attributes {
    my( $op ) = @_;

    my %classes;
    while( my( $k, $v ) = each %$op ) {
        my( $attrs, $class ) = ( $v->[3][0], $v->[5] );
        next unless $class;
        next if $classes{$class};
        $classes{$class} = $attrs;
    }

    return \%classes;
}

1;

__DATA__

# flags:
# u: do not pass parameters as a list
# v: variadic

# opcode            flags   name                in out  attrs
abs                 u       same                 1   1  context=i1
add                 0       same                 2   1  context=i1
add_assign          0       same                 2   1  context=i1
anonymous_array     0       same                 1   1  noattr
anonymous_hash      0       same                 1   1  noattr
array_element       0       same                 2   1  context=i1,create=i1,class=ElementAccess
array_length        0       array_size           1   1  context=i1
array_pop           u       same                 1   1  context=i1
array_push          0       same                 2   1  context=i1
array_shift         u       same                 1   1  context=i1
array_slice         0       same                 2   1  context=i1,create=i1,class=ElementAccess
array_unshift       0       same                 2   1  context=i1
assign              0       same                 2   1  context=i1
assign_list         0       same                 2   1  context=i1,common=i1,class=ListAssign
backtick            0       same                 1   1  context=i1
binmode             0       same                 1   1  context=i1
bit_and             0       same                 2   1  context=i1
bit_and_assign      0       same                 2   1  context=i1
bit_not             0       same                 1   1  context=i1
bit_or              0       same                 2   1  context=i1
bit_or_assign       0       same                 2   1  context=i1
bit_xor             0       same                 2   1  context=i1
bit_xor_assign      0       same                 2   1  context=i1
bless               v       same                 2   1  context=i1
call                0       same                 2   1  context=i1
call_method         0       same                 1   1  context=i1,method=s,class=CallMethod
call_method_indirect 0      same                 2   1  context=i1
caller              v       same                -1   1  context=i1,arg_count=i1
chdir               u       same                 1   1  context=i1
chop                0       same                -1   1  context=i1,arg_count=i1
chr                 u       same                 1   1  context=i1
close               u       same                 1   1  context=i1
concatenate         0       concat               2   1  context=i1
concatenate_assign  0       concat_assign        2   1  context=i1
constant_float      0       same                 0   1  value=f,class=ConstantFloat
constant_integer    0       same                 0   1  value=i,class=ConstantInt
constant_regex      0       same                 0   1  value=c,class=ConstantSub
constant_string     0       same                 0   1  value=s,class=ConstantString
constant_sub        0       same                 0   1  value=c,class=ConstantSub
constant_undef      0       same                 0   1  noattr
defined             u       same                 1   1  context=i1
defined_or          0       same                 2   1  noattr
delete              u       same                 1   1  context=i1
delete_array        u       same                 2   1  context=i1
delete_array_slice  u       same                 2   1  context=i1
delete_hash         u       same                 2   1  context=i1
delete_hash_slice   u       same                 2   1  context=i1
dereference_array   0       same                 1   1  context=i1
dereference_glob    0       same                 1   1  context=i1
dereference_hash    0       same                 1   1  context=i1
dereference_scalar  0       same                 1   1  context=i1
dereference_sub     0       dereference_subroutine 1 1  context=i1
die                 0       same                 1   1  context=i1
discard_stack       0       same                -1   0  noattr
divide              0       same                 2   1  context=i1
divide_assign       0       same                 2   1  context=i1
do_file             u       same                 1   1  context=i1
dot_dot             0       same                 2   1  context=i1
dot_dot_dot         0       same                 2   1  context=i1
dup                 0       same                 1   2  noattr
dynamic_goto        u       same                 1   0  noattr
each                u       same                 1   1  context=i1
end                 0       same                 0   0  noattr
eval                u       same                 1   1  context=i1,hints=i,warnings=su,package=s,lexicals=eval_my,globals=eval_our
eval_regex          u       same                 1   1  context=i1,flags=i,class=RegexEval
exists              u       same                 1   1  context=i1
exists_array        u       same                 2   1  context=i1
exists_hash         u       same                 2   1  context=i1
find_method         u       same                 1   1  method=s,class=CallMethod
fresh_string        0       same                 0   1  value=s,class=ConstantString
ft_atime            u       same                 1   1  context=i1
ft_ctime            u       same                 1   1  context=i1
ft_eexecutable      u       same                 1   1  context=i1
ft_empty            u       same                 1   1  context=i1
ft_eowned           u       same                 1   1  context=i1
ft_ereadable        u       same                 1   1  context=i1
ft_ewritable        u       same                 1   1  context=i1
ft_exists           u       same                 1   1  context=i1
ft_isascii          u       same                 1   1  context=i1
ft_isbinary         u       same                 1   1  context=i1
ft_isblockspecial   u       same                 1   1  context=i1
ft_ischarspecial    u       same                 1   1  context=i1
ft_isdir            u       same                 1   1  context=i1
ft_isfile           u       same                 1   1  context=i1
ft_ispipe           u       same                 1   1  context=i1
ft_issocket         u       same                 1   1  context=i1
ft_issymlink        u       same                 1   1  context=i1
ft_istty            u       same                 1   1  context=i1
ft_mtime            u       same                 1   1  context=i1
ft_nonempty         u       same                 1   1  context=i1
ft_rexecutable      u       same                 1   1  context=i1
ft_rowned           u       same                 1   1  context=i1
ft_rreadable        u       same                 1   1  context=i1
ft_rwritable        u       same                 1   1  context=i1
ft_setgid           u       same                 1   1  context=i1
ft_setuid           u       same                 1   1  context=i1
ft_sticky           u       same                 1   1  context=i1
get                 0       same                 0   1  index=i,slot=i_sigil,class=GetSet
glob                0       same                 1   1  context=i1
glob_element        0       same                 2   1  context=i1
glob_slot           0       same                 1   1  slot=i_sigil,class=GlobSlot
swap_glob_slot_set  0       same                 2   0  slot=i_sigil,class=GlobSlot
global              0       same                 0   1  name=s,slot=i_sigil,context=i1,class=Global
grep                0       same                 1   1  context=i1
hash_element        0       same                 2   1  context=i1,create=i1,class=ElementAccess
hash_slice          0       same                 2   1  context=i1,create=i1,class=ElementAccess
hex                 u       same                 1   1  context=i1
index               v       same                -1   1  context=i1,arg_count=i1
int                 u       same                 1   1  context=i1
iterator            0       same                 1   1  noattr
iterator_next       0       same                 1   1  noattr
join                0       same                 1   1  context=i1
jump                0       same                 0   0  to=b,class=Jump
jump_if_f_eq        0       same                 2   0  to=b,class=CondJump
jump_if_f_ge        0       same                 2   0  to=b,class=CondJump
jump_if_f_gt        0       same                 2   0  to=b,class=CondJump
jump_if_f_le        0       same                 2   0  to=b,class=CondJump
jump_if_f_lt        0       same                 2   0  to=b,class=CondJump
jump_if_f_ne        0       same                 2   0  to=b,class=CondJump
jump_if_false       0       same                 1   0  to=b,class=CondJump
jump_if_null        0       same                 1   0  to=b,class=CondJump
jump_if_s_eq        0       same                 2   0  to=b,class=CondJump
jump_if_s_ge        0       same                 2   0  to=b,class=CondJump
jump_if_s_gt        0       same                 2   0  to=b,class=CondJump
jump_if_s_le        0       same                 2   0  to=b,class=CondJump
jump_if_s_lt        0       same                 2   0  to=b,class=CondJump
jump_if_s_ne        0       same                 2   0  to=b,class=CondJump
jump_if_true        0       same                 1   0  to=b,class=CondJump
keys                u       same                 1   1  context=i1
lc                  u       same                 1   1  noattr
lcfirst             u       same                 1   1  noattr
length              u       same                 1   1  noattr
lexical             0       same                 0   1  lexical_info=ls,class=Lexical
lexical_clear       0       same                 0   0  lexical_info=ls,class=Lexical
lexical_pad         0       same                 0   1  lexical_info=lp,class=Lexical
lexical_pad_clear   0       same                 0   0  lexical_info=lp,class=Lexical
lexical_pad_set     0       same                 1   0  lexical_info=lp,class=Lexical
lexical_set         0       same                 1   0  lexical_info=ls,class=Lexical
lexical_state_restore 0     same                 0   0  index=i,class=LexState
lexical_state_save  0       same                 0   0  index=i,class=LexState
lexical_state_set   0       same                 0   0  index=i,class=LexState
list_slice          0       same                 2   1  context=i1
local               0       same                 1   1  noattr
localize_array_element 0    same                 2   1  index=i,class=LocalElement
localize_glob_slot  0       same                 0   1  name=s,index=i,slot=i_sigil,class=LocalGlobSlot
localize_hash_element 0     same                 2   1  index=i,class=LocalElement
localize_lexical    0       same                 0   0  lexical_info=ls,index=i,class=LocalLexical
localize_lexical_pad 0      same                 0   0  lexical_info=lp,index=i,class=LocalLexical
log_and             0       same                 2   1  noattr
log_and_assign      0       same                 2   1  context=i1
log_not             0       not                  1   1  context=i1
log_or              0       same                 2   1  noattr
log_or_assign       0       same                 2   1  context=i1
log_xor             0       same                 2   1  context=i1
make_array          v       same                -1   1  context=i1,arg_count=i1
make_closure        0       same                 1   1  noattr
make_list           v       same                -1   1  context=i1,arg_count=i1
make_qr             0       same                 1   1  noattr
map                 0       same                 1   1  context=i1
match               0       rx_match             2   1  context=i1,flags=i,index=i,class=RegexMatch
minus               0       negate               1   1  context=i1
modulus             0       same                 2   1  context=i1
modulus_assign      0       same                 2   1  context=i1
multiply            0       same                 2   1  context=i1
multiply_assign     0       same                 2   1  context=i1
negate              0       same                 1   1  context=i1
noop                0       same                 0   0  noattr
not_match           0       rx_not_match         2   1  context=i1
num_cmp             0       same                 2   1  noattr
num_eq              0       compare_f_eq_scalar  2   1  noattr
num_ge              0       compare_f_ge_scalar  2   1  noattr
num_gt              0       compare_f_gt_scalar  2   1  noattr
num_le              0       compare_f_le_scalar  2   1  noattr
num_lt              0       compare_f_lt_scalar  2   1  noattr
num_ne              0       compare_f_ne_scalar  2   1  noattr
oct                 u       same                 1   1  context=i1
open                0       same                 1   1  context=i1
ord                 u       same                 1   1  context=i1
parentheses         0       same                -1  -1  noattr
phi                 0       same                -1  -1  slots=i_sigil_a,indices=i_a,blocks=b_a,class=Phi
pipe                0       same                 2   1  context=i1
plus                0       same                 1   1  noattr
pop                 0       same                 1   0  noattr
pos                 u       same                 1   1  noattr
postdec             0       same                 1   1  context=i1
postinc             0       same                 1   1  context=i1
power               0       same                 2   1  context=i1
power_assign        0       same                 2   1  context=i1
predec              0       same                 1   1  context=i1
preinc              0       same                 1   1  context=i1
print               0       same                 2   1  context=i1
push_element        0       same                 2   0  noattr
ql_lt               0       same                -1  -1  noattr
ql_m                0       same                -1  -1  noattr
ql_qr               0       same                -1  -1  noattr
ql_qw               0       same                -1  -1  noattr
ql_qx               0       same                -1  -1  noattr
ql_s                0       same                -1  -1  noattr
ql_tr               0       same                -1  -1  noattr
quotemeta           u       same                 1   1  noattr
readline            u       same                 1   1  context=i1
reference           u       same                 1   1  context=i1
reftype             u       same                 1   1  context=i1
repeat              0       same                 2   1  context=i1
repeat_array        0       same                 2   1  context=i1
repeat_assign       0       same                 2   1  context=i1
repeat_scalar       0       same                 2   1  context=i1
replace             0       rx_replace           2   1  context=i1,index=i,flags=i,to=b,class=RegexReplace
require_file        u       same                 1   1  context=i1
restore_array_element 0     same                 0   0  index=i,class=LocalElement
restore_glob_slot   0       same                 0   0  name=s,index=i,slot=i_sigil,class=LocalGlobSlot
restore_hash_element 0      same                 0   0  index=i,class=LocalElement
restore_lexical     0       same                 0   0  lexical_info=ls,index=i,class=LocalLexical
restore_lexical_pad 0       same                 0   0  lexical_info=lp,index=i,class=LocalLexical
return              0       same                 1   0  context=i1
reverse             0       same                 1   1  context=i1
rmdir               u       same                 1   1  context=i1
rx_split            v       same                -1   1  context=i1,arg_count=i1
rx_split_skipspaces v       same                -1   1  context=i1,arg_count=i1
scalar              u       same                 1   1  context=i1
set                 0       same                 1   0  index=i,slot=i_sigil,class=GetSet
shift_left          0       same                 2   1  context=i1
shift_left_assign   0       same                 2   1  context=i1
shift_right         0       same                 2   1  context=i1
shift_right_assign  0       same                 2   1  context=i1
sort                0       same                 1   1  context=i1
splice              v       same                -1   1  context=i1,arg_count=i1
sprintf             0       same                 1   1  context=i1
stop                0       same                 1   0  noattr
str_cmp             0       same                 2   1  noattr
str_eq              0       compare_s_eq_scalar  2   1  noattr
str_ge              0       compare_s_ge_scalar  2   1  noattr
str_gt              0       compare_s_gt_scalar  2   1  noattr
str_le              0       compare_s_le_scalar  2   1  noattr
str_lt              0       compare_s_lt_scalar  2   1  noattr
str_ne              0       compare_s_ne_scalar  2   1  noattr
stringify           0       same                 1   1  context=i1
substr              v       same                -1   1  context=i1,arg_count=i1
subtract            0       same                 2   1  context=i1
subtract_assign     0       same                 2   1  context=i1
swap_assign         0       same                 2   1  context=i1
swap_assign_list    0       same                 2   1  context=i1,common=i1,class=ListAssign
temporary           0       same                 0   1  index=i,slot=i_sigil,class=Temporary
temporary_clear     0       same                 0   0  index=i,slot=i_sigil,class=Temporary
temporary_set       0       same                 1   0  index=i,slot=i_sigil,class=Temporary
transliterate       u       rx_transliterate     1   1  match=s,replacement=s,flags=i,context=i1,class=RegexTransliterate
uc                  u       same                 1   1  noattr
ucfirst             u       same                 1   1  noattr
undef               u       same                 1   0  noattr
unlink              0       same                 1   1  context=i1
values              u       same                 1   1  context=i1
vec                 u       same                 3   1  context=i1
vivify_array        0       same                 1   1  context=i1
vivify_hash         0       same                 1   1  context=i1
vivify_scalar       0       same                 1   1  context=i1
wantarray           v       want                 0   1  context=i1
warn                0       same                 1   1  context=i1

rx_accept           0       same                 0   0  groups=i,class=RegexAccept
rx_any              0       same                 0   0  noattr
rx_any_nonewline    0       same                 0   0  noattr
rx_backtrack        0       same                 0   0  to=b,class=RegexBacktrack
rx_beginning        0       same                 0   0  noattr
rx_capture_end      0       same                 0   0  group=i,class=RegexCapture
rx_capture_start    0       same                 0   0  group=i,class=RegexCapture
rx_class            0       same                 0   0  elements=s,ranges=s,flags=i,class=RegexClass
rx_end              0       same                 0   0  noattr
rx_end_or_newline   0       same                 0   0  noattr
rx_exact            0       same                 0   0  characters=s,length=i,class=RegexExact
rx_exact_i          0       same                 0   0  characters=s,length=i,class=RegexExact
rx_fail             0       same                 0   0  noattr
rx_pop_state        0       same                 0   0  noattr
rx_quantifier       0       same                 0   0  min=i,max=i,greedy=i1,group=i,to=b,subgroups_start=i,subgroups_end=i,class=RegexQuantifier
rx_restore_pos      0       same                 0   0  index=i,class=RegexState
rx_save_pos         0       same                 0   0  index=i,class=RegexState
rx_start_group      0       same                 0   0  to=b,class=RegexStartGroup
rx_start_match      0       same                 0   0  noattr
rx_state_restore    0       same                 0   0  index=i,class=RegexState
rx_try              0       same                 0   0  to=b,class=RegexTry
rx_word_boundary    0       same                 0   0  noattr
