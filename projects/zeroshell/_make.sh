#!/bin/sh

. /compiler/conf.sh

# limpar arquivos de log
echo -n > /var/log/ngsh-debug.log
echo -n > /var/log/ngsh.log

TMPDST="$1"
if [ "x$TMPDST" = "x" ]; then TMPDST="/tmp/zeroshell"; fi

WORKDIR=/compiler/output/zeroshell
SRCDIR=/compiler/projects/zeroshell

	# Limpar diretorio de resultado
		clsdir "$TMPDST"

	# Limpar diretorio de compilacao dos fontes
		clsdir "$WORKDIR"

	# Copiar fontes
		cdfolder "$SRCDIR"
		cp * "$WORKDIR/" || abort "Erro ao copiar fontes para '$WORKDIR'"

# Compilar
	cdfolder "$WORKDIR"
	make $NUMJOBS

# Instalar no diretorio do pacote
	mkdir -p "$TMPDST/bin"
	cp vtysh "$TMPDST/bin/zeroshell"

