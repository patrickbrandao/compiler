#!/bin/sh

	# Mount usbfs only if it is found in /etc/fstab:
	if grep -wq usbfs /proc/filesystems; then
		if ! grep -wq usbfs /proc/mounts ; then
			if grep -wq usbfs /etc/fstab; then
				/sbin/mount -v /proc/bus/usb
			fi
		fi
	fi



	