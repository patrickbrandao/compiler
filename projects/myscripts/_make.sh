#!/bin/sh


# Copiar scripts para o sistema
. /compiler/conf.sh


# Pasta destino
	TMPDST="$1"
	if [ "x$TMPDST" = "x" ]; then TMPDST="/tmp/pkg-myscripts"; fi

# Pasta de fontes
	HERE="/compiler/projects/myscripts"

# Preparar
	clsdir "$TMPDST"
	mkdir -p "$TMPDST/bin"
	mkdir -p "$TMPDST/sbin"
	mkdir -p "$TMPDST/usr/bin"
	mkdir -p "$TMPDST/usr/sbin"

# Instalar/copiar
	_install(){
		_file="$1"
		_dst="$2"
		cd "$HERE" || abort "Erro ao entrar em '$HERE'"

		logit2 "Copiando '$_file' para '$_dst'"
		rm "$_dst" 2>/dev/null
		cp "$_file" "$_dst" || abort "Erro ao copiar '$_file' para '$_dst'"

		rm "$TMPDST$_dst" 2>/dev/null
		cp "$_file" "$TMPDST$_dst" || abort "Erro ao copiar '$_file' para '$TMPDST$_dst'"
		chmod +x "$_dst" "$TMPDST$_dst"

	}

	_install depcheck.sh		/bin/depcheck
	_install lsfiles.sh			/bin/lsfiles

	_install dezip.sh			/usr/bin/dezip

	_install getmd5sum.sh		/usr/bin/getmd5sum
	_install strmd5.sh			/usr/bin/strmd5
	_install getsha256sum.sh	/usr/bin/getsha256sum

	_install duptester.sh		/usr/bin/duptester

	_install portclose.sh		/usr/sbin/portclose

	_install http-sync.sh		/usr/bin/http-sync

	_install ziplist.sh			/usr/bin/ziplist


