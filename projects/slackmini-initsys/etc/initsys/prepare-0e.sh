#!/bin/sh



	# Mount non-root file systems in fstab, but not NFS or SMB 
	# because TCP/IP is not yet configured, and not proc or sysfs
	# because those have already been mounted.  Also check that
	# devpts is not already mounted before attempting to mount
	# it.  With a 2.6.x or newer kernel udev mounts devpts.
	# We also need to wait a little bit to let USB and other
	# hotplugged devices settle (sorry to slow down the boot):
	logit "Mounting non-root local filesystems:"
	sleep 3
	if /bin/grep -wq devpts /proc/mounts ; then
		# This pipe after the mount command is just to convert the new
		# mount verbose output back to the old format that contained
		# more useful information:
		/sbin/mount -a -v -t nonfs,nosmbfs,nocifs,noproc,nosysfs,nodevpts | grep successfully | cut -f 1 -d : | tr -d ' ' | while read dev ; do mount | grep "${dev} " ; done
	else
		/sbin/mount -a -v -t nonfs,nosmbfs,nocifs,noproc,nosysfs | grep successfully | cut -f 1 -d : | tr -d ' ' | while read dev ; do mount | grep "${dev} " ; done
	
	fi


