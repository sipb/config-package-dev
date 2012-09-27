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

# Don't include check-files.mk in your rules files directly; instead
# use config-package.mk.

# check-files.mk is used to verify that files on local disk have not
# been modified from the upstream packaged version.  Its only API
# function is adding the following function as a dependency:
#
# $(call debian_check_files,filename)
#
#   Returns the path to a copy of filename that is verified to be
# unmodified from the version shipped by the distribution (by checking
# md5sums).  The function causes the package to fail to build if the
# relevant configuration file has been modified on the build machine.

ifndef _cdbs_rules_check_files
_cdbs_rules_check_files = 1

include /usr/share/cdbs/1/rules/displace.mk

DEB_CHECK_FILES_TMPDIR = debian/check_file_copies

debian_check_files_source = $(if $(DEB_CHECK_FILES_SOURCE_$(1)),$(DEB_CHECK_FILES_SOURCE_$(1)),$(call displace_files_replace_name,$(1)))

debian_check_files = $(patsubst %,$(DEB_CHECK_FILES_TMPDIR)%,$(1))
undebian_check_files = $(patsubst $(DEB_CHECK_FILES_TMPDIR)%,%,$(1))

debian_check_files_tmp = $(patsubst %,%.tmp,$(call debian_check_files,$(1)))
undebian_check_files_tmp = $(call undebian_check_files,$(patsubst %.tmp,%,$(1)))

# We need a level of indirection here in order to make sure that
# normal makefile targets, like "clean", are not affected by the
# debian_check_files rules.
$(call debian_check_files,%): $(call debian_check_files_tmp,%)
	mv $< $@

# We check md5sums from both /var/lib/dpkg/info/$(package).md5sums
# (the md5sums database for non-conffiles) and the conffiles database
# used for prompting about conffiles being changed (via dpkg-query).
#
# There is some wrangling here because the formats of these sources differ.
$(call debian_check_files_tmp,%): target = $(call undebian_check_files_tmp,$@)
$(call debian_check_files_tmp,%): name = $(call debian_check_files_source,$(target))
$(call debian_check_files_tmp,%): truename = $(shell /usr/sbin/dpkg-divert --truename $(name))
$(call debian_check_files_tmp,%): package = $(shell LC_ALL=C dpkg -S $(name) | sed -n '/^diversion by /! s/: .*$$// p')
$(call debian_check_files_tmp,%): $(truename)
	[ -n "$(package)" ]
	mkdir -p $(@D)
	cp "$(truename)" $@
	set -e; \
	md5sums="$$(dpkg-query --control-path $(package) md5sums 2>/dev/null)" || \
	    md5sums=/var/lib/dpkg/info/$(package).md5sums; \
	md5=$$(dpkg-query --showformat='$${Conffiles}\n' --show $(package) | \
	    sed -n 's,^ $(name) \([0-9a-f]*\)$$,\1  $@, p'); \
	if [ -n "$$md5" ]; then \
	    echo "$$md5" | md5sum -c; \
	elif [ -e "$$md5sums" ]; then \
	    md5=$$(sed -n 's,^\([0-9a-f]*\)  $(patsubst /%,%,$(name))$$,\1  $@, p' \
		"$$md5sums"); \
	    [ -n "$$md5" ] && echo "$$md5" | md5sum -c; \
	else \
	    echo "config-package-dev: warning: $(package) does not include md5sums!"; \
	    echo "config-package-dev: warning: md5sum for $(name) not verified."; \
	fi

clean::
	rm -rf $(DEB_CHECK_FILES_TMPDIR)

endif
