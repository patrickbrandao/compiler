#!/bin/sh

#
# Preparador de ambiente multi-usuario e execucao de aplicativos
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/initsys"


#*********************************************************************************************

	# Functions
	. /etc/initsys/prepare-lib.sh


#*********************************************************************************************

	logitg "Iniciando aplicativos e servicos"


	# Sincronizar bibliotecas (enviar para background para nao atrasar o boot)
	if [ -x /sbin/ldconfig ]; then
		logit "Atualizando links de bibliotecas"
		/sbin/ldconfig &
	fi

	# Opcoes de terminal (setterm)
	if [ -x /etc/rc.d/rc.term ]; then
		# /bin/setterm -blank 15 -powersave powerdown -powerdown 60
		/etc/rc.d/rc.term start
	fi

	# Set the permissions on /var/log/dmesg according to whether the kernel
	logit "Salvando mensagens do kernel (/var/log/dmesg)"
	# permits non-root users to access kernel dmesg information:
	if [ -r /proc/sys/kernel/dmesg_restrict ]; then
		if [ $(cat /proc/sys/kernel/dmesg_restrict) = 1 ]; then
			touch /var/log/dmesg
			chmod 640 /var/log/dmesg
		fi
	else
		touch /var/log/dmesg
		chmod 644 /var/log/dmesg
	fi
	# Save the contents of 'dmesg':
	/bin/dmesg -s 65536 > /var/log/dmesg

	# Start the system logger.
	if [ -x /etc/rc.d/rc.syslog -a -x /usr/sbin/syslogd -a -d /var/log ]; then
		. /etc/rc.d/rc.syslog start
	fi

	# Update the X font indexes:
	if [ -x /usr/bin/fc-cache ]; then
		logit "Atualizando indice de fontes do X"
		/usr/bin/fc-cache -f &
	fi

	# Run rc.udev again.  This will start udev if it is not already running
	# (for example, upon return from runlevel 1), otherwise it will trigger it
	# to look for device changes and to generate persistent rules if needed.
	if grep -wq sysfs /proc/mounts && grep -q devtmpfs /proc/filesystems ; then
		if ! grep -wq nohotplug /proc/cmdline ; then
			if [ -x /etc/rc.d/rc.udev ]; then
				/bin/sh /etc/rc.d/rc.udev start
			fi
		fi
	fi

	# Ordenando interfaces de rede
	if [ -x /usr/sbin/eth-mac-sort ]; then
		/usr/sbin/eth-mac-sort
	fi

	# Initialize the networking hardware.
	logit "Iniciando suporte a rede IP"
	if [ -x /etc/rc.d/rc.inet1 ]; then
		/etc/rc.d/rc.inet1
	fi

	# Start the OpenSSH SSH daemon:
	if [ -x /etc/rc.d/rc.sshd ]; then
		logit "Starting OpenSSH SSH daemon:  /usr/sbin/sshd"
		/etc/rc.d/rc.sshd start
	fi

	# Remove stale locks and junk files (must be done after mount -a!)
	/bin/rm -f /var/lock/* /var/spool/uucp/LCK..* /tmp/.X*lock /tmp/core /core 2> /dev/null
	/bin/rm -rf /var/spool/cron/cron.?????? 2> /dev/null

	# Remove stale hunt sockets so the game can start.
	if [ -r /tmp/hunt -o -r /tmp/hunt.stats ]; then
		logit "Removing your stale hunt sockets from /tmp."
		/bin/rm -f /tmp/hunt*
	fi

	# Ensure basic filesystem permissions sanity.
	chmod 755 / 2> /dev/null
	chmod 1777 /tmp /var/tmp

	# Start APM or ACPI daemon.
	# If APM is enabled in the kernel, start apmd:
	if [ -e /proc/apm ]; then
		if [ -x /usr/sbin/apmd ]; then
			logit "Starting APM daemon:  /usr/sbin/apmd"
			/usr/sbin/apmd
		fi
	elif [ -x /etc/rc.d/rc.acpid ]; then # otherwise, start acpid:
		. /etc/rc.d/rc.acpid start
	fi

	# Start D-Bus:
	if [ -x /etc/rc.d/rc.messagebus ]; then
		sh /etc/rc.d/rc.messagebus start
	fi

	# Start console-kit-daemon:
	if [ -x /etc/rc.d/rc.consolekit ]; then
		sh /etc/rc.d/rc.consolekit start
	fi

	# Start HAL:
	if [ -x /etc/rc.d/rc.hald ]; then
		sh /etc/rc.d/rc.hald start
	fi

	# Start crond (Dillon's crond):
	# If you want cron to actually log activity to /var/log/cron, then change
	# -l notice to -l info to increase the logging level.
	if [ -x /usr/sbin/crond ]; then
		/usr/sbin/crond -l notice
	fi

	# Load a custom screen font if the user has an rc.font script.
	if [ -x /etc/rc.d/rc.font ]; then
		. /etc/rc.d/rc.font
	fi

	# Load a custom keymap if the user has an rc.keymap script.
	if [ -x /etc/rc.d/rc.keymap ]; then
		. /etc/rc.d/rc.keymap
	fi

	# Start the MySQL database:
	#if [ -x /etc/rc.d/rc.mysqld ]; then
	#	. /etc/rc.d/rc.mysqld start
	#fi

	# Iniciar servicos
	/etc/initsys/services.sh init

	# Start the local setup procedure.
	if [ -x /etc/rc.d/rc.local ]; then
		logit "Executando scripts locais (/etc/rc.d/rc.local)"
		/etc/rc.d/rc.local
	fi

#*********************************************************************************************

	# Integracao personalizada
	for xx in f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff; do
		script="/etc/initsys/multiuser-$xx.sh"
		if [ -x "$script" ]; then
			logit2 "Script de servico:" "$script"
			/bin/sh "$script"
		fi
	done














