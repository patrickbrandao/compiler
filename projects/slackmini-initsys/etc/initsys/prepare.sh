#!/bin/sh
#
# Primeiro script de boot.
#
# Preparar o sistema para execucao de softwares (substituto do rc.S)
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/initsys"


#*********************************************************************************************

	# Functions
	. /etc/initsys/prepare-lib.sh

	# Inicializar sistema de arquivos virtuais (kernel)
	. /etc/initsys/prepare-00.sh

	# Modulos manuais
	. /etc/initsys/prepare-mm.sh

	# Deteccao de modulos
	. /etc/initsys/prepare-udev.sh

	# Mount Control Groups filesystem interface
	. /etc/initsys/prepare-01.sh

	# SWAP
	. /etc/initsys/prepare-02.sh

	# FUSE
	. /etc/initsys/prepare-03.sh

	# Tick/frequency sys clock
	. /etc/initsys/prepare-04.sh

	# FS-Check
	. /etc/initsys/prepare-05.sh

	# M-TAB
	. /etc/initsys/prepare-06.sh

	# remount kernel fs
	. /etc/initsys/prepare-07.sh

	# modules/udev
	. /etc/initsys/prepare-08.sh

	# isa-pnp
	. /etc/initsys/prepare-09.sh

	# manual modules
	. /etc/initsys/prepare-0a.sh

	# sysctl
	. /etc/initsys/prepare-0b.sh

	# check fs
	. /etc/initsys/prepare-0c.sh

	# usbfs
	. /etc/initsys/prepare-0d.sh

	# non-root file system
	. /etc/initsys/prepare-0e.sh

	# SWAP (novamente)
	. /etc/initsys/prepare-02.sh

#*********************************************************************************************

	# Clean up
	. /etc/initsys/prepare-0f.sh

	# sysvinit
	. /etc/initsys/prepare-10.sh

	# serial
	. /etc/initsys/prepare-11.sh

	# random-seed
	. /etc/initsys/prepare-12.sh

	# hostname
	. /etc/initsys/prepare-13.sh

#*********************************************************************************************

	
	# Eventos de pacotes
	. /etc/initsys/prepare-pkg.sh


#*********************************************************************************************

	# Integracao personalizada
	for xx in f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff; do
		script="/etc/initsys/prepare-$xx.sh"
		if [ -x "$script" ]; then
			logit2 "Script integrador:" "$script"
			/bin/sh "$script"
		fi
	done














