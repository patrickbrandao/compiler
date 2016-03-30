#!/bin/sh


	
	# Set the tick and frequency for the system clock.
	# Default values are: TICK=10000 and FREQ=0
	TICK=10000
	FREQ=0
	# If there's a /etc/default/adjtimex config file, source it to override
	# the default TICK and FREQ:
	if [ -r /etc/default/adjtimex ]; then
		. /etc/default/adjtimex
	fi
	if /sbin/adjtimex --tick $TICK --frequency $FREQ; then
		logit "Setting the system clock rate:  /sbin/adjtimex --tick $TICK --frequency $FREQ"
	else
		logitr "Failed to set system clock with adjtimex, possibly invalid parameters? (TICK=$TICK FREQ=$FREQ)"
	fi

	# Set the system time from the hardware clock using hwclock --hctosys.
	if [ -x /sbin/hwclock ]; then
		# Check for a broken motherboard RTC clock (where ioports for rtc are
		# unknown) to prevent hwclock causing a hang:
		if ! grep -q " : rtc" /proc/ioports ; then
			CLOCK_OPT="--directisa"
		fi

		if [ /etc/adjtime -nt /etc/hardwareclock ]; then
			if grep -q "^LOCAL" /etc/adjtime ; then
				logit "Setting system time from the hardware clock (localtime):  "
			else
				logit "Setting system time from the hardware clock (UTC):  "
			fi

			/sbin/hwclock $CLOCK_OPT --hctosys

		elif grep -wq "^localtime" /etc/hardwareclock 2> /dev/null ; then
		
			logit "Setting system time from the hardware clock (localtime):  "
			/sbin/hwclock $CLOCK_OPT --localtime --hctosys

		else

			logit "Setting system time from the hardware clock (UTC):  "
			/sbin/hwclock $CLOCK_OPT --utc --hctosys
		fi

		date

	fi

