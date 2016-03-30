#!/bin/sh




# Sistema de arquivos do kernel necessarios
	preprun "Iniciando PROC-FS" "/sbin/mount -v proc /proc -n -t proc"
	preprun "Iniciando SYS-FS" "/sbin/mount -v sysfs /sys -n -t sysfs"
	preprun "Iniciando TMP-FS" "/sbin/mount -v -n -t tmpfs tmpfs /run -o mode=0755"

