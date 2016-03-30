#!/bin/sh




	# Mount Control Groups filesystem interface:
	if grep -wq cgroup /proc/filesystems ; then
		if [ -d /sys/fs/cgroup ]; then
			# See linux-*/Documentation/cgroups/cgroups.txt (section 1.6)
			# Check if we have some tools to autodetect the available cgroup controllers
			if [ -x /usr/bin/lssubsys -a -x /usr/bin/tr -a -x /usr/bin/sed ]; then
			
				# Mount a tmpfs as the cgroup filesystem root
				mount -t tmpfs -o mode=0755 cgroup_root /sys/fs/cgroup
			
				# Autodetect available controllers and mount them in subfolders
				controllers="$(lssubsys -a 2>/dev/null | tr '\n' ' ' | sed s/.$//)"
				for i in $controllers; do
					mkdir /sys/fs/cgroup/$i
					mount -t cgroup -o $i $i /sys/fs/cgroup/$i
				done
				unset i controllers
			else
				# We can't use autodetection so fall back mounting them all together
				mount -t cgroup cgroup /sys/fs/cgroup
			fi
		else
			mkdir -p /dev/cgroup
			mount -t cgroup cgroup /dev/cgroup
		fi
	fi

