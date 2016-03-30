#!/bin/sh


	# Configurar nome do servidor
	DFHN=servidor
	if [ -r /etc/HOSTNAME ]; then
		HN=$(cat /etc/HOSTNAME | cut -f1 -d .)
		if [ "x$HN" = "x" ]; then HN="$DFHN"; fi
	else
		# sem arquivo hostname, esquisito,
		# improvisar e deixar recuperacao resolver
		echo "$HN" > /etc/HOSTNAME
	fi
	HOST=$(echo $HN | cut -f1 -d.)

	logit "Hostname $HOST ($HN)"
	/bin/hostname $HOST


