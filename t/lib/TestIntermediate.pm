package TestIntermediate;

use strict;
use warnings;
use TestParser qw(parse_string);

use Language::P::Intermediate::Generator;
use Language::P::Opcodes;

use Exporter 'import';
our @EXPORT_OK = qw(generate_main basic_blocks blocks_as_string
                    generate_and_diff);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

my $blocks;

sub generate_main {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new;
    my $segment = $gen->generate_bytecode( $parsetree )->[0];

    return $segment->basic_blocks;
}

my $op_map = \%Language::P::Opcodes::NUMBER_TO_NAME;

sub blocks_as_string {
    my( $blocks ) = @_;
    my $str = '';

    foreach my $block ( @$blocks ) {
        foreach my $instr ( @{$block->bytecode} ) {
            $str .= $instr->as_string( $op_map )
        }
    }

    return $str;
}

sub basic_blocks {
    return $blocks;
}

sub generate_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main( $code );
    my $asm_string = blocks_as_string( $blocks );

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

1;
