#!/usr/bin/perl -w

BEGIN { print "1..11\n" }
BEGIN { unshift @INC, 'support/bytecode', 'lib' }

use 5;
require 5;

# load some misc "very important" modules included in core
use strict;
BEGIN { print "ok\n" }
use warnings;
BEGIN { print "ok\n" }
use warnings::register;
BEGIN { print "ok\n" }
use vars;
BEGIN { print "ok\n" }
use subs;
BEGIN { print "ok\n" }
use parent;
BEGIN { print "ok\n" }
use Exporter;
BEGIN { print "ok\n" }
use Carp;
BEGIN { print "ok\n" }
use Carp::Heavy;
BEGIN { print "ok\n" }
use Exporter::Heavy;
BEGIN { print "ok\n" }
# use lib;
# use blib;
# use Fatal;
# use autodie;
use constant;
BEGIN { print "ok\n" }
# use File::Basename;
# use File::Find;
# use File::Path;
# use UNIVERSAL;
