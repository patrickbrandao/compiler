#!/bin/sh



	# Clean up some temporary files:
	rm -f /var/run/* /var/run/*/* /var/run/*/*/* /etc/nologin \
		/etc/dhcpc/*.pid /etc/forcefsck /etc/fastboot \
		/var/state/saslauthd/saslauthd.pid \
		/tmp/.Xauth* 1> /dev/null 2> /dev/null
	( cd /var/log/setup/tmp && rm -rf * ) 2>/dev/null
	( cd /tmp && rm -rf kde-[a-zA-Z]* ksocket-[a-zA-Z]* hsperfdata_[a-zA-Z]* plugtmp* ) 2>/dev/null

	# Clear /var/lock/subsys:
	if [ -d /var/lock/subsys ]; then
		rm -f /var/lock/subsys/* 2>/dev/null
	fi

	# Create /tmp/{.ICE-unix,.X11-unix} if they are not present:
	if [ ! -e /tmp/.ICE-unix ]; then
		mkdir -p /tmp/.ICE-unix
		chmod 1777 /tmp/.ICE-unix
	fi
	if [ ! -e /tmp/.X11-unix ]; then
		mkdir -p /tmp/.X11-unix
		chmod 1777 /tmp/.X11-unix
	fi

	# Create a fresh utmp file:
	touch /var/run/utmp
	chown root:utmp /var/run/utmp
	chmod 664 /var/run/utmp


	