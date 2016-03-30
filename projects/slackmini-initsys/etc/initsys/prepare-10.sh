#!/bin/sh


	# If there are SystemV init scripts for this runlevel, run them.
	if [ -x /etc/rc.d/rc.sysvinit ]; then
		. /etc/rc.d/rc.sysvinit
	fi


