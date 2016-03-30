#!/bin/sh

#
#
# Parar todo o sistema para desligar/reiniciar
# - parar todos os servicos
# - executar tarefas onshutdown
# - garantir seguranca do sistema de arquivos
#
#
#

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Evento invocado pelo usuario: 'shutdown' ou 'reboot'
	EVENT="$1"

#********************************************************************************************* ENCERRANDO SERVICOS

	# Set linefeed mode to avoid staircase effect.
	/bin/stty onlcr

	# parar todos os servicos
	/etc/initsys/services.sh shutdown


#********************************************************************************************* ACIONANDO PERSONALIZACOES DE DESLIGAMENTO


  # Run any local shutdown scripts:
  if [ -x /etc/rc.d/rc.local_shutdown ]; then
    /etc/rc.d/rc.local_shutdown stop
  fi

#********************************************************************************************* EVENTOS DE PACOTES NO DESLIGAMENTO


  # - segundo executar scripts de eventos necessarios pelos pacotes
  /usr/sbin/expkg "shutdown"


#********************************************************************************************* ENCERRANDO DATA/HORA

	# 
	# Salvar a data/hora do sistema, provavelmente sincronizada com NTP
	# na BIOS (relogio de hardware)
	#
	if [ -x /sbin/hwclock ]; then
		# Check for a broken motherboard RTC clock (where ioports for rtc are
		# unknown) to prevent hwclock causing a hang:
		if ! grep -q " : rtc" /proc/ioports ; then
			CLOCK_OPT="--directisa"
		fi
		if [ /etc/adjtime -nt /etc/hardwareclock ]; then
			logit -n "Salvando data/hora do sistema no relogio de hardware (BIOS), "
			if grep -q "^LOCAL" /etc/adjtime ; then
				echoc -c yellow "LOCALTIME"
			else
				echoc -c yellow "UTC"
			fi
			/sbin/hwclock $CLOCK_OPT --systohc
		elif grep -q "^UTC" /etc/hardwareclock 2> /dev/null ; then
			logit "Salvando data/hora do sistema no relogio de hardware (BIOS), HW-UTC"
			if [ ! -r /etc/adjtime ]; then
				logit "Criando arquivo de correcao de data/hora: /etc/adjtime."
			fi
			/sbin/hwclock $CLOCK_OPT --utc --systohc
		else
			logit "Salvando data/hora do sistema no relogio de hardware (BIOS), HW-LOCAL"
			if [ ! -r /etc/adjtime ]; then
				logit "Criando arquivo de correcao de data/hora: /etc/adjtime."
			fi
			/sbin/hwclock  $CLOCK_OPT --localtime --systohc
		fi
	fi

#********************************************************************************************* ENCERRANDO SUB-SISTEMAS


	# Encerrando suporte a rede
	if [ -x /etc/rc.d/rc.inet1 ]; then
		/etc/rc.d/rc.inet1 stop
	fi


	# Kill all remaining processes.
	# Don't kill mdmon
	OMITPIDS="$(for p in $(pgrep mdmon); do echo -o $p; done)"
	if [ ! "$1" = "fast" ]; then

		logit "Enviando sinal de SIGTERM para todos os processos."
		/sbin/killall5 -15 $OMITPIDS
		/bin/sleep 5

		logit "Enviando sinal de SIGKILL para todos os processos."
		/sbin/killall5 -9 $OMITPIDS

	fi

	# Carry a random seed between reboots.
	logit "Salvando random seed de /dev/urandom para /etc/random-seed."
	# Use the pool size from /proc, or 4096 bits:
	if [ -r /proc/sys/kernel/random/poolsize ]; then
		/bin/dd if=/dev/urandom of=/etc/random-seed count=1 bs=$(expr $(cat /proc/sys/kernel/random/poolsize) / 8) 2> /dev/null
	else
		/bin/dd if=/dev/urandom of=/etc/random-seed count=1 bs=512 2> /dev/null
	fi
	/bin/chmod 600 /etc/random-seed

	# Before unmounting file systems write a reboot or halt record to wtmp.
	$command -w

#********************************************************************************************* Liberando SWAP

	# Turn off swap:
	logit "Desligando SWAP-FS"
	/sbin/swapoff -a
	/bin/sync

	logit "Desmontando sistemas de arquivos locais."
	/bin/umount -v -a -t no,proc,sysfs | tr -d ' ' | grep successfully | sed "s/:successfullyunmounted/ has been successfully unmounted./g" 2> /dev/null

	logit "Alternando ROOT para somente leitura."
	/bin/mount -v -n -o remount,ro /

	# This never hurts:
	/bin/sync

	# This never hurts again (especially since root-on-LVM always fails
	# to deactivate the / logical volume...  but at least it was
	# remounted as read-only first)
	/bin/sync

	# sleep 3 fixes problems with some hard drives that don't
	# otherwise finish syncing before reboot or poweroff
	/bin/sleep 3

	# This is to ensure all processes have completed on SMP machines:
	wait

	if [ -x /sbin/genpowerd ]; then
		# See if this is a powerfail situation:
		if /bin/egrep -q "FAIL|SCRAM" /etc/upsstatus 2> /dev/null ; then

			# Signal UPS to shut off the inverter:
			/sbin/genpowerd -k
			if [ ! $? = 0 ]; then
				echo
				echo "There was an error signaling the UPS."
				echo "Perhaps you need to edit /etc/genpowerd.conf to configure"
				echo "the serial line and UPS type."
				# Wasting 15 seconds of precious power:
				/bin/sleep 15
			fi
		fi
	fi

	# Now halt (poweroff with APM or ACPI enabled kernels) or reboot.
	if [ "$EVENT" = "reboot" ]; then
		logit "Reiniciando AGORA"
		/sbin/reboot
	else
		logit "Desligando AGORA"
		/sbin/poweroff
	fi








