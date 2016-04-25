#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use YAML::XS qw( LoadFile );
use FindBin qw( $Bin );
use DDP;

my $conf = "$Bin/upload-svr.yml";
my $yaml = LoadFile $conf;

p $yaml;



