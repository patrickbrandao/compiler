#!/bin/sh

#
#
#
# SANATIZE instala todos os pacotes em uma pasta temporaria e testa os arquivos, dependencias - SANIDADE DO SISTEMA A SER INSTALADO
#
#
#
#


. /compiler/conf.sh

TMPDST="/tmp/slackbuild-sanatize"

#----------------------------------------------------------------------------------------

	MYNAME="Sanatizer"

	PACKAGES="
		baseapps
		baseconf
		basedb
		basefront
		baselibs
		baselinux
		basenet
		basenetapps
		baseshell
		basetools
		baseutils
		basevolatile
		basexlibs
		kernel

	"

	# evitar re-trabalho
	#[ -f "$TMPDST/.done" ] && okquit "Pacote ja esta pronto, remova o diretorio '$TMPDST' para refazer"


#------------------------------------------------------------------------------------- 

	logitr "Pasta destino: $TMPDST"

	# Pacotes existem?
	logit "$MYNAME :: Verificando pacotes"
	for pkg in $PACKAGES; do
		pkgfqdn="$SYSBASE/$pkg-$DISTRO_VERSION.txz"
		pkgidx="$SLACKBUILDDIR/$pkg/packages.dat"

		logitg "Pacote $pkg"
		# pacote precisa existir
		[ -f "$pkgfqdn" ] || abort "$MYNAME :: Pacote nao encontrado '$pkgfqdn'"

		# verificar quais scripts nao estao inclusos na lista de pacotes
		allpkglist=$(ls -1 $pkg/pkg* | cut -f2 -d'/' | cut -f2,3,4 -d'-' | cut -f1 -d'.')
		pkglist=$(cat "$pkgidx" | egrep -v '^[^a-z0-9]?[#;]')
		for xpkg in $allpkglist; do
			f=0
			for rpkg in $pkglist; do if [ "$xpkg" = "$rpkg" ]; then f=1; fi; done
			if [ "$f" = "0" ]; then
				logity "Sub-Pacote nao foi utilizado: $xpkg"
			fi
		done
	done

	# Preparar
	clsdir "$TMPDST"

	# Descompactar pacotes
	logit "$MYNAME :: Abrindo pacotes"
	for pkg in $PACKAGES; do
		pkgfqdn="$SYSBASE/$pkg-$DISTRO_VERSION.txz"

		_dezip "$pkgfqdn" "$TMPDST"
	done

	# analise de dependencias
	# -p: pastas com binarios
	# -l: pasta de bibliotecas
	# -r: pasta raiz
	# -o: arquivo com bibliotecas encontradas
	# -x: arquivo com bibliotecas nao encontradas
	# -u: arquivo com bibliotecas nao utilizadas
	/compiler/projects/myscripts/depcheck.sh \
		-r "$TMPDST" \
		\
			-p "$PATH" \
			-p "/bin" \
			-p "/sbin" \
			-p "/usr/bin" \
			-p "/usr/bin" \
			-p "/usr/local/bin" \
			-p "/usr/local/sbin" \
			-p "/admin/system/bin" \
			-p "/admin/system/sbin" \
			-p "/usr/libexec" \
			-p "/usr/libexec/awk" \
			-p "/usr/libexec/coreutils" \
			-p "/usr/libexec/mc" \
			-p "/usr/libexec/sudo" \
			-p "/bin" \
		\
			-l /lib \
			-l /lib64 \
			-l /usr/lib \
			-l /usr/lib64 \
			-l /usr/local/lib \
			-l /usr/local/lib64 \
		\
		-o /tmp/sanatize-libs-found \
		-x /tmp/sanatize-libs-missed \
			|| exit 6

#----------------------------------------------------------------------------------------

	logit "$MYNAME :: Sanatizacao concluida"

#----------------------------------------------------------------------------------------

# Concluir
	#touch "$TMPDST/.done"

	logit "$MYNAME :: Concluido"
	echo; echo





































