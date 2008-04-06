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

CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), config-package-dev

DEB_DIVERT_SCRIPT = /usr/share/config-package-dev/divert.sh.in

DEB_DIVERT_PACKAGES += $(foreach package,$(DEB_ALL_PACKAGES), \
    $(if $(DEB_REPLACE_FILES_$(package)),$(package), \
    $(if $(DEB_DIVERT_FILES_$(package)),$(package))))

ifeq ($(DEB_DIVERT_EXTENSION),)
DEB_DIVERT_EXTENSION = .divert
endif

DEB_DIVERT_ENCODER = /usr/share/config-package-dev/encode

debian-divert/%: package = $(subst debian-divert/,,$@)
debian-divert/%: replace_inputs = $(DEB_REPLACE_FILES_$(package))
debian-divert/%: replace_files = $(foreach file,$(replace_inputs),$(file))
debian-divert/%: divert_files = $(DEB_DIVERT_FILES_$(package)) $(replace_files)
$(patsubst %,debian-divert/%,$(DEB_DIVERT_PACKAGES)) :: debian-divert/%:
	( \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DIVERT_EXTENSION#/$(DEB_DIVERT_EXTENSION)/g' $(DEB_DIVERT_SCRIPT); \
	    $(if $(divert_files), \
		echo 'if [ "$$1" = "configure" ]; then'; \
		$(foreach file,$(divert_files), \
		    echo "    divert_link $(subst $(DEB_DIVERT_EXTENSION), ,$(file))";) \
		echo 'fi'; \
	    ) \
	) >> $(CURDIR)/debian/$(cdbs_curpkg).postinst.debhelper
	( \
	    sed 's/#PACKAGE#/$(cdbs_curpkg)/g; s/#DEB_DIVERT_EXTENSION#/$(DEB_DIVERT_EXTENSION)/g' $(DEB_DIVERT_SCRIPT); \
	    $(if $(divert_files), \
		echo 'if [ "$$1" = "remove" ]; then'; \
		$(foreach file,$(divert_files), \
		    echo "    undivert_unlink $(subst $(DEB_DIVERT_EXTENSION), ,$(file))";) \
		echo 'fi'; \
	    ) \
	) >> $(CURDIR)/debian/$(cdbs_curpkg).prerm.debhelper
	( \
	    echo -n "diverted-files="; \
	    $(foreach file,$(divert_files),\
		${DEB_DIVERT_ENCODER} "$(subst $(DEB_DIVERT_EXTENSION),,$(file))"; \
		echo -n ", ";) \
	    echo \
	) >> $(CURDIR)/debian/$(cdbs_curpkg).substvars

$(patsubst %,binary-fixup/%,$(DEB_DIVERT_PACKAGES)) :: binary-fixup/%: debian-divert/%

endif
