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
          'parent'            => '0.223',
          },
    get_options          =>
        { parrot         =>
              { type     => '=s',
                },
          },
    );
$build->create_build_script;
