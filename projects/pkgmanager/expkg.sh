#!/bin/sh

#
# Executar eventos de pacotes
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
	EVDIR="/var/lib/packages/.events"
	DONEEVDIR="/var/lib/packages/.done-events"
	BOOTDIR="$LIBDIR/boot"

	# caminho do / (para o caso de ser instalacao da distro)
	ROOT=""

	# Nomes
	APPNAME=""

	# Nome do evento
	EVENT=""
	PBYTE=""

# Funcoes
	# ajuda de como usar
	_usage() {
		echo
		echoc -c white -l -n 'Use: '; echoc -c green -l -n 'expkg '; echoc -c yellow ' <evento>'
		echoc -c gray        "    expkg e' usado para executar eventos de pacote do sistema"
		echo
		echoc -c cyan -l     '    Opcoes:'
		echoc -c cyan -l -n  '	      --root DIR';     echoc -c gray '       - Informe o diretorio root (no lugar de /)'
		echo
		echoc -c cyan -l     '    Eventos:'
		echoc -c cyan -l -n  '	      bootevents  ';     echoc -c gray '       - Executar eventos de boot dos pacotes'
		echoc -c cyan -l -n  '	      bootinstall ';     echoc -c gray '       - Executar instalacao de pacotes no boot'
		echoc -c cyan -l -n  '	      shutdown    ';     echoc -c gray '       - Executa eventos de shutdown dos pacotes'
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


	# Criar links das novas bibliotecas
	_pkg_ldconfig(){
		xroot="$1"
		cd "$xroot" || return
		# Ativar bibliotecas (PRE)
		if [ "$ROOT" = "/" ]; then
			if [ -x /sbin/ldconfig ]; then /sbin/ldconfig; fi
		else
			# pacote na pasta destino da distro
			chroot "$ROOT" "/sbin/ldconfig" 2>/dev/null 1>/dev/null
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
		# Nome do evento
		# - bootevents
		elif [ "$1" = "bootevents" -o "$1" = "-b" ]; then
			EVENT=bootevents
			PBYTE="@"
			shift 1
		# - bootinstall
		elif [ "$1" = "bootinstall" -o "$1" = "-i" ]; then
			EVENT=bootinstall
			PBYTE="@"
			shift 1
		elif [ "$1" = "shutdown" -o "$1" = "-d" ]; then
			EVENT=shutdown
			PBYTE="&"
			shift 1
		else
			break
		fi
	done

	# Sem argumentos restantes
	if [ "x$EVENT" = "x" ]; then _usage; fi


# Caminhos
	# Diretorio de base para logs e nomes de arquivos instalados
	[ -d "$BASEDIR" ] || mkdir -p "$BASEDIR" || iabort "pkg-events:mkdir" "Erro ao criar diretorio '$BASEDIR'"
	[ -d "$LIBDIR" ] || mkdir -p "$LIBDIR" || iabort "pkg-events:mkdir" "Erro ao criar diretorio '$LIBDIR'"
	[ -d "$EVDIR" ] || mkdir -p "$EVDIR" || iabort "pkg-events:mkdir" "Erro ao criar diretorio '$EVDIR'"
	[ -d "$DONEEVDIR" ] || mkdir -p "$DONEEVDIR" || iabort "pkg-events:mkdir" "Erro ao criar diretorio '$DONEEVDIR'"
	[ -d "$BOOTDIR" ] || mkdir -p "$BOOTDIR" || iabort "pkg-events:mkdir" "Erro ao criar diretorio '$BOOTDIR'"

	# ROOT nao pode ser vazio
	if [ "x$ROOT" = "x" ]; then ROOT="/"; fi

	# Sem evento
	if [ "x$EVENT" = "x" ]; then iabort "pkg-events:error" "Evento nao informado"; fi





#---------------------------------------------------------------------- Executar por eventos

	# Listar eventos
	SCRIPTS=""

	logit2 "[expkg] Evento:" "$EVENT"

	case "$EVENT" in
	'bootevents')
		# Executar scripts registrados para rodar no boot
		cd $EVDIR || iabort "pkg-events:cd" "Erro ao acessar diretorio '$EVDIR'"
		for _script in onboot-*; do
			if [ -x "$_script" ]; then SCRIPTS="$SCRIPTS $_script"; fi
		done
		;;

	'bootinstall')
		# Instalar pacotes durante o boot
		cd $BOOTDIR || iabort "pkg-events:cd" "Erro ao acessar diretorio '$BOOTDIR'"

		# Listar pacotes
		PACKAGES=""
		for _pkg in *.txz; do [ -f "$_pkg" ] && PACKAGES="$PACKAGES $_pkg"; done
		[ "x$PACKAGES" = "x" ] && exit

		# Instalar pacotes
		for _pkg in $PACKAGES; do
			# instalar e remover link
			ixpkg --check "$_pkg" && rm "$_pkg" 2>/dev/null
		done

		# concluido
		exit

		;;

	'shutdown')
		# Executar scripts registrados para rodar no desligamento
		cd $EVDIR || iabort "pkg-events:cd" "Erro ao acessar diretorio '$EVDIR'"
		for _script in onshutdown-*; do
			if [ -x "$_script" ]; then SCRIPTS="$SCRIPTS $_script"; fi
		done
		;;

	esac

	# sem scripts para rodar
	if [ "x$SCRIPTS" = "x" ]; then exit; fi

	# Analisar prioridades
	SLIST=""
	for _script in $SCRIPTS; do
		if [ -x "$_script" ]; then
			_sprio=$(egrep -m1 "^#$PBYTE[0-9]{1,2}$" $_script | cut -f2 -d'@')
			[ "x$_sprio" = "x" ] && _sprio=99
			SLIST="$SLIST $_sprio:$_script"
		fi
	done

	# ordenar
	SLIST=$(for x in $SLIST; do echo $x; done | sort -n | cut -f2 -d:)
	NOWDT=$(date "+%Y-%m-%d-%H-%M-%S")

	# executar
	for _svc in $SLIST; do

		# Executando evento
		logit2 "[expkg] Executando script de evento:" "$_svc"

		# Executar script
		/bin/sh "$_svc"; ret="$?"

		# se rodou com sucesso, renomear o script para nao rodar mais
		if [ "$ret" = "0" ]; then
			mv "$_svc" "$DONEEVDIR/$_svc-$NOWDT"
		fi
	done











