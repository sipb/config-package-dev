# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2008 Tim Abbott <tabbott@mit.edu> and
#                  Anders Kaseorg <andersk@mit.edu>
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

# Don't include transform-files.mk in your rules files directly;
# instead use config-package.mk.

ifndef _cdbs_rules_transform_files
_cdbs_rules_transform_files = 1

include /usr/share/cdbs/1/rules/check-files.mk

DEB_TRANSFORM_FILES = $(foreach package,$(DEB_ALL_PACKAGES),$(DEB_TRANSFORM_FILES_$(package)))

DEB_TRANSFORM_FILES_TMPDIR=debian/transform_file_copies

debian_transform_files = $(patsubst %,$(DEB_TRANSFORM_FILES_TMPDIR)%,$(1))
undebian_transform_files = $(patsubst $(DEB_TRANSFORM_FILES_TMPDIR)%,%,$(1))
debian_transform_script = $(if $(DEB_TRANSFORM_SCRIPT_$(call undebian_transform_files,$(1))), \
	$(DEB_TRANSFORM_SCRIPT_$(call undebian_transform_files,$(1))), \
	debian/transform_$(notdir $(call undebian_transform_files,$(1))))

common-build-arch common-build-indep:: $(foreach file,$(DEB_TRANSFORM_FILES),$(call debian_transform_files,$(file)))

$(call debian_transform_files,%): $(call debian_check_files,%)
	mkdir -p $(@D)
	chmod +x $(call debian_transform_script,$@)
	$(call debian_transform_script,$@) < $< > $@

$(patsubst %,binary-install/%,$(DEB_ALL_PACKAGES)) :: binary-install/%:
	set -e; \
	$(foreach file,$(DEB_TRANSFORM_FILES_$(cdbs_curpkg)), \
		install -d debian/$(cdbs_curpkg)/$(dir $(file)); \
		cp -a $(call debian_transform_files,$(file)) \
		    debian/$(cdbs_curpkg)/$(dir $(file));)

clean::
	rm -rf $(DEB_TRANSFORM_FILES_TMPDIR)

endif
