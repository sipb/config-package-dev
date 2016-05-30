#!/usr/bin/perl
# debhelper sequence file for config-package-dev

use warnings;
use strict;
use Debian::Debhelper::Dh_Lib;

insert_before("dh_link", "dh_configpackage");

1
