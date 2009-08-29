#!/usr/bin/perl -w

use strict;
use warnings;
use lib 'inc';

use My::Build;

my $build = My::Build->new
  ( module_name          => 'Language::P',
    license              => 'perl',
    requires             =>
        { 'Class::Accessor'   => '0.30',
          'Module::Build'     => '0.28',
          'Exporter'          => '5.58',
          'Test::Differences' => '0.47',
          'TAP::Harness'      => '3.10',
          'perl'              => '5.8.3',
          },
    recursive_test_files => 1,
    get_options          =>
        { parrot         =>
              { type     => '=s',
                },
          dlr            =>
              { type     => '=s',
                },
          },
    );
$build->create_build_script;

if( my $dlr = $build->args( 'dlr' ) ) {
    $dlr =~ s{/}{\\\\}g;

    system $^X, '-i', '-p', '-e', 's/<HintPath>.*?\\\\Src\\\\Runtime\\\\/<HintPath>'
                            . '..\\\\..\\\\' . $dlr . '\\\\Src\\\\Runtime\\\\/', '--',
                            'support/dotnet/dotnet.csproj';
}
