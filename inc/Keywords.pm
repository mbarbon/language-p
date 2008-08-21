package Keywords;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(write_keywords);

my %types =
  ( k    => 'T_KEYWORD',
    b    => 'T_BUILTIN',
    o    => 'T_OVERRIDABLE',
    );

sub write_keywords {
    my( $file ) = @ARGV;

    open my $out, '>', $file;

    my( %kw, @keywords, @builtins, @overridables );
    my $num = 1;
    while( defined( my $line = readline Keywords::DATA ) ) {
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        next unless length $line;
        my( $keyword, $type, $id ) = split /\s+/, $line;

        $id ||= "KEY_" . uc $keyword;

        push @keywords, $id if $type eq 'k';
        push @builtins, $id if $type eq 'b';
        push @overridables, $id if $type eq 'o';
        $kw{$keyword} = [ $types{$type}, $id ];

        ++$num;
    }

    printf $out <<'EOT', join( ' ', @keywords ), join( ' ', @builtins ), join( ' ', @overridables );
package Language::P::Keywords;

use Exporter 'import';

our( @KEYWORDS, @BUILTINS, @OVERRIDABLES );
BEGIN {
  our @KEYWORDS = qw(%s);
  our @BUILTINS = qw(%s);
  our @OVERRIDABLES = qw(%s);
};

our @EXPORT = ( @KEYWORDS, @BUILTINS, @OVERRIDABLES,
                qw(is_keyword is_builtin is_overridable)
                );

use constant +
  { ID_MASK          => 0x0003, # 1
    KEYWORD_MASK     => 0x003e, # 5
    BUILTIN_MASK     => 0x07c0, # 5
    OVERRIDABLE_MASK => 0xf800, # 5
    };

use constant +
  { ( map { $KEYWORDS[$_] => ( $_ + 1 ) << 1 } 0 .. $#KEYWORDS ),
    ( map { $BUILTINS[$_] => ( $_ + 1 ) << 6 } 0 .. $#BUILTINS ),
    ( map { $OVERRIDABLES[$_] => ( $_ + 1 ) << 11 } 0 .. $#OVERRIDABLES ),
    };

sub is_keyword($)     { $_[0] & KEYWORD_MASK }
sub is_builtin($)     { $_[0] & BUILTIN_MASK }
sub is_overridable($) { $_[0] & OVERRIDABLE_MASK }

our %%KEYWORDS =
  (
EOT

    while( my( $k, $v ) = each %kw ) {
        printf $out <<'EOT', $k, $v->[1];
    '%s' => %s,
EOT
    }

    print $out <<'EOT';
    );

1;
EOT

}

__DATA__

if                  k       
unless              k       
else                k       
elsif               k       
for                 k       
foreach             k       
while               k       
until               k       
do                  k       
last                k       
next                k       
redo                k       
my                  k       OP_MY
our                 k       OP_OUR
state               k       OP_STATE
sub                 k       
eval                k       
package             k       
print               b       OP_PRINT
defined             b       
return              b       
undef               b       
unlink              o       
glob                o       
readline            o       
die                 o       
open                o       
pipe                o       
chdir               o       
rmdir               o       
glob                o       
readline            o       
close               o       
binmode             o       
abs                 o       
wantarray           o       
