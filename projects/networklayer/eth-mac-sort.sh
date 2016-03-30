#!/bin/sh

#
#       Ordenar nome das interfaces pelo MAC
#       Autor: Patrick Brandao <patrickbrandao@gmail.com>
#
#       Garantir nome das interfaces pela ordem alfabetica de seus macs
#       de maneira que nunca mudem (problema constante do udev).
#       Nao podemos usar nenhum arquivo temporario pois o sistema
#       de arquivos pode estar como somente leitura, e precisaremos da rede
#       para possiveis reparos e execucoes de softwares
#
#

	export PATH="/usr/sbin:/sbin:/usr/bin:/bin"


#---------------------------------------------------------------------------- CONSTANTES

	NETCONFDIR="/etc/network"
	DEBUGFILE="/var/log/eth-mac-sort-debug.log"
	LOGFILE="/var/log/eth-mac-sort.log"

#---------------------------------------------------------------------------- VARIAVEIS

	# Listas

	# - interfaces ethX
	ETHS=""

	# - lista de par mac=eth
	# -- lista inicial
	OLIST=""
	# -- lista final
	LIST=""

	# - lista de macs encontrados
	MACS=""

	# - lista de macs encontrados ordenados
	SMACS=""

	# numero de ethernets encontradas
	ETHCOUNT=0

	# numero a ser usado na ultima ethernet (novo nome)
	ETHENDIDX=0

#---------------------------------------------------------------------------- FUNCOES

	# limpar e sair
	_quit(){
		rm $TMPDIR -rf 2>/dev/null
		exit $1
	}
	# parar com erro fatal
	_abort(){
		logit2 "eth-mac-sort" "Abortado, $@"
		exit 2
	}

	# Renomear interface
	_rename_eth(){
		_re_act="$1"
		_re_new="$2"
		# desativar
		/sbin/ip link set down dev "$_re_act" 2>/dev/null
		/sbin/ifconfig "$_re_act" down 2>/dev/null
		# renomear
		/sbin/ip link set down dev "$_re_act" name "$_re_new" 2>/dev/null
		/sbin/ip link set down dev "$_re_act" name "$_re_new" 2>/dev/null
		# subir novamente o novo nome
		/sbin/ip link set up dev "$_re_new" 2>/dev/null
		/sbin/ifconfig "$_re_new" up 2>/dev/null
		# subir novamente o nome antigo, vai dar erro, mas por seguranca
		/sbin/ip link set up dev "$_re_act" 2>/dev/null
		/sbin/ifconfig "$_re_act" up 2>/dev/null		
	}
	# verificar se o nome da interface esta em uso
	_eth_exist(){
		_ee_find_eth="$1"
		_ee_ret=0
		for _ee_xitem in $LIST; do
			_ee_xeth=$(strcut -s "$_ee_xitem" -n2 -c=)
			if [ "$_ee_xeth" = "$_ee_find_eth" ]; then echo "1"; return; fi
		done
		echo "0"
	}
	# Atualizar lista trocando o nome de uma eth
	_update_list_replace(){
		_ulr_act="$1"
		_ulr_new="$2"
		_ulr_list=""
		for _ulr_xitem in $LIST; do
			_ulr_xmac=$(strcut -s "$_ulr_xitem" -n1 -c=)
			_ulr_xeth=$(strcut -s "$_ulr_xitem" -n2 -c=)
			if [ "$_ulr_xeth" = "$_ulr_act" ]; then _ulr_xeth="$_ulr_new"; fi
			_ulr_list="$_ulr_list $_ulr_xmac=$_ulr_xeth"
		done
		# atualizar lista global
		LIST="$_ulr_list"
	}

	# pasta temporaria
	#rm -rf $TMPDIR 2>/dev/null
	#mkdir -p $TMPDIR

	# esvaziar arquivos temporarios
	[ -d "$NETCONFDIR" ] || mkdir -p "$NETCONFDIR" || _abort "Falha ao acessar diretorio $NETCONFDIR"

# *********************************** Tentar obter mac sincrono ou padrao ****************************************

	logit3 "eth-mac-sort" "Ordenando interfaces ethernet, atuais:"

	# Coletar lista de macs e interfaces
	ETHS=$(lseth)

	# nada a fazer se nao tem interfaces
	if [ "x$ETHS" = "x" ]; then
		logit2 "eth-mac-sort" "Nenhuma interface de rede encontrado"
		exit
	fi

	for _eth in $ETHS; do
		_mac=$(getethmac $_eth)

		logit3 "eth-mac-sort" "$_eth" "$_mac"
		LIST="$LIST $_mac=$_eth"
		MACS="$MACS $_mac"
		ETHCOUNT=$(($ETHCOUNT+1))
	done

	# id de novo nome a ser usado
	ETHENDIDX=$(($ETHCOUNT+1))

	# salvar lista original
	OLIST="$LIST"

	# ordenar macs
	SMACS=$(echo $(for x in $MACS; do echo $x; done | sort))


	#-logitp "MACS.....: $MACS"
	#-logitp "LIST.....: $LIST"
	#-logitp "SMACS....: $SMACS"


	# analisar macs ordenados e ver quais interfaces
	ethid=0
	for _mac in $SMACS; do

		# nome esperado
		seth="eth$ethid"

		logit3 -n "eth-mac-sort" "Definindo:" "$seth "

		# descobrir nome do mac atual
		f=0
		for xitem in $LIST; do

			# mac da interface
			xmac=$(strcut -s "$xitem" -n1 -c=)

			# nome atual da interface
			xeth=$(strcut -s "$xitem" -n2 -c=)

			#-logit "---------- xmac=$xmac xeth=$xeth"

			# Mac encontrado
			if [ "$xmac" = "$_mac" ]; then
				f=1
				#- logitp "-------------- mac found $xmac => $xeth"

				# se o nome atual nao for o nome esperado, precisamos renomear
				if [ "$xeth" = "$seth" ]; then
					# tudo certo, o nome ja esta correto, nao precisar renomear
					echoc -n -c gray "Right: "
					echoc -c green -l "$seth = $xmac"

					f=2
				else
					# esta diferente, precisamos renomear
					#- logitr "-------------------- mac found $xmac => $xeth, renomear $xeth para $seth"

					# PROBLEMA: imagine que a eth0 esteja em uso mas o mac em questao seja
					#           o que deve ser renomeado para eth0. Precisamos entao mudar
					#           o nome da eth0 para ethX, onde X e' um numero maior que o numero
					#           de interfaces, e atualizar a variavel $LIST
					ethexist=$(_eth_exist "$seth")
					if [ "$ethexist" = "1" ]; then
						# ja existe, teremos que renomea-la para um novo nome
						# e atualizar a lista antes de renomear o
						# nome atual para seu nome de direito

						# obter um nome livre
						xneweth="eth$ETHENDIDX"
						#-logity "--------------------------- nome $seth em uso, muda-lo para $xneweth"

						echoc -n -c yellow "Busy/Move: "
						echoc -n -c gray "$seth > $xneweth, $xeth > "
						echoc -c green -l "$seth = $xmac"

						# atualizar lista
						_update_list_replace "$seth" "$xneweth"

						# renomear do atual para o novo para liberar o nome
						_rename_eth "$seth" "$xneweth"

						# renomear interface atual para seu nome de direito
						# - atualizar lista
						_update_list_replace "$xeth" "$seth"
						# - renomear
						_rename_eth "$xeth" "$seth"

						# aumentar o numero de indice para novas interfaces
						ETHENDIDX=$(($ETHENDIDX+1))

					else

						# Nome disponivel, renomear interface para o novo nome
						#- echo "SIMPLES, renomear '$xeth' para '$seth'"

						#logit3 "eth-mac-sort" "Ocupado, realocando:" "$xeth/$xmac -> $seth" 
						echoc -n -c yellow "Free/Rename: "
						echoc -n -c gray "$xeth > "
						echoc -c green -l "$seth = $xmac" 

						#echoc -n -c yellow "Free/Rename: "
						#echoc -c green "$xeth/$xmac -> $seth" 

						# - atualizar lista
						_update_list_replace "$xeth" "$seth"
						# - renomear
						_rename_eth "$xeth" "$seth"

					fi

				fi
				# mac encontrado, nao precisa verificar outros itens
				# bug possivel: se houver duas interfaces com o mesmo MAC,
				#               mas isso nao e' um problema nosso.
				#               Nao resolver via softawre problemas de hardware
				break

			fi # if xmac = _mac

		done


		#-logitb "Next..."

		# proximo...
		ethid=$(($ethid+1))

	done

	#-logita "lista final: $LIST"

	# Logar ambiente inicial e final
	(
		echo -n "$(date '+%y-%m-%d %T') | "
		echo -n $OLIST
		echo -n " | "
		echo $LIST
	) >> $LOGFILE

	# Salvar variaveis para debug
	#-(
	#-	echo -n "# "; date
	#-	echo "[ETHS]"; echo "$ETHS"; echo
	#-	echo "[NETCONFDIR]"; echo "$NETCONFDIR"; echo
	#-	echo "[OLIST]"; echo "$OLIST"; echo
	#-	echo "[LIST]"; echo "$LIST"; echo
	#-	echo "[MACS]"; echo "$MACS"; echo
	#-	echo "[SMACS]"; echo "$SMACS"; echo
	#-	echo "[ETHCOUNT]"; echo "$ETHCOUNT"; echo
	#-	echo "[ETHENDIDX]"; echo "$ETHENDIDX"; echo
	#-	echo "[env]"; env; echo
	#-) > $DEBUGFILE









