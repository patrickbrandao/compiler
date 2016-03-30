#!/bin/sh

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

	# Finalizar instalacao

	# Desmontar pontos de montagem
	/sbin/swapoff -a >/dev/null 2>&1
	/bin/umount -a -r >/dev/null 2>&1
	/sbin/vgchange -an --ignorelockingfailure >/dev/null 2>&1

	# Desligar servidor ssh
	/bin/killall dropbear > /dev/null 2>&1

	# Desligar dhcpcd
	/bin/killall dhcpcd > /dev/null 2>&1

