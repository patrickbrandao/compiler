#!/bin/sh



	# Check all the non-root filesystems:
	if [ ! -r /etc/fastboot ]; then
		logit "Checking non-root filesystems:"
		/sbin/fsck $FORCEFSCK -C -R -A -a
	fi

