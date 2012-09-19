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

# Don't include displace.mk in your rules files directly; instead use
# config-package.mk.

# displace.mk handles the low-level diversion logic.  It includes
# displace.sh.in in the postinst and prerm scripts, and adds calls to
# the functions in displace.sh.in to add and remove diversions and
# symlinks at the appropriate points.

ifndef _cdbs_rules_displace
_cdbs_rules_displace = 1

include /usr/share/cdbs/1/rules/debhelper.mk

CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), config-package-dev (>= 5.0~)

# displace.sh.in is included in the postinst/prerm scripts of packages
# installing diversions and symlinks using config-package-dev.
DEB_DISPLACE_SCRIPT = /usr/share/debhelper/autoscripts/displace.sh.in
# script used to encode the path of a file uniquely in a valid virtual
# package name.
DEB_DISPLACE_ENCODER = /usr/share/config-package-dev/encode

DEB_DISPLACE_PACKAGES += $(foreach package,$(DEB_ALL_PACKAGES), \
    $(if $(DEB_TRANSFORM_FILES_$(package)),$(package), \
    $(if $(DEB_HIDE_FILES_$(package)),$(package), \
    $(if $(DEB_UNHIDE_FILES_$(package)),$(package), \
    $(if $(DEB_UNDISPLACE_FILES_$(package)),$(package), \
    $(if $(DEB_DISPLACE_FILES_$(package)),$(package), \
    $(if $(DEB_REMOVE_FILES_$(package)),$(package), \
    $(if $(DEB_UNREMOVE_FILES_$(package)),$(package), \
    $(if $(DEB_UNDIVERT_FILES_$(package)),$(package), \
    $(if $(DEB_DIVERT_FILES_$(package)),$(package)))))))))))

ifeq ($(DEB_DISPLACE_EXTENSION),)
ifeq ($(DEB_DIVERT_EXTENSION),)
DEB_DISPLACE_EXTENSION = .divert
else
DEB_DISPLACE_EXTENSION = $(DEB_DIVERT_EXTENSION)
endif
endif

# Replace only the last instance of DEB_DISPLACE_EXTENSION in the
# filename, to make it possible to displace /path/foo.divert to
# foo.divert.divert-orig
displace_files_replace_name = $(shell echo $(1) | perl -pe 's/(.*)\Q$(DEB_DISPLACE_EXTENSION)\E/$$1$(2)/')

# Encode a full path into the path it should be diverted to if it's
# hidden
hide_files_name = /usr/share/$(cdbs_curpkg)/$(shell $(DEB_DISPLACE_ENCODER) $(1))

dh_compat_6 := $(shell if [ '$(DH_COMPAT)' -ge 6 ]; then echo y; fi)

reverse = $(foreach n,$(shell seq $(words $(1)) -1 1),$(word $(n),$(1)))
reverse_dh_compat_6 = $(if $(dh_compat_6),$(call reverse,$(1)),$(1))

debian-displace/%: package = $(subst debian-displace/,,$@)
debian-displace/%: displace_files = $(DEB_DISPLACE_FILES_$(package)) $(DEB_DIVERT_FILES_$(package)) $(DEB_TRANSFORM_FILES_$(package))
debian-displace/%: displace_hide_files = $(DEB_HIDE_FILES_$(package)) $(DEB_REMOVE_FILES_$(package))
debian-displace/%: displace_undisplace_files = $(DEB_UNDISPLACE_FILES_$(package)) $(DEB_UNDIVERT_FILES_$(package))
debian-displace/%: displace_unhide_files = $(DEB_UNHIDE_FILES_$(package)) $(DEB_UNREMOVE_FILES_$(package))
debian-displace/%: displace_files_all = $(strip $(displace_files) $(displace_hide_files) $(displace_undisplace_files) $(displace_unhide_files))
debian-displace/%: displace_files_thispkg = $(strip $(displace_files) $(displace_hide_files))
$(patsubst %,debian-displace/%,$(DEB_DISPLACE_PACKAGES)) :: debian-displace/%:
#   Writing shell scripts in makefiles sucks.  Remember to $$ shell
#   variables and include \ at the end of each line.
# Add code to postinst to add/remove diversions and symlinks as appropriate
	set -e; \
	{ \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DISPLACE_EXTENSION#/$(DEB_DISPLACE_EXTENSION)/g' $(DEB_DISPLACE_SCRIPT); \
	    $(if $(displace_files_all), \
		echo 'if [ "$$1" = "configure" ]; then'; \
		$(foreach file,$(displace_undisplace_files), \
		    echo "    check_undisplace_unlink $(call displace_files_replace_name,$(file), )"; )\
		$(foreach file,$(displace_unhide_files), \
		    echo "    check_undisplace_unhide $(file) $(call hide_files_name,$(file))"; )\
		$(foreach file,$(displace_files), \
		    echo "    displace_link $(call displace_files_replace_name,$(file), )";) \
		$(foreach file,$(displace_hide_files), \
		    mkdir -p debian/$(cdbs_curpkg)/usr/share/$(cdbs_curpkg); \
		    echo "    displace_hide $(file) $(call hide_files_name,$(file))";) \
		echo 'fi'; \
	    ) \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).postinst.debhelper
# Add code to prerm script to undo diversions and symlinks when package is removed.
	set -e; \
	{ \
	    $(if $(dh_compat_6),, \
		if [ -e $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper ]; then \
		    cat $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper; \
		fi;) \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DISPLACE_EXTENSION#/$(DEB_DISPLACE_EXTENSION)/g' $(DEB_DISPLACE_SCRIPT); \
	    $(if $(displace_files_thispkg), \
		echo 'if [ "$$1" = "remove" ] || [ "$$1" = "deconfigure" ]; then'; \
		$(foreach file,$(call reverse_dh_compat_6,$(displace_files)), \
		    echo "    undisplace_unlink $(call displace_files_replace_name,$(file), )";) \
		$(foreach file,$(call reverse_dh_compat_6,$(displace_hide_files)), \
		    echo "    undisplace_unhide $(file) $(cdbs_curpkg)";) \
		echo 'fi'; \
	    ) \
	    $(if $(dh_compat_6), \
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
#   Provides: ${diverted-files}
#   Conflicts: ${diverted-files}
	set -e; \
	{ \
	    echo -n "diverted-files="; \
	    $(foreach file,$(displace_files_thispkg),\
		echo -n "diverts-"; \
		${DEB_DISPLACE_ENCODER} "$(call displace_files_replace_name,$(file))"; \
		echo -n ", ";) \
	    echo; \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).substvars

$(patsubst %,binary-post-install/%,$(DEB_DISPLACE_PACKAGES)) :: binary-post-install/%: debian-displace/%

endif
