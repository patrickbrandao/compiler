#!/bin/sh


	# Carry an entropy pool between reboots to improve randomness.
	if [ -f /etc/random-seed ]; then
		logit "Using /etc/random-seed to initialize /dev/urandom."
		cat /etc/random-seed > /dev/urandom
	fi


	# Use the pool size from /proc, or 4096 bits:
	if [ -r /proc/sys/kernel/random/poolsize ]; then
		dd if=/dev/urandom of=/etc/random-seed count=1 bs=$(expr $(cat /proc/sys/kernel/random/poolsize) / 8) 2> /dev/null
	else
		dd if=/dev/urandom of=/etc/random-seed count=1 bs=512 2> /dev/null
	fi
	chmod 600 /etc/random-seed


