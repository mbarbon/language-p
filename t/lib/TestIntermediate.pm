package TestIntermediate;

use strict;
use warnings;
use TestParser qw(parse_string);

use Language::P::Intermediate::Generator;
use Language::P::Intermediate::Transform;
use Language::P::Opcodes;

use Exporter 'import';
our @EXPORT_OK = qw(generate_main basic_blocks blocks_as_string
                    generate_and_diff generate_tree_and_diff
                    generate_ssa_and_diff);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

sub generate_main {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new;
    my $segments = $gen->generate_bytecode( $parsetree );

    return $segments;
}

sub generate_main_tree {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new;
    my $segments = $gen->generate_bytecode( $parsetree );
    my $trans = Language::P::Intermediate::Transform->new;
    my $trees = [ map $trans->to_tree( $_ ), @$segments ];

    return $trees;
}

sub generate_main_ssa {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new;
    my $segments = $gen->generate_bytecode( $parsetree );
    my $trans = Language::P::Intermediate::Transform->new;
    my $trees = [ map $trans->to_ssa( $_ ), @$segments ];

    return $trees;
}

my $op_map = \%Language::P::Opcodes::NUMBER_TO_NAME;
my $op_attr = \%Language::P::Opcodes::OP_ATTRIBUTES;

sub blocks_as_string {
    my( $segments ) = @_;
    my $str = '';

    foreach my $segment ( @$segments ) {
        $str .= "# " . ( $segment->name ? $segment->name : 'main' ) . "\n";
        foreach my $block ( @{$segment->basic_blocks} ) {
            foreach my $instr ( @{$block->bytecode} ) {
                $str .= $instr->as_string( $op_map, $op_attr )
            }
        }
    }

    return $str;
}

sub generate_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main( $code );
    my $asm_string = blocks_as_string( $blocks );

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

sub generate_tree_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main_tree( $code );
    my $asm_string = blocks_as_string( $blocks );

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

sub generate_ssa_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main_ssa( $code );
    my $asm_string = blocks_as_string( $blocks );

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

1;
