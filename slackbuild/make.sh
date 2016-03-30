#!/bin/sh

. /compiler/conf.sh

	_nops(){ logity -n "Slackbuild.make: Falhou em "; echoc -c pink -l "$@"; exit 1; }

	_admin_continue(){
		echo
		echo
		echoc -c yellow -n " > Um erro foi detectado no script '$1', deseja continuar ? (y/n) "
		read x
		[ "$x" = "y" ] || _nops "Compilacao abortada pelo administrador. $1"
	}

#-----------------------------------------------------------************************************ PROJETOS NECESSARIOS PELO COMPILADOR

	GLOBALOPT=""

#-----------------------------------------------------------************************************ PROJETOS NECESSARIOS PELO COMPILADOR

	# Atualizar data/hora
	(ntpdate a.ntp.br) 2>/dev/null 1>/dev/null &

	# Comandos auxiliares no sistema
	[ -f /bin/logit ] || /compiler/projects/toolbox/_make.sh || _nops "Erro em projects/toolbox"
	[ -f /usr/bin/dezip ] || /compiler/projects/myscripts/_make.sh || _nops "Erro em projects/myscripts"
	[ -f /usr/sbin/ixpkg ] || /compiler/projects/pkgmanager/_make.sh || _nops "Erro em projects/pkgmanager"


#-----------------------------------------------------------************************************ EVITAR CACHE DE ALGUNS PROJETOS


	#logity "Apagando cache de projetos vitais"
	#(rm /tmp/baseconf* -rf /tmp/baselinux-pkg-toolbox* /tmp/baselinux-pkg-myscripts* /compiler/packages/distro/slackmini/baseconf* ) 2>/dev/null 1>/dev/null
	#(rm -rf /tmp/baselinux-pkg-toolbox* /tmp/baselinux-pkg-myscripts* /compiler/packages/distro/slackmini/baseconf* ) 2>/dev/null 1>/dev/null


	logity "Forcar recriacao de pacotes"
#	( cd /compiler/packages/distro/slackmini;  rm baselibs* basexlibs* baseapps* baseutils* basenet* baseconf*)



# Kernel, muitos pacotes depende das bibliotecas do kernel
#-----------------------------------------------------------************************************ CRIACAO DE PACOTES

	PACKAGES="
		kernel

		baseconf
		baselibs
		basexlibs
		baseapps
		baselinux
		basenet
		baseutils

		baseshell
		basefront
		basedb
		basenetapps
		basetools
		basevolatile
		basevoip
	"
	PFILES=""
	for pkg in $PACKAGES; do
		/compiler/slackbuild/build-package.sh $GLOBALOPT $pkg	|| _nops "$pkg"
		PFILES="$PFILES $SYSBASE/$pkg-$DISTRO_VERSION.txz"
	done

#-----------------------------------------------------------************************************ VERIFICAR REPETICAO DE ARQUIVOS POR PACOTE

	# Dups
	/compiler/projects/myscripts/duptester.sh 			\
		$PFILES											\
		\
		|| abort "Incapaz de finalizar o projeto, duplicacoes encontradas."

#-----------------------------------------------------------************************************ VERIFICAR REPETICAO AO UNIR PACOTES


# Verificar se o sistema esta habil para funcionamento
	/compiler/slackbuild/sanatize.sh 									|| _admin_continue "sanatize.sh"

# Criar instaladores

	# Instaladores e imagens (ISO / Pendrive)
	/compiler/slackbuild/build-package.sh nopkg 	installer			|| _nops "baseutils"







































