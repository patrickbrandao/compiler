#!/bin/sh

# Script de instalacao
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#

. /etc/setup/vars.sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

	# Pontos de montagem e informacoes
	ROOT_DIR=$(head -1 /tmp/root-dir)
	BOOT_DIR=$(head -1 /tmp/boot-dir)
	STORE_DIR=$(head -1 /tmp/store-dir)
	SRCDIR=$(head -1 /tmp/srcdir)
	PKGLIST=$(cat /tmp/pkglist)


# Instalar pacotes
#------------------------------------------------------------------------------

	dialog --title "$DISTRO_TITLE" --infobox "\nIniciando instalacao de pacotes\n" 7 40
	sync
	sleep 2
	clear

	# Instalar pacotes
	for xpkg in $PKGLIST; do

		# verificar
		fpkg="$SRCDIR/$xpkg"
		[ -f "$fpkg" ] || exit 31

		# instalar
		/usr/sbin/ixpkg --root "$ROOT_DIR" $fpkg

	done



















