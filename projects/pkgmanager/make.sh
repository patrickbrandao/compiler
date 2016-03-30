#!/bin/sh

# Instalar scripts do gerenciador de pacotes no sistema
TMPDST="$1"

. /compiler/conf.sh

[ "x$TMPDST" = "x" ] && abort "Informe a pasta destino do pacote"

cdfolder "/compiler/projects/pkgmanager"

list="
	ixpkg
	fxpkg
	rxpkg
	uxpkg
	expkg
"
for it in $list; do
	logit2 "Instalando $it" "($TMPDST) > /usr/sbin/$it"
	cp $it.sh $TMPDST/usr/sbin/$it || abort "Erro ao copiar $it.sh para $TMPDST/usr/sbin/$it"
	chmod 700 $TMPDST/usr/sbin/$it || abort "Erro ao aplicar chmod 700 em $TMPDST/usr/sbin/$it"
done



