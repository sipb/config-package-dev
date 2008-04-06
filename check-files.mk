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

ifndef _cdbs_rules_check_files
_cdbs_rules_check_files = 1

include /usr/share/cdbs/1/rules/divert.mk

DEB_CHECK_FILES_DIR = debian/check_file_copies

debian_check_files_source = $(if $(DEB_CHECK_FILES_SOURCE_$(1)),$(DEB_CHECK_FILES_SOURCE_$(1)),$(1))
debian_check_files_check = $(subst $(DEB_DIVERT_EXTENSION),,$(call debian_check_files_source,$(1)))

debian_check_files = $(patsubst %,$(DEB_CHECK_FILES_DIR)%,$(1))
undebian_check_files = $(patsubst $(DEB_CHECK_FILES_DIR)%,%,$(1))

debian_check_files_tmp = $(patsubst %,%.tmp,$(call debian_check_files,$(1)))
undebian_check_files_tmp = $(call undebian_check_files,$(patsubst %.tmp,%,$(1)))

$(call debian_check_files,%): $(call debian_check_files_tmp,%)
	mv $< $@

$(call debian_check_files_tmp,%): target = $(call undebian_check_files_tmp,$@)
$(call debian_check_files_tmp,%): name = $(call debian_check_files_check,$(target))
$(call debian_check_files_tmp,%): truename = $(shell /usr/sbin/dpkg-divert --truename $(name))
$(call debian_check_files_tmp,%): package = $(shell dpkg -S $(name) | grep -v "^diversion by" | cut -f1 -d:)
$(call debian_check_files_tmp,%): $(truename)
	[ -n $(package) ]
	mkdir -p $(@D)
	cp "$(truename)" $@
	md5=$$(dpkg-query --showformat='$${Conffiles}\n' --show $(package) | \
	    sed -n 's,^ $(name) \([0-9a-f]*\)$$,\1  $@, p'); \
	if [ -n "$$md5" ]; then \
	    echo "$$md5" | md5sum -c; \
	elif [ -e /var/lib/dpkg/info/$(package).md5sums ]; then \
	    md5=$$(sed -n 's,^\([0-9a-f]*\)  $(patsubst /%,%,$(name))$$,\1  $@, p' \
		/var/lib/dpkg/info/$(package).md5sums); \
	    [ -n "$$md5" ] && echo "$$md5" | md5sum -c; \
	else \
	    echo "warning: $(package) does not include md5sums!"; \
	    echo "warning: md5sum for $(name) not verified."; \
	fi

clean::
	rm -rf $(DEB_CHECK_FILES_DIR)

endif
