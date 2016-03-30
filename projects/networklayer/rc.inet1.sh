#!/bin/sh

export PATH="/usr/sbin:/sbin:/usr/bin:/bin"

#
# Script para configurar interfaces de rede e gateway padrao
#
# - ethernet
# - vlan
# - ipv4
# - ipv6
# - rotas
#

# ------------------------------------------------------------- CONSTANTES


	# banco de dados CSV de enderecos IP
	IPCONF=/etc/network/ip.conf


	# banco de dados CSV de vlans
	VLANCONFIG=/etc/network/vlans.conf


	# dhcp-client
	DHCPCCONF=/etc/network/dhcp-client.conf

# ------------------------------------------------------------- VARIAVEIS


	ACTION="$1"


# ------------------------------------------------------------- PROGRAMA

	# Funcao para ativar loopback
	_inet_loopback(){
		# Subir loopback
		logit -n "Ativando LOOPBACK "
		# UP loopback
		/sbin/ifconfig lo up 2>/dev/null
		echoc -c green -n "."
		# IPv4 loopback
		/sbin/ifconfig lo 127.0.0.1 netmask 255.0.0.0 2>/dev/null
		echoc -c green -n "."
		/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo 2>/dev/null \
			|| /usr/sbin/ip route add 127.0.0.0/8 dev lo 2>/dev/null
		echoc -c green -n "."
		# IPv6 loopback
		/usr/sbin/ip -6 addr add ::1/128 dev lo 2>/dev/null \
			|| /usr/sbin/ip -6 addr add ::1/128 dev lo 2>/dev/null
		echoc -c green -n "."
		echo_ok
	}

	# Ativar forward
	_inet_forward(){
		logit -n "Ativando roteamento IPv4/IPv6 "
		if [ -f /proc/sys/net/ipv4/ip_forward ]; then
			echoc -c green -n "."
			echo 1 > /proc/sys/net/ipv4/ip_forward
		fi
		if [ -f /proc/sys/net/ipv6/conf/all/forwarding ]; then
			echoc -c cyan -n "."
			echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
		fi
		echo_ok
	}

	# Funcao para parar a rede
	_inet_stop(){
		logit "Parando camada de rede"
		# destruir todos os tunneis
		# -> sem suporte a tuneis ainda
		# destruir vlans
		vlans="$(lsvlan) $(lsqinq)"
		if [ "x$vlans" != "x" ]; then
			logit -n "Removendo VLANs "
			for vlan in $vlans; do
				# baixar interface
				/usr/sbin/ip link set down dev "$vlan" 2>/dev/null
				# remover ips
				/usr/sbin/ip address flush dev "$vlan" 2>/dev/null
				# remover interface
				/usr/sbin/ip link delete dev "$vlan" 2>/dev/null
				echoc -c blue -n "."
			done
			echo_ok
		fi
		# limpar interfaces de rede
		ethers=$(lseth)
		if [ "x$ethers" != "x" ]; then
			logit -n "Desativando ethers "
			for eth in $ethers; do
				# baixar interface
				/usr/sbin/ip link set down dev "$eth" 2>/dev/null
				# remover ips
				/usr/sbin/ip address flush dev "$eth" 2>/dev/null
				echoc -c blue -n "."
			done
			echo_ok
		fi
	}

	# Iniciar rede
	_inet_start(){
		# Subir interfaces ethernet	
		ethers=$(lseth)
		for _eth in $ethers; do
			logit -n "[ethernet] "
			echoc -n -c green "$_eth"
			# UP
			ip link set up dev $_eth 2>/dev/null; ifconfig $_eth up 2>/dev/null
			echo_ok
		done
		# Tem vlans para subir?
		if [ -f "$VLANCONFIG" ]; then
			# carregar modulo de VLAN
			modprobe 8021q 2>/dev/null
		    # definindo formato
		    /sbin/vconfig set_name_type DEV_PLUS_VID_NO_PAD 2>/dev/null 1>/dev/null
			logit -n "[VLAN] "
			# montar lista nivelada
			for vlevel in 1 2; do
				# ler configuracao, coletar apenas nivel $vlevel
				VLANIDS=$(csv_listid $VLANCONFIG)
				# ler arquivo
				for dbvid in $VLANIDS; do
					vname=$(csv_getid_col $VLANCONFIG $dbvid 2)
					dev=$(csv_getid_col $VLANCONFIG $dbvid 3)
					vid=$(csv_getid_col $VLANCONFIG $dbvid 4)
					service=$(csv_getid_col $VLANCONFIG $dbvid 5)
					options=$(csv_getid_col $VLANCONFIG $dbvid 6)
					status=$(csv_getid_col $VLANCONFIG $dbvid 7)
					# nome no sistema
					vdev="$dev.$vid"; proto=802.1q
					if [ "$service" = "1" ]; then vdev="$dev.s$vid"; proto=802.1ad; fi
					# comandos para adicionar
					CMD="ip link add link $dev name $vdev type vlan proto $proto id $vid"
					# vlan desativada
					[ "$status" = "0" ] && continue
					# obter nivel pelo numero de pontos
					mylevel=$(countchar '.' $vdev)
					# nivel da vlan depende de outra vlan, pular
					[ "$mylevel" = "$vlevel" ] || continue
					# se a vlan ja existe, ignorar
					[ -d "/sys/class/net/$vdev" ] && continue
					# interface mestre existe no sysfs
					[ -d "/sys/class/net/$dev" ] || continue
					# criar VLAN
					# criar interface vlan (deixar ips v4 e v6 para o sync)
					xerr=$(eval "$CMD" 2>&1); nerr="$?"
					if [ "x$nerr" = "x0" ]; then
						# deu certo, subir interface
						(ifconfig $vdev up || ip link set up dev $vdev) 2>/dev/null
						echoc -c green -n "."
						continue
					else
						echoc -c red -n "x"
					fi
				done
			done
			echo_ok
		fi
		# Tem bridges?
		# -> sem suporte a bridge no momento
		# Tem ips nas interfaces?
		if [ -f "$IPCONF" ]; then
			# carregar modulo de IPv6
			modprobe ipv6 2>/dev/null
			# subir ips nas interfaces (ipv4 e ipv6)
			logit -n "[IP] "
			IPIDS=$(csv_listid $IPCONF 2>/dev/null)
			for IPID in $IPIDS; do
				dev=$(csv_getid_col $IPCONF $IPID 2)
				ipversion=$(csv_getid_col $IPCONF $IPID 3)
				ipaddr=$(csv_getid_col $IPCONF $IPID 4)
				netbits=$(csv_getid_col $IPCONF $IPID 5)
				status=$(csv_getid_col $IPCONF $IPID 7)
				# ignorar desativado
				[ "$status" = "1" ] || continue
				# ignorar versao desconhecida
				[ "$ipversion" = "4" -o "$ipversion" = "6" ] || continue
				# ip ou bits nao informados			
				[ "x$ipaddr" = "x" -o "x$netbits" = "x" ] && continue
				# interface nao existe no sysfs
				[ -d "/sys/class/net/$dev" ] || continue
				# Adicionar ip na interface
				/usr/sbin/ip -$ipversion addr add "$ipaddr/$netbits" dev "$dev" 2>/dev/null
				if [ "$?" = "0" ]; then
					# tudo certo
					if [ "$ipversion" = "4" ]; then echoc -n -c green "."; else echoc -n -c cyan "."; fi
				else
					# bugou
					echoc -n -c blue "."
				fi
			done
			echo_ok
		else
			# configurar ip padrao: 192.168.N.2/24
			logit "[IP] Sem configuracao, usando IPs padrao"
			for eth in $ethers; do
				ip="192.168.255.2/24"
				[ "$eth" = "eth0" ] && ip="192.168.0.2/24"
				[ "$eth" = "eth1" ] && ip="192.168.1.2/24"
				[ "$eth" = "eth2" ] && ip="192.168.2.2/24"
				[ "$eth" = "eth3" ] && ip="192.168.3.2/24"
				[ "$eth" = "eth4" ] && ip="192.168.4.2/24"
				[ "$eth" = "eth5" ] && ip="192.168.5.2/24"
				[ "$eth" = "eth6" ] && ip="192.168.6.2/24"
				[ "$eth" = "eth7" ] && ip="192.168.7.2/24"
				logit "[IP] Padrao na $eth -> $ip"
				/usr/sbin/ip -4 addr add "$ip" brd + dev $eth 2>/dev/null
			done
		fi

		# Tem cliente dhcp?
		if [ -f "$DHCPCCONF" ]; then
			# subir ips nas interfaces (ipv4 e ipv6)
			logit -n "[DHCP-Client] "
			DHCPCIDS=$(csv_listid $IPCONF 2>/dev/null)
			for DCID in $DHCPCIDS; do
				dev=$(csv_getid_col $IPCONF $IPID 2)
				ipversion=$(csv_getid_col $IPCONF $IPID 3)
				ipaddr=$(csv_getid_col $IPCONF $IPID 4)
				netbits=$(csv_getid_col $IPCONF $IPID 5)
				status=$(csv_getid_col $IPCONF $IPID 7)
				# ignorar desativado
				[ "$status" = "1" ] || continue
				# ignorar versao desconhecida
				[ "$ipversion" = "4" -o "$ipversion" = "6" ] || continue
				# ip ou bits nao informados			
				[ "x$ipaddr" = "x" -o "x$netbits" = "x" ] && continue
				# interface nao existe no sysfs
				[ -d "/sys/class/net/$dev" ] || continue
				# Adicionar ip na interface
				/usr/sbin/ip -$ipversion addr add "$ipaddr/$netbits" dev "$dev" 2>/dev/null
				if [ "$?" = "0" ]; then
					# tudo certo
					if [ "$ipversion" = "4" ]; then echoc -n -c green "."; else echoc -n -c cyan "."; fi
				else
					# bugou
					echoc -n -c blue "."
				fi
			done
			echo_ok
		fi
	}

	case "$1" in
		'start')
			# Iniciar rede
			_inet_loopback
			_inet_start
			_inet_forward
			;;

		'stop')
			_inet_stop
			;;

		'restart')
			samba_restart
			;;

		*)
			# Iniciar rede
			_inet_loopback
			_inet_start
			_inet_forward

	esac






















