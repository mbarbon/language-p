#!/usr/bin/perl -w

use strict;
use warnings;
use lib 'inc';

use My::Build;

my $build = My::Build->new
  ( module_name          => 'Language::P',
    license              => 'perl',
    requires             =>
        { 'Module::Build'     => '0.28',
          'Exporter'          => '5.58',
          'Test::Differences' => '0.47',
          'TAP::Harness'      => '3.10',
          'perl'              => '5.8.3',
          'parent'            => '0.221',
          },
    get_options          =>
        { perl5          =>
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

    system $^X, '-i', '-p', '-e', 's/<HintPath>.*?\\\\bin\\\\/<HintPath>'
                            . '..\\\\..\\\\' . $dlr . '\\\\bin\\\\/i', '--',
                            'support/dotnet/dotnet.csproj';
}
