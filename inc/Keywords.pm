package Keywords;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(write_keywords);

use Language::P::Parser::KeywordList;

sub write_keywords {
    my( $file ) = @ARGV;
    my( $kw, $keywords, $builtins, $overridables ) =
        Language::P::Parser::KeywordList::parse_table();

    open my $out, '>', $file;

    printf $out <<'EOT', join( ' ', @$keywords ), join( ' ', @$builtins ), join( ' ', @$overridables );
package Language::P::Keywords;

use Exporter 'import';

our( @KEYWORDS, @BUILTINS, @OVERRIDABLES );
BEGIN {
  our @KEYWORDS = qw(%s);
  our @BUILTINS = qw(%s);
  our @OVERRIDABLES = qw(%s);
};

our @EXPORT = ( @KEYWORDS, @BUILTINS, @OVERRIDABLES,
                qw(@KEYWORDS @BUILTINS @OVERRIDABLES %%ID_TO_KEYWORD),
                qw(is_keyword is_builtin is_overridable is_id)
                );
our %%EXPORT_TAGS =
  ( all       => \@EXPORT,
    constants => [ @KEYWORDS, @BUILTINS, @OVERRIDABLES ],
    );

use constant +
  { ID_MASK          => 0x00003, # 2
    KEYWORD_MASK     => 0x0007c, # 5
    BUILTIN_MASK     => 0x00f80, # 5
    OVERRIDABLE_MASK => 0x3f000, # 6
    };

use constant +
  { ( map { $KEYWORDS[$_] => ( $_ + 1 ) << 2 } 0 .. $#KEYWORDS ),
    ( map { $BUILTINS[$_] => ( $_ + 1 ) << 7 } 0 .. $#BUILTINS ),
    ( map { $OVERRIDABLES[$_] => ( $_ + 1 ) << 12 } 0 .. $#OVERRIDABLES ),
    };

sub is_keyword($)     { $_[0] & KEYWORD_MASK }
sub is_builtin($)     { $_[0] & BUILTIN_MASK }
sub is_overridable($) { $_[0] & OVERRIDABLE_MASK }
sub is_id($)          { $_[0] & ID_MASK }

our %%KEYWORDS =
  (
EOT

    while( my( $k, $v ) = each %$kw ) {
        printf $out <<'EOT', $k, $v->[1];
    '%s' => %s,
EOT
    }

    print $out <<'EOT';
    );

our %ID_TO_KEYWORD = reverse %KEYWORDS;

1;
EOT

}

1;
