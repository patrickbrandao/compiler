#!/bin/sh


# Copiar scripts para o sistema
. /compiler/conf.sh


# Pasta destino
	TMPDST="$1"
	if [ "x$TMPDST" = "x" ]; then TMPDST="/tmp/pkg-pkgmanager"; fi

# Pasta de fontes
	HERE="/compiler/projects/pkgmanager"

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
		cp "$_file" "$_dst" #|| abort "Erro ao copiar '$_file' para '$_dst'"
		cp "$_file" "$TMPDST$_dst" #|| abort "Erro ao copiar '$_file' para '$TMPDST$_dst'"
		chmod +x "$_dst" "$TMPDST$_dst"
	}

	_install fxpkg.sh			/usr/sbin/fxpkg
	_install rxpkg.sh			/usr/sbin/rxpkg
	_install ixpkg.sh			/usr/sbin/ixpkg
	#_install expkg.sh			/usr/sbin/expkg

