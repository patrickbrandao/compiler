#!/bin/sh

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

#
# Iniciar deteccao de internet automatica via DHCP-CLIENTE (IPv4 e IPv6), ND (IPv6)
#

#
# -> Executar silenciosamente
#

ETHS=$(lseth)

for eth in $ETHS; do

	logit "Ativando interface $eth"

	# ativar
	/sbin/ifconfig $eth up 2>/dev/null 1>/dev/null

	# Rodar dhcp
	clog="/var/log/dhcp-client-$eth.log"
	(/sbin/dhcpcd -t 35 -L $eth) 1>$clog 2>$clog &
done


