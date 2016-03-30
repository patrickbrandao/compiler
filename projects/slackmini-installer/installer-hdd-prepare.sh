#!/bin/sh

# Script de particionamento e formatacao
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#

. /etc/setup/vars.sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

# Tamanho minimo exigido do disco
	# 4 gigas
	HDD_MIN_SIZE=4294967296


# Funcoes
	# Obter numero de bytes do dispositivo
	get_dev_size_bytes(){ blockdev --getsize64 "$1"; }
	# Obter tamanho em formato tecnico - siglas em K, M, G, T, or P
	get_size_human() { numfmt --to=iec "$1"; }

	# Formatar particao
	make_ext2() { mkfs.ext2 -F -F $1 1>/dev/null 2>/dev/null; }
	make_ext3() { mkfs.ext3 -F -F $1 1>/dev/null 2>/dev/null; }
	make_ext4() { mkfs.ext4 -F -F $1 1>/dev/null 2>/dev/null; }
	make_reiserfs() { echo "y" | mkreiserfs $1 1>/dev/null 2>/dev/null; }
	make_swap() { mkswap -v1 $1 1>/dev/null 2>/dev/null; }

# Metodo de instalacao, format ou repair
# no metodo repair a particao com o sistema e com o boot sao montadas para
# reinstalar os pacotes do sistema
	MODE="$1"; if [ "x$MODE" = "x" ]; then MODE="repair"; else MODE="format"; fi

# Listar discos
	dialog --title "$DISTRO_TITLE" --infobox "Procurando discos...\n\n  * IDE\n  * SATA\n  * SAS\n  * SCSI\n  * FLASH" 10 30
	sleep 1

	# obter discos (APENAS ITENS COM 1 ou mais GIGABYTES)
	fdisk -l | egrep '^Disk /dev' | grep -v ' MiB' | cut -f1 -d: | awk '{print $2}' > /tmp/discs-devs
	dcount=$(cat /tmp/discs-devs | wc -l)
	if [ "$dcount" -lt "1" ]; then
		# Nenhum disco encontrado
		dialog --title "$DISTRO_TITLE" \
			--msgbox "Erro na instalacao.\n\nNenhum HD ou unidade de armazenamento foi encontrada.\n\nImpossivel continuar." \
			10 50
		exit 11
	fi


# Escolher o disco de instalacao
	# Menu principal
	HDDLIST=$(cat /tmp/discs-devs)
	HDDSELECTED=""
	while [ 0 ]; do
		_delfile "/tmp/menu-hdd-choice"

		# montar dialog
		dscript=/tmp/dialog-hdd.sh
		echo -n "dialog --title '$DISTRO_TITLE' --menu " > $dscript
		echo -n '"Bem-vindo ao Slackmini.\nEscolha uma opcao e tecle ENTER.\n" 10 56 9 ' >> $dscript
		for hddopt in $HDDLIST; do
			# tamanho do disco
			_bytes=$(get_dev_size_bytes "$hddopt")
			_hsize=$(get_size_human "$_bytes")
			echo -n " '$hddopt' 'Tamanho: $_hsize ($_bytes bytes)'" >> $dscript
		done
		# opcao de cancelar
		echo -n ' "CANCELAR" "Cancelar instalacao"' >> $dscript

		# resultado
		echo -n ' 2> /tmp/menu-hdd-choice; exit $?' >> $dscript

		# executar
		sh $dscript; RET="$?"

		# erro no software
		if [ ! $RET = 0 ]; then echo "Falha no menu. Tente novamente"; sleep 1; continue; fi
		HDDSELECTED=$(cat /tmp/menu-hdd-choice)

		# verificar se opcao escolhida esta na lista
		hddfound=0
		for hddopt in $HDDLIST; do if [ "$hddopt" = "$HDDSELECTED" ]; then found=1; break; fi; done

		# Usuario cancelou
		if [ "$HDDSELECTED" = "CANCELAR" ]; then exit 9; fi

		# Opcao nao encontrada, MUITO ESQUISITO
		if [ "$found" = "0" ]; then
			echo
			echo " ERRO"
			echo
			echo " A escolha nao constava na lista de opcoes. Erro imprevisto."
			echo " Tire uma foto dessa tela e envie ao SUPORTE."
			echo " Escolha: [$HDDSELECTED]"
			echo " Opcoes: [$HDDLIST]"
			echo
			echo " Tecle ENTER para finalizar."
			echo
			read pause
			exit 8
		else
			break
		fi

	done
	# fim menu principal

	# Instalar no dispositivo $HDDSELECTED
	echo "$HDDSELECTED" > /tmp/idev
	# tamanho do disco
	HDD_BYTES=$(get_dev_size_bytes "$HDDSELECTED")
	HDD_SEQSIZE=16000000
	HDD_SEQCOUNT=$(($HDD_BYTES/$HDD_SEQSIZE))
	HDD_HSIZE=$(get_size_human "$HDD_BYTES")


	# O disco nao pode ter menos de 8 gigas
	if [ "$HDD_BYTES" -lt "$HDD_MIN_SIZE" ]; then
		HDD_MIN_HSIZE=$(get_size_human "$HDD_MIN_SIZE")
		# Disco pequeno
		dialog --title "$DISTRO_TITLE" \
			--msgbox "Erro na instalacao.\n\nO disco:\n - $HDDSELECTED\n - Tamanho: $HDD_HSIZE\n\nNao tem o tamanho necessario (minimo $HDD_MIN_HSIZE).\n\nImpossivel continuar." \
			14 50
		exit 20
	fi


	# Perguntar se o usuario deseja mesmo mexer no disco
	if [ "$MODE" = "format" ]; then
		# FORMATAR
		dialog --title "$DISTRO_TITLE" \
			--yesno \
			"Unidade escolhida: $HDDSELECTED - $HDD_HSIZE\n\nTem certeza que deseja apagar todos os dados da unidade $HDDSELECTED?\n\nSe escolher SIM, todos os dados serao permanentemente apagados." 12 50
		RET="$?"
		[ "$RET" = "0" ] || exit 7

	else
		# REPARAR
		echo "FALTA FAZER A PARTE DO REPARAR"
		exit 21
	fi


# Usuario escolheu formatar.
#----------------------------------------------------------------------------------------------

	# Apagar o disco com ZERO-FILL
	TMPTEXT="Apagando dados em $HDDSELECTED\n"

	# - desmontar particoes por seguranca
	TMPTEXT="$TMPTEXT\n * Verificando"
	dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50
	for pdev in ${HDDSELECTED}1 ${HDDSELECTED}2 ${HDDSELECTED}3 ${HDDSELECTED}4; do
		umount -f "$pdev" 2>/dev/null 1>/dev/null
	done

	# - apagar MBR
	TMPTEXT="$TMPTEXT\n * Apagando MBR"
	dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50
	dd if=/dev/zero of=$HDDSELECTED count=1 bs=512 2>/dev/null 1>/dev/null

	# - zeroFILL
	TMPTEXT="$TMPTEXT\n * Apagando conteudo (zero-fill)"
	dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50

	# 512k
	dd if=/dev/zero of=$HDDSELECTED count=1 bs=512000 2>/dev/null 1>/dev/null

	# 16 megas
	dd if=/dev/zero of=$HDDSELECTED count=1 bs=$HDD_SEQSIZE 2>/dev/null 1>/dev/null

	# apenas 2 gigas iniciais
	ct=$HDD_SEQCOUNT
	if [ "$ct" -ge 64 ]; then ct=64; fi
	dd if=/dev/zero of=$HDDSELECTED count=$ct bs=$HDD_SEQSIZE 2>/dev/null 1>/dev/null


	# Avaliar tamanho do disco para decidir se vai existir a particao storage
	PINFO="boot+swap+root"
	pfile=/tmp/hdd-mbr-tables
	ptype=gpt
	pcount=3
	echo -n > $pfile

	# MBR vai apenas ate 2 TERAS (2.199.023.255.552)
	if [ "$HDD_BYTES" -lt "2199023255552" ]; then ptype=dos; fi

	# escolher modelo de particionamento de acordo com o tamanho
	# menos de  64 gigas : BOOT + SWAP + ROOT
	# maior que 64 gigas : BOOT + SWAP + ROOT + STORAGE

	# BOOT e SWAP
	echo ',150M,L' >> $pfile
	echo ',512M,S' >> $pfile

	# menos que 64 gigas (68719476736 = 68.719.476.736)
	if [ "$HDD_BYTES" -lt "68719476736" ]; then
		# menor que 64 gigas
		# sem storage
		# usar o resto para o ROOT
		echo ',,L' >> $pfile
		PINFO="boot+swap+root"
	else
		# maior que 64 gigas
		# com storage
		# usar o ROOT com 32 gigas
		echo ',32G,L' >> $pfile

		# usar o resto no STORAGE
		echo ',,L' >> $pfile
		PINFO="boot+swap+root+storage"
		pcount=4
	fi

	# Aplicar particionamento
	TMPTEXT="$TMPTEXT\n * Particionando ($PINFO)"
	dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50
	sfdisk --no-reread -q $HDDSELECTED < $pfile 2>/dev/null 1>/dev/null; pret="$?"

	# Ativar /boot como botavel
	TMPTEXT="$TMPTEXT\n * Ativando BOOT"
	dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50
	sfdisk --no-reread -q -A $HDDSELECTED 1 2>/dev/null 1>/dev/null




# FORMATAR PARCICOES
#----------------------------------------------------------------------------------------------

	ptable=/tmp/partitions
	echo -n > $ptable

	# SWAP (segunda particao)
		swapdev="${HDDSELECTED}2"
		TMPTEXT="$TMPTEXT\n * Formatando SWAP ($swapdev)"
		dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50

			# formatar
			make_swap "$swapdev"

			# registrar
			echo "$swapdev" > /tmp/swap-dev
			echo "2:swap:$swapdev:swap:swap" >> $ptable


	# ROOT (/)
		rootdev="${HDDSELECTED}3"
		rootdir="/mnt/install_root"
		rootpoint="/"
		TMPTEXT="$TMPTEXT\n * Formatando / ($rootdev)"
		dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50

			# formatar
			make_ext4 "$rootdev"

			# registrar
			echo "$rootdev" > /tmp/root-dev
			echo "$rootdir" > /tmp/root-dir
			echo "3:ext4:$rootdev:$rootpoint:$rootdir" >> $ptable

			# montar
			mkdir -p "$rootdir"
			mount "$rootdev" -t "ext4" "$rootdir"; mret="$?"
			if [ "$mret" != "0" ]; then
				dialog \
					--title "$DISTRO_TITLE" \
					--msgbox "Erro na instalacao.\n\nErro $mret ao montar '$rootdev' em '$rootdir' [ext4]\n\nImpossivel continuar." \
					14 50
				exit 41
			fi


	# BOOT (/boot)
		bootdev="${HDDSELECTED}1"
		bootdir="/mnt/install_root/boot"
		bootpoint="/boot"
		TMPTEXT="$TMPTEXT\n * Formatando /boot ($bootdev)"
		dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50

			# formatar
			make_ext2 "$bootdev"

			# registrar
			echo "$bootdev" > /tmp/boot-dev
			echo "$bootdir" > /tmp/boot-dir
			echo "1:ext2:$bootdev:$bootpoint:$bootdir" >> $ptable

			# montar
			mkdir -p "$bootdir"
			mount "$bootdev" -t "ext2" "$bootdir"; mret="$?"
			if [ "$mret" != "0" ]; then
				dialog \
					--title "$DISTRO_TITLE" \
					--msgbox "Erro na instalacao.\n\nErro $mret ao montar '$bootdev' em '$bootdir' [ext2]\n\nImpossivel continuar." \
					14 50
				exit 42
			fi


	# STORAGE (/storage)
	if [ "x$pcount" = "x4" ]; then

		storedev="${HDDSELECTED}4"
		storedir="/mnt/install_root/storage"
		storepoint="/storage"
		TMPTEXT="$TMPTEXT\n * Formatando /storage ($storedev)"
		dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 14 50

			# formatar
			make_ext4 "$storedev"

			# registrar
			echo "$storedev" > /tmp/store-dev
			echo "$storedir" > /tmp/store-dir
			echo "4:ext4:$storedev:$storepoint:$storedir" >> $ptable

			# montar
			mkdir -p "$storedir"
			mount "$storedev" -t "ext4" "$storedir"; mret="$?"
			if [ "$mret" != "0" ]; then
				dialog \
					--title "$DISTRO_TITLE" \
					--msgbox "Erro na instalacao.\n\nErro $mret ao montar '$storedev' em '$storedir' [ext4]\n\nImpossivel continuar." \
					14 50
				exit 43
			fi


	fi

	sleep 1

#----------------------------------------------------------------------------------------------














































 