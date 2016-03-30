#!/bin/sh

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

#
# Iniciar rede IPv4 / IPv6
#

	# Funcao para verificar se um modulo ja esta carregado
	_modloaded(){
		_mod="$1"
		_modules=$(lsmod | awk '{print $1}')
		for _mloaded in $_modules; do
			if [ "$_mloaded" = "$_mod" ]; then return 0; fi
		done
		return 2
	}

# Lista de eth's
	ethers=$(lseth)
	tmpethers="$ethers"
	rm -f /tmp/net-modules 2>/dev/null

# Verificar se alguma interface esta presente
	logit -n "Iniciando interfaces de rede"
	if [ "x$ethers" = "x" -o "x$1" = "x-f" ]; then
		# nenhuma interface de rede foi detectada
		echo_failure
	else
		echo_done
	fi

# Detectar novas interfaces de rede com modulos que nao subiram automaticamente
	if [ "x$ethers" = "x" -o "x$1" = "x-f" -o "x$1" = "xforce" ]; then

		# tentar subir os modulos ate achar alguma
		logit "Detectando interfaces de rede"

		# Testar modulos mais comuns para ver se algum funciona
		netmods="
			3c59x acenic de4x5 dgrs
			eepro100 e1000 e1000e e100
			epic100 hp100 ne2k-pci
			olympic pcnet32 rcpci 8139too
			8139cp tulip via-rhine
			r8169 atl1e sktr yellowfin
			tg3 dl2k ns83820
		"
		
		for netmod in $netmods; do
			_modloaded "$netmod" && continue
			logit "Verificando modulo: $netmod"
			modprobe $netmod 2>/dev/null || continue
			ethers=$(lseth)
			if [ "x$ethers" = "x$tmpethers" ]; then
				# nao funicionou
				modprobe -r $netmod 2> /dev/null
			else
				# funcionou
				echo "OLD=$tmpethers NEW=$ethers"
				tmpethers="$ethers"
				echo "$netmod" >> /tmp/net-modules
				logit "--> Modulo encontrado: $netmod"
			fi
		done

		# Caso nenhuma interface seja detectada, tentar modulos incomuns
		if [ "x$ethers" = "x" ]; then
			logit "Verificando modulos antigos"
			netmods="
				depca ibmtr 3c501 3c503 3c505 3c507 3c509 3c515 ac3200
				acenic at1700 cosa cs89x0 de4x5 de600
				de620 e2100 eepro eexpress es3210 eth16i ewrk3 fmv18x forcedeth hostess_sv11
				hp-plus hp lne390 ne3210 ni5010 ni52 ni65 sb1000 sealevel smc-ultra
				sis900 smc-ultra32 smc9194 wd
			"
			rm -f /tmp/net-modules 2>/dev/null
			for netmod in $netmods; do
				_modloaded "$netmod" && continue
				logit "Verificando modulo: $netmod"
				modprobe $netmod 2>/dev/null || continue
				ethers=$(lseth)
				if [ "x$ethers" = "x$tmpethers" ]; then
					# nao funicionou
					modprobe -r $netmod 2> /dev/null
				else
					# funcionou
					echo "OLD=$tmpethers NEW=$ethers"
					tmpethers="$ethers"
					echo "$netmod" >> /tmp/net-modules
					logit "--> Modulo encontrado: $netmod"
				fi
			done
		fi

		# Resultado
		if [ -f /tmp/net-modules ]; then
			logit -n "Modulos detectados:"
			echoc -c green " $(cat /tmp/net-modules | wc -l)"
		else
			if [ "x$ethers" = "x" ]; then
				logity -n "ALERTA: NENHUM MODULO DETECTADO"
				echo_failure
			else
				logit2 "Interfaces de rede detectadas:" " $(lseth | wc -l)"
			fi
		fi

	fi
















