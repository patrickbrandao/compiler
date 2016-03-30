#!/bin/sh

#
# Instalar pacote
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

	# verificar integridade?
	ICHECK=0

	# caminho do / (para o caso de ser instalacao da distro)
	ROOT=""

	# Nomes
	APPNAME=""

# Funcoes
	# ajuda de como usar
	_usage() {
		echo
		echoc -c white -l -n 'Use: '; echoc -c green -l -n 'ixpkg '; echoc -c cyan -n '[opcoes]'; echoc -c yellow ' <arquivo-do-pacote>'
		echoc -c gray        "    ixpkg e' usado para instalar um pacote no sistema (.zip, .tgz, .txz, .myp)"
		echo
		echoc -c cyan -l     '    Opcoes:'
		echoc -c cyan -l -n  '	      --root DIR';     echoc -c gray '       - Informe o diretorio root (no lugar de /)'
		echoc -c cyan -l -n  '	      --check   ';     echoc -c gray '       - Verificar integridade dos arquivos apos instala-los'
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

	# copiar script executavel
	_pkg_copyscript(){
		_pkg_csrc="$1"
		_pkg_cdst="$2"
		cp "$_pkg_csrc" "$_pkg_cdst" || return
		chmod +x "$_pkg_cdst"
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

	# analisar pacote instalado e fazer instalacoes e correcoes
	_pkg_setup(){
		xroot="$1"
		cd "$xroot" || return

		# Ativar bibliotecas (PRE)
		echoc -c gray -n '.'
		_pkg_ldconfig "$xroot"

		# Instalar ou remover novos arquivos
		# o caminho registrado no arquivo e' totalmente qualificado (com / no inicio)
		if [ -f install/news ]; then
			newslist=$(cat install/news)
			echoc -c gray -n '.'
			for new in $newslist; do
				_dir=$(dirname $new)
				_orig="$_dir/$(basename $new .new)"
				if [ -f "$xroot/$_orig" ]; then
					# ja existe, ignorar novo
					rm -f "$new" 2>/dev/null 2>/dev/null
				else
					# nao existe, instalar novo
					mv "$xroot/$new" "$xroot/$_orig" 2>/dev/null
				fi
			done
		fi 

		# Instalar arquivos imperativos
		# o caminho registrado no arquivo e' totalmente qualificado (com / no inicio)
		cd "$xroot" || return
		if [ -f install/sets ]; then
			setlist=$(cat install/sets)
			echoc -c gray -n '.'
			for new in $setlist; do
				_dir=$(dirname $new)
				_orig="$_dir/$(basename $new .new)"
				# instalar no caminho definitivo
				mv "$xroot/$new" "$xroot/$_orig" 2>/dev/null
			done
		fi 

		# Remover arquivos imperativos
		# o caminho registrado no arquivo e' totalmente qualificado (com / no inicio)
		cd "$xroot" || return
		if [ -f install/deletes ]; then
			dellist=$(cat install/deletes)
			echoc -c gray -n '.'
			for new in $dellist; do
				_dir=$(dirname $new)
				_orig="$_dir/$(basename $new .delete)"
				# instalar no caminho definitivo
				rm -f "$xroot/$_orig" 2>/dev/null
			done
		fi 

		# Executar pos-instalador
		cd "$xroot" || return
		if [ -d "$ROOT/install" ]; then
			cd "$ROOT/install" || return
			_dolist=""
			for _dox in doinst*; do [ -f "$_dox" ] && _dolist="$_dolist $_dox"; done
			if [ "x$_dolist" != "x" ]; then
				for _dox in $_dolist; do
					# Ativar bibliotecas (POS)
					_pkg_ldconfig "$xroot"
					echoc -c gray -n '.'
					# *> Script de instalacao
					(sh $_dox) 2>/dev/null 1>/dev/null
				done
			fi
		fi

		# Manter padronizacao com doinst global do slackware
		if [ -f $ROOT/install/doinst.sh ]; then
			# Ativar bibliotecas (POS)
			_pkg_ldconfig "$xroot"
			# *> Script de instalacao
			echoc -c gray -n '.'
			(sh install/doinst.sh) 2>/dev/null 1>/dev/null
			echoc -c gray -n '.'
		fi 

		# Copiar scripts de eventos
		cd "$xroot" || return
		for _evscript in onboot onshutdown ondelete onrepair; do
			[ -f install/$_evscript.sh ] && _pkg_copyscript install/$_evscript.sh $FULLLEVDIR/$_evscript-$APPNAME.sh
			echoc -c gray -n '.'
		done

		# Limpar arquivos
		cd "$xroot" || return
		(rm -rf install) 2>/dev/null

		# Ativar bibliotecas (POS), caso algum script mude algo
		_pkg_ldconfig "$xroot"
		echoc -c gray -n '.'
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

		# nao verificar
		elif [ "$1" = "-no-check" -o "$1" = "--no-check" -o "$1" = "-n" ]; then
			ICHECK=0
			shift 1

		# verificar
		elif [ "$1" = "-check" -o "$1" = "--check" -o "$1" = "-c" ]; then
			ICHECK=1
			shift 1
		
		else
			break
		fi
	done

	# Sem argumentos restantes
	n=$(echo "$@")
	if [ "x$n" = "x" ]; then _usage; fi


# Caminhos
	# Diretorio de base para logs e nomes de arquivos instalados
	FULLBASEDIR="$ROOT/$BASEDIR"
	[ -d "$FULLBASEDIR" ] || mkdir -p "$FULLBASEDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLBASEDIR'"

	# Diretorio de repositorio
	FULLLIBDIR="$ROOT/$LIBDIR"
	[ -d "$FULLLIBDIR" ] || mkdir -p "$FULLLIBDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLLIBDIR'"

	# Diretorio de eventos
	FULLLEVDIR="$ROOT/$EVDIR"
	[ -d "$FULLLEVDIR" ] || mkdir -p "$FULLLEVDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLLEVDIR'"

	# ROOT nao pode ser vazio
	if [ "x$ROOT" = "x" ]; then ROOT="/"; fi


# Processar parametros alvos (nome de pacotes relativos ou fqdn)
	HERE=$(pwd)
	for PACKAGE in $* ; do

		# diretorio onde o comando esta sendo executado
		cd $HERE || iabort "install:cd" "Erro ao entrar no diretorio '$HERE'"

		# Gerar caminho FQDN do arquivo
		FQDN="$(readlink -f $PACKAGE)"

		# Nao tolerar erros, podem ser fatais para a coletividade
		[ -f "$FQDN" ] || iabort "install:file" "Arquivo '$FQDN' nao encontrado"

		# Obter extencao do arquivo
		EXT="$(fileextension $PACKAGE)"
		[ "$EXT" = "tgz" -o "$EXT" = "txz" -o "$EXT" = "zip" ] || iabort "install:extension" "Tipo de arquivo '$EXT' desconhecido"

		# Obter nome do arquivo (sem pasta)
		FILENAME=$(basename "$PACKAGE")

		# Tamanho do ficheiro compactado
		FILESIZE=$(du -sh "$FQDN" | cut -f1)

		# Nome sem extensao
		BASENAME=$(basename "$FILENAME" .$EXT)

		# Nome do aplicativo (sem versao e sem extensao)
		APPNAME=$(echo $BASENAME | cut -f1 -d'-')

		# caminho da copia de repositorio (backup)
		STOREDFILE="$FULLLIBDIR/$FILENAME"
		STOREDMD5="$FULLLIBDIR/$BASENAME.md5"

		#**
		lineclear -n -r -w 80
		echoc -c white -n "Analisando. "; echoc -l -n -c cyan "[$BASENAME]"

		# registrar arquivos do pacote
		RFILE="$FULLBASEDIR/$BASENAME"
		touch $RFILE

		# Conta numero de arquivos no ficheiro
		#FILELIST=""
		FILECOUNT="0"
		DEZIPER=""

		#**
		lineclear -n -r -w 80
		echoc -c white -n "Analisando arquivos... "; echoc -l -n -c cyan "[$BASENAME]"

		# ARQUIVOS TXZ
		if [ "$EXT" = "txz" ]; then
			tar -Jtf "$FQDN" > $RFILE
			DEZIPER="tar -vxf '$FQDN'"
		fi
		# ARQUIVOS TAR + GZ
		if [ "$EXT" = "tgz" ]; then
			tar -tf "$FQDN" > $RFILE
			DEZIPER="tar -xvzf '$FQDN'"
		fi
		# ARQUIVOS ZIP
		if [ "$EXT" = "zip" ]; then
			unzip -l "$FQDN" | egrep '.*[0-9]{2}-[0-9]{2}-[0-9]{4}' > $RFILE
			DEZIPER="unzip -o '$FQDN'"
		fi

		#**
		lineclear -n -r -w 80
		echoc -c white -n "Preparando "; echoc -l -n -c cyan "[$BASENAME]"

		# contar numero de arquivos
		FILECOUNT=$(cat $RFILE | wc -l)

		# arquivo vazio
		if [ "$FILECOUNT" -lt "1" ]; then
			echoc -c yellow -n "$APPNAME: "; echoc -c yellow -l "$FILENAME - Arquivo vazio."
			continue
		fi

		# Entrar na pasta ALVO
		cd "$ROOT"

		# Descompactar
		eval "$DEZIPER" 2>/dev/null | shloading -s 1 -l "Instalado" -t "$BASENAME" -m "$FILECOUNT" -c -n
		ret="$?"

		# Garantir gravacao no disco
		lineclear -n -r -w 80
		echoc -n -c green -l "Sincronizando "; echoc -c cyan -l -n "[$BASENAME]"
		sync; echoc -c gray -n "."
		sync; echoc -c gray -n "."

		# Verificar
		if [ "$ret" = "0" ]; then

			# limpar linha do loading e exibir mensagem de concluido
			lineclear -n -r -w 80
			echoc -n -c green -l "Ativando  "; echoc -c cyan -l -n "[$BASENAME]"

			# colocar lista de arquivos instalados
			_pkg_setup "$ROOT"

			# gerar copia de repositorio
			md5FQDN=$(getmd5sum "$FQDN")
			md5STORED=$(getmd5sum "$STOREDFILE")
			if [ "x$md5STORED" = "x" -o "$md5STORED" != "$md5FQDN" ]; then cp -rf "$FQDN" "$STOREDFILE" 2>/dev/null; fi
			echo "$md5FQDN" > "$STOREDMD5"

			# concluido
			lineclear -n -r -w 80
			echoc -n -c green -l "Instalado "; echoc -c cyan -l -n "[$BASENAME]"

			# fazer verificacao de sintaxe
			if [ "$ICHECK" = "1" ]; then
				fxpkg -r "$ROOT" --no-repair "$FQDN"
			else
				echo
			fi
		else
			# erro na instalacao
			iabort "install:dezip" "Erro $ret ao executar '$DEZIPER'"
		fi

	done










