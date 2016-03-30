#!/bin/sh

#
# Rodar script pelo identificador
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/initsys"


# Functions
	. /etc/initsys/prepare-lib.sh


#*********************************************************************************************

	# Functions
	script="/etc/initsys/prepare-$1.sh"
	if [ -f "$script" ]; then
		. $script
	else
		echo "Script $script not found."
	fi


#*********************************************************************************************

