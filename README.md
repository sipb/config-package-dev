config-package-dev
===

config-package-dev is a tool for building Debian _configuration
packages_, that is, packages that configure other Debian packages
already on your system. It is an alternative to configuration-management
tools (e.g., Ansible, Chef, Puppet, cfengine) that integrates cleanly
with the Debian packaging system: you can apply configuration by
installing a configuration package, and remove it cleanly by
uninstalling it. config-package-dev uses `dpkg-divert` to inform the
packaging system that it is changing files owned by another package,
which means that your changes remain applied even when the original
package is upgraded.

Configuration packages are particularly useful for sites using Debian or
Ubuntu (or another dpkg-based distribution) who are already running
their own internal apt repository. You can provide site defaults and
configuration through your existing package-update processes, and make
sure systems are up-to-date in both software and configuration by
checking what versions of packages they have installed.
(config-package-dev is not intended for use by packages in Debian
itself.)

config-package-dev is a project of [MIT SIPB](https://sipb.mit.edu/),
and was originally developed for the
[Debathena](https://debathena.mit.edu) project to provide functionality
to access MIT computing services (e.g., Kerberos and AFS configuration)
on privately owned machines.

To get started, install `config-package-dev` from your package manager;
we support the versions in the Debian and Ubuntu archives. Take a look
at the [examples](examples/debhelper), or check out the full
documentation at
[https://debathena.mit.edu/config-package-dev](https://debathena.mit.edu/config-package-dev). 
If you're using config-package-dev, please also join the
[config-package-dev@mit.edu mailing
list](https://mailman.mit.edu/mailman/listinfo/config-package-dev).

config-package-dev itself is [licensed under the
GPLv2+](debian/copyright), but the code it
adds to configuration packages is [released under the MIT
license](https://github.com/sipb/config-package-dev/commit/8d36c7611f0b3f3a16447b613d0e2a6ad0b1059f#diff-e93fa5c394e60f185a53f9ff00b68eb2)
and automatically includes the MIT license in the added code.

Feel free to report bugs or submit patches either on GitHub or [on the Debian
bug tracker](https://bugs.debian.org/src:config-package-dev).

[![Build Status](https://travis-ci.org/sipb/config-package-dev.svg?branch=master)](https://travis-ci.org/sipb/config-package-dev)
