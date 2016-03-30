#!/bin/sh


	# Run serial port setup script:
	# CAREFUL!  This can make some systems hang if the rc.serial script isn't
	# set up correctly.  If this happens, you may have to edit the file from a
	# boot disk, and/or set it as non-executable:
	if [ -x /etc/rc.d/rc.serial ]; then
		sh /etc/rc.d/rc.serial start
	fi

