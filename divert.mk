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

ifndef _cdbs_rules_divert
_cdbs_rules_divert = 1

include /usr/share/cdbs/1/rules/debhelper.mk

CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), config-package-dev (>= 4.5~)

DEB_DIVERT_SCRIPT = /usr/share/config-package-dev/divert.sh.in

DEB_DIVERT_PACKAGES += $(foreach package,$(DEB_ALL_PACKAGES), \
    $(if $(DEB_TRANSFORM_FILES_$(package)),$(package), \
    $(if $(DEB_REMOVE_FILES_$(package)),$(package), \
    $(if $(DEB_UNREMOVE_FILES_$(package)),$(package), \
    $(if $(DEB_UNDIVERT_FILES_$(package)),$(package), \
    $(if $(DEB_DIVERT_FILES_$(package)),$(package)))))))

ifeq ($(DEB_DIVERT_EXTENSION),)
DEB_DIVERT_EXTENSION = .divert
endif

DEB_DIVERT_ENCODER = /usr/share/config-package-dev/encode

divert_files_replace_name = $(shell echo $(1) | perl -pe 's/(.*)\Q$(DEB_DIVERT_EXTENSION)\E/$$1$(2)/')

debian-divert/%: package = $(subst debian-divert/,,$@)
debian-divert/%: divert_files = $(DEB_DIVERT_FILES_$(package)) $(DEB_TRANSFORM_FILES_$(package))
debian-divert/%: divert_remove_files = $(DEB_REMOVE_FILES_$(package))
debian-divert/%: divert_undivert_files = $(DEB_UNDIVERT_FILES_$(package))
debian-divert/%: divert_unremove_files = $(DEB_UNREMOVE_FILES_$(package))
debian-divert/%: divert_files_all = $(strip $(divert_files) $(divert_remove_files) $(divert_undivert_files) $(divert_unremove_files))
debian-divert/%: divert_files_thispkg = $(strip $(divert_files) $(divert_remove_files))
$(patsubst %,debian-divert/%,$(DEB_DIVERT_PACKAGES)) :: debian-divert/%:
	( \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DIVERT_EXTENSION#/$(DEB_DIVERT_EXTENSION)/g' $(DEB_DIVERT_SCRIPT); \
	    $(if $(divert_files_all), \
		echo 'if [ "$$1" = "configure" ]; then'; \
		$(foreach file,$(divert_undivert_files), \
		    $(if $(DEB_UNDIVERT_VERSION_$(file)),,\
			echo "ERROR!  Missing undivert version for $(file)!">&2; exit 1;) \
		    echo -n "    if [ -n \"\$$2\" ] && dpkg --compare-versions \"\$$2\" '<<' "; \
		    echo "'$(DEB_UNDIVERT_VERSION_$(file))'; then"; \
		    echo "        undivert_unlink $(call divert_files_replace_name,$(file), )"; \
		    echo "    fi";) \
		$(foreach file,$(divert_unremove_files), \
		    $(if $(DEB_UNREMOVE_VERSION_$(file)),,\
			echo "ERROR!  Missing unremove version for $(file)!">&2; exit 1;) \
		    echo -n "    if [ -n \"\$$2\" ] && dpkg --compare-versions \"\$$2\" '<<' "; \
		    echo "'$(DEB_UNREMOVE_VERSION_$(file))'; then"; \
		    echo "        undivert_unremove $(file)"; \
		    echo "    fi";) \
		$(foreach file,$(divert_files), \
		    echo "    divert_link $(call divert_files_replace_name,$(file), )";) \
		$(foreach file,$(divert_remove_files), \
		    mkdir -p $(DEB_DESTDIR)/usr/share/$(cdbs_curpkg); \
		    echo "    divert_remove $(file) /usr/share/$(cdbs_curpkg)/`$(DEB_DIVERT_ENCODER) $(file)`";) \
		echo 'fi'; \
	    ) \
	) >> $(CURDIR)/debian/$(cdbs_curpkg).postinst.debhelper
	( \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DIVERT_EXTENSION#/$(DEB_DIVERT_EXTENSION)/g' $(DEB_DIVERT_SCRIPT); \
	    $(if $(divert_files_thispkg), \
		echo 'if [ "$$1" = "remove" ]; then'; \
		$(foreach file,$(divert_files), \
		    echo "    undivert_unlink $(call divert_files_replace_name,$(file), )";) \
		$(foreach file,$(divert_remove_files), \
		    echo "    undivert_unremove $(file) $(cdbs_curpkg)";) \
		echo 'fi'; \
	    ) \
	) >> $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper
	( \
	    echo -n "diverted-files="; \
	    $(foreach file,$(divert_files_thispkg),\
		echo -n "configures-"; \
		${DEB_DIVERT_ENCODER} "$(call divert_files_replace_name,$(file))"; \
		echo -n ", ";) \
	    echo \
	) >> $(CURDIR)/debian/$(cdbs_curpkg).substvars

$(patsubst %,binary-post-install/%,$(DEB_DIVERT_PACKAGES)) :: binary-post-install/%: debian-divert/%

endif
