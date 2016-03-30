#!/bin/sh


	# Adicionando a entrada das montagens em /etc/mtab:
	preprun "Re-ativando ROOT-FS como escrita" "/sbin/mount -f -w /"

	preprun "Ativando PROC-FS" "/sbin/mount -f proc /proc -t proc"
	preprun "Ativando SYS-FS" "/sbin/mount -f sysfs /sys -t sysfs"
	
