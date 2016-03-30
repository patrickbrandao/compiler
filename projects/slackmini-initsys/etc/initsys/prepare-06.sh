#!/bin/sh


	# Any /etc/mtab that exists here is old, so we start with a new one:
	/bin/rm -f /etc/mtab{,~,.tmp} && /bin/touch /etc/mtab


