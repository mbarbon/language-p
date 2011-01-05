package TestIntermediate;

use strict;
use warnings;
use t::lib::TestParser;

use Language::P::Intermediate::Generator;
use Language::P::Intermediate::Transform;
use Language::P::Opcodes;
use Language::P::Constants qw(:all);
use Language::P::Toy::Assembly;
use Language::P::Toy::Intermediate;

use Exporter 'import';
our @EXPORT_OK = qw(generate_main_linear basic_blocks blocks_as_string
                    generate_linear_and_diff generate_tree_and_diff
                    generate_ssa_and_diff);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

sub generate_main_linear {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new( { is_stack => 1 } );
    my $segments = $gen->generate_bytecode( $parsetree );
    my $trans = Language::P::Intermediate::Transform->new;
    my $linear = $trans->all_to_linear( $segments );

    return $linear;
}

sub generate_main_tree {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new;
    my $segments = $gen->generate_bytecode( $parsetree );
    my $trans = Language::P::Intermediate::Transform->new;
    my $trees = $trans->all_to_tree( $segments );

    return $trees;
}

sub generate_main_ssa {
    my( $code ) = @_;
    my $parsetree = parse_string( $code );
    my $gen = Language::P::Intermediate::Generator->new;
    my $segments = $gen->generate_bytecode( $parsetree );

    return $segments;
}

my $op_map = \%Language::P::Opcodes::NUMBER_TO_NAME;
my $op_attr = \%Language::P::Opcodes::OP_ATTRIBUTES;

sub blocks_as_string {
    my( $segments ) = @_;
    my $str = '';

    foreach my $segment ( @$segments ) {
        $segment->find_alive_blocks;
        my $name = $segment->is_main ? 'main' :
                                       $segment->name || 'anoncode';
        $str .= sprintf "# %s\n", $name;
        foreach my $block ( sort { $a->start_label cmp $b->start_label}
                                 @{$segment->basic_blocks} ) {
            next if $block->dead;
            $str .= sprintf "%s: # scope=%d\n",
                            $block->start_label,
                            $block->scope;
            foreach my $instr ( @{$block->bytecode} ) {
                $str .= $instr->as_string( $op_map, $op_attr )
            }
        }
    }

    return $str;
}

sub generate_linear_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main_linear( $code );
    my $asm_string = blocks_as_string( $blocks );

    $assembly =~ s{([= ])((?:NUM|CXT|FLAG|CONST|STRING|VALUE|OP|DECLARATION|PROTO|CHANGED|RX_CLASS|RX_GROUP|RX_POSIX|RX_ASSERTION)_[A-Z_\|]+)}
                  {$1 . ( eval $2 or die $@ )}eg;

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

sub generate_tree_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main_tree( $code );
    my $asm_string = blocks_as_string( $blocks );

    $assembly =~ s{([= ])((?:NUM|CXT|FLAG|CONST|STRING|VALUE|OP|DECLARATION|PROTO|CHANGED|RX_CLASS|RX_GROUP|RX_POSIX|RX_ASSERTION)_[A-Z_\|]+)}
                  {$1 . ( eval $2 or die $@ )}eg;

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

sub generate_ssa_and_diff {
    my( $code, $assembly ) = @_;
    my $blocks = generate_main_ssa( $code );
    my $asm_string = blocks_as_string( $blocks );

    $assembly =~ s{([= ])((?:NUM|CXT|FLAG|CONST|STRING|VALUE|OP|DECLARATION|PROTO|CHANGED|RX_CLASS|RX_GROUP|RX_POSIX|RX_ASSERTION)_[A-Z_\|]+)}
                  {$1 . ( eval $2 or die $@ )}eg;

    require Test::Differences;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::Differences::eq_or_diff( $asm_string, $assembly );
}

package t::lib::TestIntermediate;

sub import {
    shift;

    strict->import;
    warnings->import;
    Test::More->import( @_ );
    Exporter::export( 'TestIntermediate', scalar caller, ':all' );
}

1;
