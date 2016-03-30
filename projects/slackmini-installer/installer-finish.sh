#!/bin/sh

# Finalizar a instalacao

. /etc/setup/vars.sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"


	dialog --title "$DISTRO_TITLE" --infobox "\nFinalizando instalador\n" 7 40


	# Pontos de montagem e informacoes
	ROOT_DIR=$(head -1 /tmp/root-dir)
	BOOT_DIR=$(head -1 /tmp/boot-dir)
	STORE_DIR=$(head -1 /tmp/store-dir 2>/dev/null)
	SRCDIR=$(head -1 /tmp/srcdir)
	PDNDIR=$(head -1 /tmp/pdn-mount)
	ISODEV=$(head -1 /tmp/isodev)
	ISODIR="/mnt/iso-mount"

	ALLPOINTS="
		$BOOT_DIR
		$STORE_DIR

		$PDNDIR
		$ISODIR
		$ISODEV

		$SRCDIR

		$ROOT_DIR
	"
	# Desmontar tudo
	dots=""
	for point in $ALLPOINTS; do
		(umount -f $point  2>/dev/null 1>/dev/null) 2>/dev/null 1>/dev/null &

		dialog --title "$DISTRO_TITLE" --infobox "\nFinalizando instalador.$dots\n" 7 40
		sleep 1
		dots=".$dots"

	done
	# desmontar tudo dentro da pasta de root da instalacao (procfs, sysfs, run, ...)
	dialog --title "$DISTRO_TITLE" --infobox "\nDesmontando disco de instalacao...\n" 7 40
	(umount -f $BOOT_DIR/*  2>/dev/null 1>/dev/null) 2>/dev/null 1>/dev/null &
	sync

	# ejetar ISO
	if [ "x$ISODEV" = "x" ]; then

		# sem iso
		true

	else

		# ejetar
		dialog --title "$DISTRO_TITLE" --infobox "\nRetirando disco de instalacao\n" 7 40
		(
			eject || eject "$ISODEV" || eject -t "$ISODEV"
		) 2>/dev/null 1>/dev/null

	fi


	# aviso final de reboot
	dialog --title "$DISTRO_TITLE" --infobox "\nReiniciando...\n" 7 40


