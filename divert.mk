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

# Don't include divert.mk in your rules files directly; instead use
# config-package.mk.

# divert.mk handles the low-level diversion logic.  It includes
# divert.sh.in in the postinst and prerm scripts, and adds 

ifndef _cdbs_rules_divert
_cdbs_rules_divert = 1

include /usr/share/cdbs/1/rules/debhelper.mk

CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), config-package-dev (>= 4.5~)

# divert.sh.in is included in the postinst/prerm scripts of packages
# installing diversions using config-package-dev.
DEB_DIVERT_SCRIPT = /usr/share/config-package-dev/divert.sh.in
# script used to encode the path of a file uniquely in a valid virtual
# package name.
DEB_DIVERT_ENCODER = /usr/share/config-package-dev/encode

DEB_DIVERT_PACKAGES += $(foreach package,$(DEB_ALL_PACKAGES), \
    $(if $(DEB_TRANSFORM_FILES_$(package)),$(package), \
    $(if $(DEB_REMOVE_FILES_$(package)),$(package), \
    $(if $(DEB_UNREMOVE_FILES_$(package)),$(package), \
    $(if $(DEB_UNDIVERT_FILES_$(package)),$(package), \
    $(if $(DEB_DIVERT_FILES_$(package)),$(package)))))))

ifeq ($(DEB_DIVERT_EXTENSION),)
DEB_DIVERT_EXTENSION = .divert
endif

# Replace only the last instance of DEB_DIVERT_EXTENSION in the
# filename, to make it possible to divert /path/foo.divert to
# foo.divert.divert-orig
divert_files_replace_name = $(shell echo $(1) | perl -pe 's/(.*)\Q$(DEB_DIVERT_EXTENSION)\E/$$1$(2)/')

# Transform a full path into the path it should be diverted to if it's
# removed
remove_files_name = /usr/share/$(cdbs_curpkg)/$(shell $(DEB_DIVERT_ENCODER) $(1))

dh_compat_5 := $(shell if [ '$(DH_COMPAT)' -ge 5 ]; then echo y; fi)

reverse = $(foreach n,$(shell seq $(words $(1)) -1 1),$(word $(n),$(1)))
reverse_dh_compat_5 = $(if $(dh_compat_5),$(call reverse,$(1)),$(1))

debian-divert/%: package = $(subst debian-divert/,,$@)
debian-divert/%: divert_files = $(DEB_DIVERT_FILES_$(package)) $(DEB_TRANSFORM_FILES_$(package))
debian-divert/%: divert_remove_files = $(DEB_REMOVE_FILES_$(package))
debian-divert/%: divert_undivert_files = $(DEB_UNDIVERT_FILES_$(package))
debian-divert/%: divert_unremove_files = $(DEB_UNREMOVE_FILES_$(package))
debian-divert/%: divert_files_all = $(strip $(divert_files) $(divert_remove_files) $(divert_undivert_files) $(divert_unremove_files))
debian-divert/%: divert_files_thispkg = $(strip $(divert_files) $(divert_remove_files))
$(patsubst %,debian-divert/%,$(DEB_DIVERT_PACKAGES)) :: debian-divert/%:
#   Writing shell scripts in makefiles sucks.  Remember to $$ shell
#   variables and include \ at the end of each line.
# Add code to postinst to add/remove diversions as appropriate
	set -e; \
	{ \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DIVERT_EXTENSION#/$(DEB_DIVERT_EXTENSION)/g' $(DEB_DIVERT_SCRIPT); \
	    $(if $(divert_files_all), \
		echo 'if [ "$$1" = "configure" ]; then'; \
		$(foreach file,$(divert_undivert_files), \
		    echo "    check_undivert_unlink $(call divert_files_replace_name,$(file), )"; )\
		$(foreach file,$(divert_unremove_files), \
		    echo "    check_undivert_unremove $(file) $(call remove_files_name,$(file))"; )\
		$(foreach file,$(divert_files), \
		    echo "    divert_link $(call divert_files_replace_name,$(file), )";) \
		$(foreach file,$(divert_remove_files), \
		    mkdir -p debian/$(cdbs_curpkg)/usr/share/$(cdbs_curpkg); \
		    echo "    divert_remove $(file) $(call remove_files_name,$(file))";) \
		echo 'fi'; \
	    ) \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).postinst.debhelper
# Add code to prerm script to undo diversions when package is removed.
	set -e; \
	{ \
	    $(if $(dh_compat_5),, \
		if [ -e $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper ]; then \
		    cat $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper; \
		fi;) \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DIVERT_EXTENSION#/$(DEB_DIVERT_EXTENSION)/g' $(DEB_DIVERT_SCRIPT); \
	    $(if $(divert_files_thispkg), \
		echo 'if [ "$$1" = "remove" ]; then'; \
		$(foreach file,$(call reverse_dh_compat_5,$(divert_files)), \
		    echo "    undivert_unlink $(call divert_files_replace_name,$(file), )";) \
		$(foreach file,$(call reverse_dh_compat_5,$(divert_remove_files)), \
		    echo "    undivert_unremove $(file) $(cdbs_curpkg)";) \
		echo 'fi'; \
	    ) \
	    $(if $(dh_compat_5), \
		if [ -e $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper ]; then \
		    cat $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper; \
		fi;) \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper.new
	mv $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper.new \
	    $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper
# Add an encoding of the names of the diverted files to the Provides:
# and Conflicts: lists.  This prevents two packages diverting the same
# file from being installed simultaneously (it cannot work, and this
# produces a much less ugly error).  Requires in debian/control:
#   Provides: $(diverted-files)
#   Conflicts: $(diverted-files)
	set -e; \
	{ \
	    echo -n "diverted-files="; \
	    $(foreach file,$(divert_files_thispkg),\
		echo -n "diverts-"; \
		${DEB_DIVERT_ENCODER} "$(call divert_files_replace_name,$(file))"; \
		echo -n ", ";) \
	    echo; \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).substvars

$(patsubst %,binary-post-install/%,$(DEB_DIVERT_PACKAGES)) :: binary-post-install/%: debian-divert/%

endif
