#!/bin/sh

#
#
# Atualizar pacote usando http-sync
#
#
# indice: /etc/pkgmanager.conf
#---------------------------------------------------------
#
# interval=600
# -> tempo em minutos entre invervalos, minimo 30 minutos
#
# version=1.0
# -> versao da distribuicao atual (padrao em /etc/os-release)
#
# site=download@.slackmini.com.br
# -> nome DNS do site @ pode ser usado para variar numeros de 0 a 9
#
# path=packages/$version
# -> nome do diretorio no site do update oficial
#
# bpath=packages/beta/$version
# apath=packages/alpha/$version
# -> pastas dos pacotes de beta-update (pre-release) e alpha-updates (dev)
#
# proto=http
# -> protocolo de download: http, https, ftp
#
# http_port=80
# https_port=443
# -> porta dos protocolos http e https, personalizar para escapar de proxys
#
# timeout=7
# -> tempo de inatividade tcp (tentar conectar)
# retries=300
# -> numero de tentativas para conectar
#
# readtimeout=5
# -> tempo de inatividade de uma conexao estabelecida
#
#
#---------------------------------------------------------
#

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Padronizar saida
	unset LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY \
	  LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT \
	  LC_IDENTIFICATION LC_ALL
	LANG=C
	export LANG


# Opcoes:
	BASEDIR="/var/log/packages"
	LIBDIR="/var/lib/packages"
	CONFDIR="$LIBDIR/conf"
	BOOTDIR="$LIBDIR/boot"

	# Caminhos para instalacao de distro
	FULLBASEDIR=""
	FULLLIBDIR=""
	FULLLEVDIR=""
	FULLCONFDIR=""
	FULLBOOTDIR=""

	# instalar ou agendar
	ONBOOTUPDATE=0

	# Atualizar todos os pacotes
	UPDATEALL=0

	# Lista de pacotes a atualizar
	PACKAGES=""

	# Release do pacote: core, beta, alpha
	# vazio utilizar a ultima release
	RELEASE=""

	# Configuracao padrao de update
	UPCONF="/etc/pkgmanager.conf"
	std_interval=600
	std_version=1.0
	std_site=download@.slackmini.com.br
	std_path=packages/$version
	std_bpath=packages/beta/$version
	std_apath=packages/alpha/$version
	std_proto=http
	std_http_port=80
	std_https_port=443
	std_timeout=7
	std_retries=300
	std_readtimeout=5
	std_ipversion=dual

	# Versao da distro
	OSVERSION=$std_version

	# caminho do / (para o caso de ser instalacao da distro)
	ROOT=""

# Funcoes

	# ajuda de como usar
	_usage() {
		echo
		echoc -c white -l -n 'Use: '; echoc -c green -l -n 'uxpkg '; echoc -c cyan -n '[opcoes]'; echoc -c yellow ' <arquivo-do-pacote>'
		echoc -c gray        "  uxpkg e' usado para atualizar um pacote no sistema (.zip, .tgz, .txz, .myp)"
		echo
		echoc -c cyan -l     '  Opcoes:'
		echoc -c cyan -l -n  '	  --root DIR        '; echoc -c gray ' - Informe o diretorio root (no lugar de /)'
		echoc -c cyan -l -n  '	  --conf CFG        '; echoc -c gray ' - Configuracao padrao de update'
		echoc -c cyan -l -n  '	  --boot            '; echoc -c gray ' - Baixar e agendar, o update deve ser aplicado no BOOT (requer reboot)'
		echoc -c cyan -l -n  '	  --now             '; echoc -c gray ' - Instalar update imediatamente (padrao)'
		echoc -c cyan -l -n  '	  --all             '; echoc -c gray ' - Atualizar todos os pacotes presentes'
		echoc -c cyan -l -n  '	  --core/beta/alpha '; echoc -c gray ' - Alternar de release (padrao core)'
		echo
		exit 1
	}
	iabort(){
		iatitle="$1"
		iatext="$2"
		echo
		echoc -c red -l -n "$iatitle"; echo -n " "; echoc -c yellow -l "$iatext"
		echo
		exit 2
	}


	# Efetivar UPDATE de um pacote
	_do_update(){

		_du_appname="$1"
		_du_appconf="$FULLCONFDIR/$_du_appname.conf"

		logit2 -n "Atualizando" "[$_du_appname]"

		# Carregar configuracoes padrao
		INTERVAL="$std_interval"
		VERSION="$std_version"
		PKG_URL="$std_site"
		PKG_PATH="$std_path"
		PKG_BPATH="$std_bpath"
		PKG_APATH="$std_apath"
		PROTO="$std_proto"
		HTTP_PORT="$std_http_port"
		HTTPS_PORT="$std_https_port"
		TIMEOUT="$std_timeout"
		RETRIES="$std_retries"
		READTIMEOUT="$std_readtimeout"
		IPVERSION="$std_ipversion"

		# substituir por configuracoes gerais
		if [ -f "$UPCONF" ]; then
			# zerar configuracoes gerais para impedir heranca da chamada anterior
			interval=""
			version=""
			site=""
			path=""
			bpath=""
			apath=""
			proto=""
			http_port=""
			https_port=""
			timeout=""
			retries=""
			readtimeout=""
			ipversion=""
			# incluir configuracao geral
			. "$UPCONF"
			# Obter variaveis especificadas
			[ "x$interval" = "x" ] || INTERVAL="$interval"
			[ "x$version" = "x" ] || VERSION="$version"
			[ "x$site" = "x" ] || PKG_URL="$site"
			[ "x$path" = "x" ] || PKG_PATH="$path"
			[ "x$bpath" = "x" ] || PKG_BPATH="$bpath"
			[ "x$apath" = "x" ] || PKG_APATH="$apath"
			[ "x$proto" = "x" ] || PROTO="$proto"
			[ "x$http_port" = "x" ] || HTTP_PORT="$http_port"
			[ "x$https_port" = "x" ] || HTTPS_PORT="$https_port"
			[ "x$timeout" = "x" ] || TIMEOUT="$timeout"
			[ "x$retries" = "x" ] || RETRIES="$retries"
			[ "x$readtimeout" = "x" ] || READTIMEOUT="$readtimeout"
			[ "x$ipversion" = "x" ] || IPVERSION="$ipversion"
		fi
		# Obter configuracao pelo APP-NAME
		# /var/lib/packages/conf/baselinux.conf
		if [ -f "$_du_appconf" ]; then
			# zerar configuracoes gerais para impedir heranca da chamada anterior
			interval=""
			version=""
			site=""
			path=""
			bpath=""
			apath=""
			proto=""
			http_port=""
			https_port=""
			timeout=""
			retries=""
			readtimeout=""
			ipversion=""
			# incluir configuracao geral
			. "$_du_appconf"
			# Obter variaveis especificadas
			[ "x$interval" = "x" ] || INTERVAL="$interval"
			[ "x$version" = "x" ] || VERSION="$version"
			[ "x$site" = "x" ] || PKG_URL="$site"
			[ "x$path" = "x" ] || PKG_PATH="$path"
			[ "x$bpath" = "x" ] || PKG_BPATH="$bpath"
			[ "x$apath" = "x" ] || PKG_APATH="$apath"
			[ "x$proto" = "x" ] || PROTO="$proto"
			[ "x$http_port" = "x" ] || HTTP_PORT="$http_port"
			[ "x$https_port" = "x" ] || HTTPS_PORT="$https_port"
			[ "x$timeout" = "x" ] || TIMEOUT="$timeout"
			[ "x$retries" = "x" ] || RETRIES="$retries"
			[ "x$readtimeout" = "x" ] || READTIMEOUT="$readtimeout"
			[ "x$ipversion" = "x" ] || IPVERSION="$ipversion"
		fi

		# Sanatizar variaveis preenchendo com valor padrao
		# as variaveis vazias
		[ "x$INTERVAL" = "x" ] && INTERVAL="$std_interval"
		[ "x$VERSION" = "x" ] && VERSION="$std_version"
		[ "x$PKG_URL" = "x" ] && PKG_URL="$std_site"
		[ "x$PKG_PATH" = "x" ] && PKG_PATH="$std_path"
		[ "x$PKG_BPATH" = "x" ] && PKG_BPATH="$std_bpath"
		[ "x$PKG_APATH" = "x" ] && PKG_APATH="$std_apath"
		[ "x$PROTO" = "x" ] && PROTO="$std_proto"
		[ "x$HTTP_PORT" = "x" ] && HTTP_PORT="$std_http_port"
		[ "x$HTTPS_PORT" = "x" ] && HTTPS_PORT="$std_https_port"
		[ "x$TIMEOUT" = "x" ] && TIMEOUT="$std_timeout"
		[ "x$RETRIES" = "x" ] && RETRIES="$std_retries"
		[ "x$READTIMEOUT" = "x" ] && READTIMEOUT="$std_readtimeout"
		[ "x$IPVERSION" = "x" ] && IPVERSION="$std_ipversion"

		# Porta
		PORT="$HTTP_PORT"; [ "$PROTO" = "https" ] && PORT="$HTTPS_PORT"

		# Dual-stack?
		DUALSTACK=""; [ "$IPVERSION" = "dual" ] && DUALSTACK="--dual-stack"

		# Release
		UPATH="$PKG_PATH"

		# no caso de release for "" padrao, deve-se obedecer a release
		# do pacote. Caso a release seja informada, deve-se alternar
		# a release oficial do pacote
		APPRELEASE="$RELEASE"
		APPRELEASECONF="$FULLCONFDIR/$_du_appname.release"
		if [ -f "$APPRELEASECONF" ]; then
			# obter release do pacote
			APPRELEASE=$(head -1 "$APPRELEASECONF")
			case "$APPRELEASE" in
				'core')
					UPATH="$PKG_PATH"
					;;
				'beta')
					UPATH="$PKG_BPATH"
					;;
				'alpha')
					UPATH="$PKG_APATH"
					;;
				*)
					# padrao core por omissao
					# desconsiderar e remover arquivo
					rm -f "$APPRELEASECONF" 2>/dev/null
			esac
		else
			# usar release global e setar no pacote caso nao seja 'core'
			case "$APPRELEASE" in
				'core')
					UPATH="$PKG_PATH"
					[ -f "$APPRELEASECONF" ] && rm -f "$APPRELEASECONF" 2>/dev/null
					;;
				'beta')
					UPATH="$PKG_BPATH"
					echo "beta" > "$APPRELEASECONF"
					;;
				'alpha')
					UPATH="$PKG_APATH"
					echo "alpha" > "$APPRELEASECONF"
					;;
				*)
					# padrao core por omissao
					# desconsiderar e remover arquivo
					[ -f "$APPRELEASECONF" ] && rm -f "$APPRELEASECONF" 2>/dev/null
			esac
		fi


		# Nome do pacote
		_du_pkgname="$_du_appname-$VERSION"

		# Arquivo local
		_du_file="$_du_pkgname.txz"
		_du_filefspatch="$LIBDIR/$_du_file"
		_du_filepatch="$FULLLIBDIR/$_du_file"
		_du_bootlink="$FULLBOOTDIR/$_du_file"
		_du_bootflag="$CONFDIR/$_du_appname.boot"
		_du_tmplist="/tmp/uxpkg-tmp-$RANDOM"

		echoc -c pink " $_du_file"

		# Remover flag de boot antiga, nao podemos ser enganados
		rm -f "$_du_bootlink" 2>/dev/null

		# ------------ Verificar remotamente
		http-sync \
			--label "update" 	\
			--url "$PKG_URL" 	\
			--proto "$PROTO" 	\
			--port "$PORT" 		\
			--path "$UPATH"		\
			--var "osversion=$OSVERSION" \
			--zumbi "$READTIMEOUT" 	\
			--timeout  "$TIMEOUT" 	\
			$DUALSTACK \
			--tries "$RETRIES" \
			--retries "$RETRIES" \
			\
			"$_du_filepatch"; stdno="$?"

		# Analisar retorno
		if [ "$stdno" = "0" ]; then
			logitg -n "Nenhuma atualizacao disponivel "; echoc -c green "[$_du_file]"
			return 0
		elif [ "$stdno" = "1" ]; then
			logitg -n "Novo arquivo adquirido "; echoc -c pink "[$_du_file]"

			# Analisar lista de arquivos
			# - extensao padrao: TXZ
			logitg -n "Analisando arquivos adquirido..."
			tar -Jvtf $_du_filepatch 2>/dev/null 1> "$_du_tmplist"

			lineclear -n -r -w 80
			logit2 "Total de arquivos no ficheiro: " "$(cat $_du_tmplist | wc -l)"
			
			_du_tmp=$(cat "$_du_tmplist" | grep "$_du_bootflag")

			# Proceder com acao de instalacao
			if [ "x$_du_tmp" = "x" -a "$ONBOOTUPDATE" = "0" ]; then
				# Instalar agora
				ixpkg --check --root "$ROOT" "$_du_filefspatch"
				true
			else
				# Agendar para instalar no boot
				logity "Pacote agendado. Requer REBOOT para instalar."
				ln -s "$_du_filefspatch" "$_du_bootlink"
			fi

			return 0
		else
			logity -n "Erro $stdno no http-sync ao atualizar "; echoc -c yellow "[$_du_file]"
			return $stdno
		fi

	}


# Processar argumentos
	while [ 0 ]; do
		# Ajuda
		if [ "$1" = "-h" -o "$1" = "--h" -o "$1" = "--help" ]; then _usage; fi
		# Diretorio ROOT
		if [ "$1" = "-root" -o "$1" = "--root"  -o "$1" = "-r" ]; then
			if [ "$2" = "" ]; then
				_usage
				exit
			fi
			ROOT="$2"
			shift 2

		# configuracao
		elif [ "$1" = "-conf" -o "$1" = "--conf" -o "$1" = "-f" ]; then
			UPCONF="$2"
			shift 2

		# instalar durante proximo boot
		elif [ "$1" = "-boot" -o "$1" = "--boot" -o "$1" = "-b" ]; then
			ONBOOTUPDATE=1
			shift 1

		# instalar durante proximo boot
		elif [ "$1" = "-now" -o "$1" = "--now" ]; then
			ONBOOTUPDATE=0
			shift 1

		# release: core
		elif [ "$1" = "-core" -o "$1" = "--core" ]; then
			RELEASE=core
			shift 1
		# release: beta
		elif [ "$1" = "-beta" -o "$1" = "--beta" ]; then
			RELEASE=beta
			shift 1
		# release: alpha
		elif [ "$1" = "-alpha" -o "$1" = "--alpha" ]; then
			RELEASE=alpha
			shift 1

		# instalar durante proximo boot
		elif [ "$1" = "-all" -o "$1" = "--all" -o "$1" = "-a" ]; then
			UPDATEALL=1
			shift 1

		else
			break
		fi
	done

	# Incluir variaveis da distribuicao
	if [ -f /etc/os-release ]; then . /etc/os-release; OSVERSION="$VERSION"; fi

	# Considerar versao padrao
	[ "x$OSVERSION" = "x" ] && OSVERSION=$std_version
	VERSION="$OSVERSION"


# Caminhos
#-------------------------------------------------------------------------------------------------------------

	# Diretorio de base para logs e nomes de arquivos instalados
	FULLBASEDIR="$ROOT/$BASEDIR"
	[ -d "$FULLBASEDIR" ] || mkdir -p "$FULLBASEDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLBASEDIR'"

	# Diretorio de repositorio
	FULLLIBDIR="$ROOT/$LIBDIR"
	[ -d "$FULLLIBDIR" ] || mkdir -p "$FULLLIBDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLLIBDIR'"

	# Diretorio de eventos
	FULLLEVDIR="$ROOT/$EVDIR"
	[ -d "$FULLLEVDIR" ] || mkdir -p "$FULLLEVDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLLEVDIR'"

	# Diretorio de configuracao
	FULLCONFDIR="$ROOT/$CONFDIR"
	[ -d "$FULLCONFDIR" ] || mkdir -p "$FULLCONFDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLCONFDIR'"

	# Diretorio de pacotes a instalar no boot
	FULLBOOTDIR="$ROOT/$BOOTDIR"
	[ -d "$FULLBOOTDIR" ] || mkdir -p "$FULLBOOTDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLBOOTDIR'"

	# ROOT nao pode ser vazio
	if [ "x$ROOT" = "x" ]; then ROOT="/"; fi



# Efetivar updates
#-------------------------------------------------------------------------------------------------------------


	# Sem argumentos restantes
	n=$(echo "$@")
	if [ "x$n" = "x" -a "$UPDATEALL" = "0" ]; then _usage; fi


	# Instalar todos os pacotes?
	if [ "$UPDATEALL" = "1" ]; then
		PACKAGES=""

		# LISTAR ARQUIVOS DE PACOTES : FULLLIBDIR
		cd "$FULLLIBDIR" || iabort "Erro ao acessar diretorio de pacotes ($FULLLIBDIR)"
		for _pkg in *-$OSVERSION.txz; do [ -f "$i" ] && PACKAGES="$PACKAGES $(basename $_pkg .txz)"; done

		# LISTAR ARQUIVOS DE PACOTES : FULLBASEDIR
		cd "$FULLBASEDIR" || iabort "Erro ao acessar diretorio de log de pacotes ($FULLBASEDIR)"
		for _pkg in *-$OSVERSION; do PACKAGES="$PACKAGES $_pkg"; done

		# Nenhum pacote, desistir
		[ "x$PACKAGES" = "x" ] && iabort "Erro ao obter lista de pacotes, nenhum pacote encontrado."

		# Ordernar e singularizar
		PACKAGES=$(for _pkg in $PACKAGES; do echo $(basename $_pkg "-$OSVERSION"); done | sort -u)

		# Atualizar pacotes pelo APPNAME
		for _pkg in $PACKAGES; do
			_do_update $_pkg && continue

			# Falhou
			iabort "Falhou ao atualizar $_pkg"

		done

	else
		# Update de pacotes selecionados
		PACKAGES=""
		tmplist="$@"

		# Verificar se pacotes existem
		for _pkg in $tmplist; do
			# verificar se o nome proposto e':

			# 1 - appname
			if [ -f "$FULLLIBDIR/$_pkg" -o -f "$FULLBASEDIR/$_pkg" ]; then
				# sim, appname
				PACKAGES="$PACKAGES $_pkg"
				continue
			fi

			# 2 - appname-version
			if [ -f "$FULLLIBDIR/$_pkg-$OSVERSION" -o -f "$FULLBASEDIR/$_pkg-$OSVERSION" ]; then
				# sim, appname-version
				_apn=$(basename "$_pkg" "-$OSVERSION")
				PACKAGES="$PACKAGES $_apn"
				continue
			fi

			# - totalmente desconecido
			iabort "Nome de pacote desconhecido: $_pkg"

		done

		# Atualizar pacotes pelo APPNAME
		for _pkg in $PACKAGES; do
			_do_update $_pkg && continue

			# Falhou
			iabort "Falhou ao atualizar $_pkg"

		done

	fi





