#!/bin/sh

. /etc/setup/vars.sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"


	dialog --title "$DISTRO_TITLE" --infobox "\nProcurando disco de instalacao...\n" 7 40


# Encontrar dispositivo DVD/CD com os pacotes
#------------------------------------------------------------------------------

	tmp=$(head -1 /tmp/isodev 2>/dev/null)
	iDEVS="
		$tmp
		/dev/sr0 /dev/sr1 /dev/sr2 /dev/sr3
		/dev/hdb /dev/hda /dev/hdc /dev/hdd /dev/hde /dev/hdf /dev/hdg /dev/hdh
		/dev/hdm /dev/hdn /dev/hdo /dev/hdp
		/dev/pcd0 /dev/pcd1 /dev/pcd2 /dev/pcd3
		/dev/aztcd
		/dev/cdu535
		/dev/gscd
		/dev/sonycd
		/dev/optcd
		/dev/sjcd
		/dev/mcdx0
		/dev/mcdx1
		/dev/sbpcd
		/dev/cm205cd /dev/cm206cd
		/dev/mcd
		/dev/bpcd
	"

	# ponto de montagem do iso
	ISOMOUNT="/mnt/iso-mount"
	echo "$ISOMOUNT" > /tmp/pdn-mount

	# Procurar um a um
	DRIVE_FOUND=""
	SRCDIR=""
	mkdir -p $ISOMOUNT
	umount -f $ISOMOUNT 2>/dev/null
	for xdev in $iDEVS; do
		umount -f "$ISOMOUNT" 2>/dev/null
		mount -o ro -t iso9660 $xdev "$ISOMOUNT" 1>/dev/null 1>/dev/null; mret="$?"
		# montou?
		if [ "$mret" = "0" ]; then
			# montou, verificar se e' o DVD/CD de instalacao
			if [ -f "$ISOMOUNT/packages/index.md5" ]; then
				# Encontrou
				DRIVE_FOUND="$xdev"
				SRCDIR="$ISOMOUNT/packages"

				echo "$xdev" > /tmp/isodev
				echo "$SRCDIR" > /tmp/srcdir
				break
			fi
			# errado, desmontar
		fi		
	done

	# Nao encontrou nada?
	if [ "$DRIVE_FOUND" = "x" ]; then
		dialog --title "$DISTRO_TITLE" \
			--msgbox "Erro na instalacao.\n\nO CD/DVD de instalacao nao foi localizado no sistema.\n\nImpossivel continuar." \
			14 50
		exit 19
	fi
	dialog --title "$DISTRO_TITLE" --infobox "\nDisco encontrado em $DRIVE_FOUND\n" 7 40


# Analisar sanidade dos pacotes
#------------------------------------------------------------------------------
	cd $SRCDIR || exit 18

	# obter lista de pacotes
	pkgcount=0
	pkglist=""
	for pkg in none *.txz; do
		[ "$pkg" = "none" ] && continue
		pkglist="$pkglist $pkg"
		pkgcount=$(($pkgcount+1))
	done 2>/dev/null
	# nenhum pacote encontrado
	if [ "$pkgcount" = "0" ]; then
		dialog --title "$DISTRO_TITLE" --msgbox "Erro na instalacao.\n\nNenhum pacote foi encontrado no CD/DVD\n\n" 8 50
		exit 17
	fi

	# analise de sanidade
	# Apagar o disco com ZERO-FILL
	TMPTEXT="\nAnalisando integridade dos pacotes\n"
	dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 20 60
	allcheck=1
	for pkg in $pkglist; do
		# md5 real
		realmd5=$(getmd5sum "$pkg")

		# md5 catalogado
		idxmd5=$(cat index.md5 | grep "$pkg" | awk '{print $1}')

		if [ "$realmd5" = "$idxmd5" ]; then
			TMPTEXT="$TMPTEXT\n  $pkg - OK"
		else
			TMPTEXT="$TMPTEXT\n  $pkg - CORROMPIDO"
			allcheck=0
		fi
		dialog --title "$DISTRO_TITLE" --infobox "$TMPTEXT" 20 60
	done
	if [ "$allcheck" = "0" ]; then exit 16; fi

	# Catalogar pacotes a serem instalados
	echo "$pkglist" > /tmp/pkglist

	sync
	sleep 1














