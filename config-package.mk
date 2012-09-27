# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2007-2008 Anders Kaseorg <andersk@mit.edu> and
#                       Tim Abbott <tabbott@mit.edu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.

#   /usr/share/cdbs/1/rules/config-package.mk is the externally-facing
# makefile fragment for config-package-dev.  It should be included
# after the following variables are set in debian/rules.
#
#
# Most variables are lists, so one can 
#
# DEB_DIVERT_FILES_package += /path1/file1.divert \
#			      /path2/file2.divert \
#			      /path3/file3.divert
#
# We use += in the examples 
#
# The config-package-dev system supports the following variables:
#
# DEB_DIVERT_EXTENSION
#
#   Extension used for all config-package-dev diversions (defaults to
# .divert, which we will use in examples).  This field is difficult to
# change on package upgrades; we recommend picking a value to use for
# all packages at your site.
#
# DEB_DIVERT_FILES_package += /path/file.divert
#
#   List of absolute paths to files to be replaced at package install
# time by being diverted from /path/file to /path/file.divert-orig
# (DEB_DIVERT_EXTENSION should be part of the path, but need not
# appear at the end); a symlink /path/file -> /path/file.divert will
# be installed in its place.  The user is responsible for installing
# /path/file.divert.  This is best for diverting binaries and most
# configuration files.
#
# DEB_TRANSFORM_FILES_package += /path/file.divert
#
#   This works like DEB_DIVERT_FILES, but additionally the file to be
# installed to /path/file.divert will be generated at package build
# time as the standard output from
#
# $(DEB_TRANSFORM_SCRIPT_path/file.divert) < $(DEB_CHECK_FILES_SOURCE_/path/file.divert)
#
# These variables have the following defaults:
#
#   DEB_TRANSFORM_SCRIPT_path/file.divert = debian/transform_file.divert
#   DEB_CHECK_FILES_SOURCE_/path/file.divert = /path/file
#
#   If DEB_CHECK_FILES_SOURCE_/path/file.divert does not match the
# md5sums shipped with the package containing it, the package build
# will abort.  DEB_TRANSFORM_FILES is targeted at making changes to a
# (potentially long) configuration file that will work on several
# Debian versions.  We recommend using DEB_TRANSFORM_FILES in
# conjunction with pbuilder, sbuild, or another tool for building
# Debian packages in a clean environment. (That said, if /path/file is
# diverted on the running system, DEB_CHECK_FILES_SOURCE does
# reverse-resolve the diversion and default to the original version of
# the file, to allow you to rebuild a package using DEB_TRANSFORM_FILES
# that is currently installed, in most cases.)
#
# DEB_REMOVE_FILES_package += /path/file
#
#   List of absolute paths to files to be diverted to a unique path in
# /usr/share/package/.  No symlink or replacement file will be
# installed.  This system is useful for disabling files in /etc/cron.d
# or similar .d directories where the normal divert-and-symlink
# approach would result in (e.g.)  the old cron job still being run,
# and any new cron job being run twice.  Note that for technical
# reasons related to how dpkg unpacks files, you cannot also install a
# replacement file to /etc/cron.d/file; you must install it to some
# other path (which should be fine in a .d directory).  If you want to
# install a replacement file with the same name, you probably want
# DEB_DIVERT_FILES.
#
# DEB_UNDIVERT_FILES_package += /path/file.divert
#
#   List of absolute paths to files whose diversions caused by
# DEB_DIVERT_FILES are to be removed upon installing this package, if
# the diversions have been made on the target system.  This is
# primarily useful for removing a now-unecessary diversion provided by
# a previous version of this package on an upgrade.
#
# DEB_UNREMOVE_FILES_package += /path/file
#
#   This works like DEB_UNDIVERT_FILES_package, except that it only
# removes the diversion (not a symlink).

ifndef _cdbs_rules_config_package
_cdbs_rules_config_package = 1

# transform-files.mk includes the other config-package-dev fragments.
include /usr/share/cdbs/1/rules/transform-files.mk

endif
