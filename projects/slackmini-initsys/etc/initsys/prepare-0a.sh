#!/bin/sh


	# This loads any kernel modules that are needed.  These might be required to
	# use your ethernet card, sound card, or other optional hardware.
	# Priority is given first to a script named "rc.modules.local", then
	# to "rc.modules-$FULL_KERNEL_VERSION", and finally to the plain "rc.modules".
	# Note that if /etc/rc.d/rc.modules.local is found, then that will be the ONLY
	# rc.modules script the machine will run, so make sure it has everything in
	# it that you need.
	if [ -x /etc/rc.d/rc.modules.local -a -r /proc/modules ]; then
		logit "Executando /etc/rc.d/rc.modules.local:"
		/bin/sh /etc/rc.d/rc.modules.local
	elif [ -x /etc/rc.d/rc.modules-$(uname -r) -a -r /proc/modules ]; then
		logit "Executando /etc/rc.d/rc.modules-$(uname -r):"
		. /etc/rc.d/rc.modules-$(uname -r)
	elif [ -x /etc/rc.d/rc.modules -a -r /proc/modules -a -L /etc/rc.d/rc.modules ]; then
		logit "Executando /etc/rc.d/rc.modules -> $(readlink /etc/rc.d/rc.modules):"
		. /etc/rc.d/rc.modules
	elif [ -x /etc/rc.d/rc.modules -a -r /proc/modules ]; then
		logit "Executando /etc/rc.d/rc.modules:"
		. /etc/rc.d/rc.modules
	fi

