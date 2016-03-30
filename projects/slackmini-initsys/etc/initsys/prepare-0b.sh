#!/bin/sh



	# Configure kernel parameters:
	if [ -x /sbin/sysctl -a -r /etc/sysctl.conf ]; then
		logit "Configuring kernel parameters:  /sbin/sysctl -e --system"
		/sbin/sysctl -e --system

	elif [ -x /sbin/sysctl  ]; then
		logit "Configuring kernel parameters:  /sbin/sysctl -e --system"
		# Don't say "Applying /etc/sysctl.conf" or complain if the file doesn't exist
		/sbin/sysctl -e --system 2> /dev/null | grep -v "Applying /etc/sysctl.conf"

	fi

	