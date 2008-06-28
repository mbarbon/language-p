#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  ( module_name          => 'Language::P',
    license              => 'perl',
    requires             =>
        { 'Class::Accessor'   => '0.30',
          'Module::Build'     => '0.28',
          'Exporter'          => '5.58',
          'Test::Differences' => '0.47',
          'perl'              => '5.8.3',
          },
    recursive_test_files => 1,
    );
$build->create_build_script;
