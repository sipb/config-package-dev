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

ifndef _cdbs_rules_debconf_divert
_cdbs_rules_debconf_divert = 1

CDBS_BUILD_DEPENDS := $(CDBS_BUILD_DEPENDS), config-package-dev (>= 3.2~)

DEB_DEBCONF_HACK_SCRIPT = /usr/share/config-package-dev/debconf-hack.sh

DEB_DEBCONF_HACK_PACKAGES += $(foreach package,$(DEB_ALL_PACKAGES), \
    $(if $(wildcard debian/$(package).debconf-hack),$(package)))

dh_compat_6 := $(shell if [ '$(DH_COMPAT)' -ge 6 ]; then echo y; fi)

$(patsubst %,debian-debconf-hack/%,$(DEB_DEBCONF_HACK_PACKAGES)) :: debian-debconf-hack/%:
	set -e; \
	{ \
	    cat $(DEB_DEBCONF_HACK_SCRIPT); \
	    echo 'if [ ! -f /var/cache/$(cdbs_curpkg).debconf-save ]; then'; \
	    echo '    debconf_get $(shell cut -d'	' -f2 debian/$(cdbs_curpkg).debconf-hack) >/var/cache/$(cdbs_curpkg).debconf-save'; \
	    echo '    debconf_set <<EOF'; \
	    sed 's/$$/	true/' debian/$(cdbs_curpkg).debconf-hack; \
	    echo 'EOF'; \
	    echo 'fi'; \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).preinst.debhelper
	set -e; \
	{ \
	    cat $(DEB_DEBCONF_HACK_SCRIPT); \
	    echo 'if [ -f /var/cache/$(cdbs_curpkg).debconf-save ]; then'; \
	    echo '    debconf_set </var/cache/$(cdbs_curpkg).debconf-save'; \
	    echo '    rm -f /var/cache/$(cdbs_curpkg).debconf-save'; \
	    echo 'fi'; \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).postinst.debhelper
	set -e; \
	{ \
	    $(if $(dh_compat_6),, \
		if [ -e $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper ]; then \
		    cat $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper; \
		fi;) \
	    cat $(DEB_DEBCONF_HACK_SCRIPT); \
	    echo 'if [ -f /var/cache/$(cdbs_curpkg).debconf-save ]; then'; \
	    echo '    debconf_set </var/cache/$(cdbs_curpkg).debconf-save'; \
	    echo '    rm -f /var/cache/$(cdbs_curpkg).debconf-save'; \
	    echo 'fi'; \
	    $(if $(dh_compat_6), \
		if [ -e $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper ]; then \
		    cat $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper; \
		fi;) \
	} >> $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper.new
	mv $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper.new \
	    $(CURDIR)/debian/$(cdbs_curpkg).postrm.debhelper

$(patsubst %,binary-fixup/%,$(DEB_DEBCONF_HACK_PACKAGES)) :: binary-fixup/%: debian-debconf-hack/%

endif
