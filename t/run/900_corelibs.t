#!/usr/bin/perl -w

BEGIN { print "1..1\n" }

use 5;
require 5;

# load some misc "very important" modules included in core
use strict;
use warnings;
use warnings::register;
use vars;
use subs;
use base;
use parent;
use Carp;
use Carp::Heavy;
use Exporter;
# use Exporter::Heavy;
# use lib;
# use blib;
# use Fatal;
# use autodie;
use constant;
# use File::Basename;
# use File::Find;
# use File::Path;
# use UNIVERSAL;
use Class::Accessor;
use Class::Accessor::Fast;

print "ok 1 - got there\n";
