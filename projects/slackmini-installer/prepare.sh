#!/bin/sh

# Script para prepara o Linux
# precisamos dele aceitavel para instalar o novo servidor
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#
# Preparar sistema linux (substituto do rc.S)

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

#
# - Executar comando silenciosamente e dar feedback
preprun(){
	label="$1"
	cmd="$2"
	logit -n "$label"
	eval "$cmd" 2>/dev/null 1>/dev/null
	echo_ok
}

# Carregar modulos, se possivel
preprun "Iniciando LOOP-FS" "modprobe loop"

# Deletar lembrancas de montagens
preprun "Preparando FSTAB" "/bin/rm -f /etc/mtab{,~,.tmp} && /bin/touch /etc/mtab"

# Add (fake) entry for / to /etc/mtab:
preprun "Iniciando RAM-FS" "/sbin/mount -f -w /dev/initramfs / -t tmpfs"

# Mount /proc:
preprun "Montando PROC-FS" "/sbin/mount -v proc /proc -t proc"

# Mount sysfs next:
preprun "Montando SYS-FS" "/sbin/mount -v sysfs /sys -t sysfs"

# Activate swap:
preprun "Ativando SWAP-FS" "/sbin/swapon -a"

# ldd libraries links
[ -x /sbin/ldconfig ] && preprun "Ajustando bibliotecas" "/sbin/ldconfig"

# System logger (mostly to eat annoying messages):
preprun "Iniciando processo SYSLOG" "/sbin/syslogd && sleep 1 && /sbin/klogd -c 3"

# Run udev:
if ! grep -wq noudev /proc/cmdline ; then
	# udev ajuda a carregar modulos no kernel
	preprun "Iniciando SYSTEMD UDEV" "/bin/bash /etc/rc.d/rc.udev start"
else
	# modo antigo
	# teclado via usb e pen-drive
	preprun "Iniciando suporte USB" "/etc/rc.d/rc.usb start; sleep 3; [ -x /etc/rc.d/rc.ieee1394 ] && /etc/rc.d/rc.ieee1394 start; sleep 3; /dev/makedevs.sh"

	# Check /proc/partitions again:
	preprun "Criando ponteiros /DEV" "sleep 3; /dev/makedevs.sh"

	# Create LVM nodes:
	preprun "Iniciando DEVMAP" "/dev/devmap_mknod.sh"
fi

# Preparar nome do host
	HOSTNAME=$(head -1 /etc/HOSTNAME 2>/dev/null)
	if [ "x$HOSTNAME" = "x" ]; then HOSTNAME="slackmini.intranet.br"; fi
	/bin/hostname "$HOSTNAME"

# Ativar loopback
	/sbin/ifconfig lo 127.0.0.1
	/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo

# Normalmente nao usamos pcmcia pra nada, mas vai...
	preprun "Iniciando suporte PCMCIA" "chmod 755 /etc/rc.d/rc.pcmcia"

# Subir a rede
#preprun "Iniciando suporte IP" "[ -x /etc/rc.d/rc.inet1 ] && /bin/sh /etc/rc.d/rc.inet1"

# Carregar fontes do terminal
[ -x /etc/rc.d/rc.font ] && preprun "Iniciando suporte a fontes" "/bin/sh /etc/rc.d/rc.font"

# Desativar o descanco do monitor, as vezes trava
	preprun "Preparando monitor" "/bin/setterm -blank 0"

# Salvar qual kernel deve ser utilizado baseado no kernel escolhido no BOOT
	unset SLACK_KERNEL
	for ARG in $(cat /proc/cmdline); do
		argname=$(echo $ARG | cut -f1 -d= -s)
		argvalue=$(echo $ARG | cut -f2 -d= -s)
		if [ "$argname" = "SLACK_KERNEL" ]; then
			IMAGE="$argvalue"
			SLACK_KERNEL="$argvalue"
		fi
	done
	export SLACK_KERNEL
	echo "$SLACK_KERNEL" > /tmp/slack-kernel

# Iniciar interfaces de rede (carregar modulos)
	/bin/sh /etc/setup/networkboot.sh

# Tentar conectar a internet
	/bin/sh /etc/setup/internetboot.sh

# Carregar scripts de perfil (/etc/profile.d/*.sh tambem)
	. /etc/profile


# Start dropbear ssh server (only if a configured interface is present):
	if [ -x /etc/rc.d/rc.dropbear ]; then
		preprun "Iniciando DROPBEAR" "/etc/rc.d/rc.dropbear start"
		logit "Ativando dropbear"
	fi


#------------------------------------------------------------------- INSTALADOR
	logit "Iniciando instalador..."
	sleep 1
	#--clear

	# Iniciar instalacao
	INSTRET=0
	if [ -x /etc/setup/start.sh ]; then
		/etc/setup/start.sh
		INSTRET="$?"
	fi

	if [ "$INSTRET" = "0" ]; then
		logit "Instalador concluido."

		# DESENVOLVIMENTO
		if [ -f /etc/setup/devmode ]; then
			logit "Iniciando shell de desenvolvimento"
			/bin/sh
		fi

		# Finalizar instalador
			/bin/sh /etc/setup/finish.sh

		# Reiniciar
			/bin/sh /etc/setup/reboot.sh

	#else
	#	# houve um erro, deixar o shell natural assumir
	fi























