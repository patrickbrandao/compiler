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

	# ajuda de como usar
	_usage() {
		echo
		echoc -c white -l -n 'Use: '; echoc -c green -l -n 'rxpkg '; echoc -c yellow ' <arquivo-do-pacote>'
		echoc -c gray        "    rxpkg e' usado para remover um pacote do sistema"
		echo
		echoc -c cyan -l     '    Opcoes:'
		echoc -c cyan -l -n  '	      --root DIR';     echoc -c gray '       - Informe o diretorio root (no lugar de /)'
		echoc -c cyan -l -n  '	      --full    ';     echoc -c gray '       - Remover completamente (incluindo repo e sigs)'
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

	# executar script de evento
	_event_script_exec(){
		_loc_fullscript="$1"
		_loc_localscript="$2"
		if [ "$ROOT" = "/" ]; then
			# rodando no sistema atual
			[ -x "$_loc_localscript" ] && /bin/sh "$_loc_localscript"
		else
			# rodando em sistema destino
			# rodar CHROOT
			# verificar se o sistema CHROOT esta disponivel
			if [ -x "$ROOT/bin/sh" ]; then
				# sim
				chroot "$ROOT" /bin/sh "$_loc_localscript"
			else
				# nao, rodar aqui mesmo
				[ -x "$_loc_localscript" ] && /bin/sh "$_loc_localscript"
			fi
		fi
	}

# Opcoes:
	BASEDIR="/var/log/packages"
	LIBDIR="/var/lib/packages"

	EVDIR="/var/lib/packages/.events"

	# caminho do / (para o caso de ser instalacao da distro)
	ROOT=""

	# Modo: normal ou full
	MODE=normal
	NEEDREPAIR=0
	CHECKALL=0

# Processar argumentos
	while [ 0 ]; do
		# Ajuda
		if [ "$1" = "-h" -o "$1" = "--h" -o "$1" = "--help" ]; then _usage; fi
		# Modos
		if [ "$1" = "-f" -o "$1" = "-full" -o "$1" = "--full" -o "$1" = "full" ]; then MODE=full; shift; continue; fi
		# Diretorio ROOT
		if [ "$1" = "-root" -o "$1" = "--root"  -o "$1" = "-r" ]; then
			if [ "$2" = "" ]; then
				_usage
				exit
			fi
			ROOT="$2"
			shift 2		
		else
			break
		fi
	done

# Caminhos
	# Diretorio de base para logs e nomes de arquivos instalados
	FULLBASEDIR="$ROOT/$BASEDIR"
	[ -d "$FULLBASEDIR" ] || mkdir -p "$FULLBASEDIR" || iabort "remove:mkdir" "Erro ao criar diretorio '$FULLBASEDIR'"

	# Diretorio de repositorio
	FULLLIBDIR="$ROOT/$LIBDIR"
	[ -d "$FULLLIBDIR" ] || mkdir -p "$FULLLIBDIR" || iabort "remove:mkdir" "Erro ao criar diretorio '$FULLLIBDIR'"

	# ROOT nao pode ser vazio
	# Diretorio de eventos
	FULLLEVDIR="$ROOT/$EVDIR"
	[ -d "$FULLLEVDIR" ] || mkdir -p "$FULLLEVDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLLEVDIR'"

	if [ "x$ROOT" = "x" ]; then ROOT="/"; fi

	# diretorios com assinaturas md5
	SIG_DIR=$FULLBASEDIR/.sigs

# Pasta temporaria
	mkdir -p "$ROOT/tmp" 2>/dev/null

# Lista de alvos
	# usar parametros
	LIST="$*"
	if [ "x$LIST" = "x" ]; then _usage; fi

# Processar parametros alvos (nome de pacotes relativos ou fqdn)
	HERE=$(pwd)
	for PACKAGE in $LIST ; do

		# diretorio onde o comando esta sendo executado
		cd $HERE || iabort "remove:cd" "Erro ao entrar no diretorio '$HERE'"

		# O arquivo alvo pode ser
		#  1: um arquivo real, de onde vamos obter o nome do arquivo em .sigs/
		#  2: o nome de um arquivo no diretorio .sigs/

		# obter nome com versao caso seja omitido
		sigtmp=$(echo $SIG_DIR/$PACKAGE-?.? | rev | awk '{print $1}' | rev)

		# 1 - arquivo real
		if [ -f "$PACKAGE" ]; then

			# Gerar caminho FQDN do arquivo
			FQDN="$(readlink -f $PACKAGE)"

			# Nao tolerar erros, podem ser fatais para a coletividade
			[ -f "$FQDN" ] || iabort "remove:file" "Arquivo '$FQDN' nao encontrado"

			# Obter extencao do arquivo
			EXT="$(echo $PACKAGE | rev | cut -f 1 -d . | rev)"
			[ "$EXT" = "tgz" -o "$EXT" = "txz" -o "$EXT" = "zip" ] || iabort "remove:extension" "Tipo de arquivo '$EXT' desconhecido"


			# Obter nome do arquivo (sem pasta)
			FILENAME=$(basename "$PACKAGE")

			# Nome sem extensao
			BASENAME=$(basename "$FILENAME" .$EXT)

			# Nome do arquivo com assinaturas
			MD5LISTFILE="$SIG_DIR/$BASENAME"

			# Lista de arquivos do pacote
			PKGLIST="$FULLBASEDIR/$BASENAME"

		# 2 - nome de pacote instalado (com versao)
		elif [ -f "$SIG_DIR/$PACKAGE"  ]; then

			# Tentar encontrar o pacote FQDN contendo os arquivos
			FQDN=""; EXT=""; FILENAME=""
			if [ -f "$FULLLIBDIR/$PACKAGE.zip" ]; then FQDN="$FULLLIBDIR/$PACKAGE.zip"; EXT="zip"; FILENAME="$PACKAGE.zip"; fi
			if [ -f "$FULLLIBDIR/$PACKAGE.tgz" ]; then FQDN="$FULLLIBDIR/$PACKAGE.tgz"; EXT="tgz"; FILENAME="$PACKAGE.tgz"; fi
			if [ -f "$FULLLIBDIR/$PACKAGE.txz" ]; then FQDN="$FULLLIBDIR/$PACKAGE.txz"; EXT="txz"; FILENAME="$PACKAGE.txz"; fi

			# arquivo em sig ja e' o nome base
			BASENAME="$PACKAGE"

			# Nome do arquivo com assinaturas
			MD5LISTFILE="$SIG_DIR/$PACKAGE"

			# Lista de arquivos do pacote
			PKGLIST="$FULLBASEDIR/$BASENAME"

		# 3 - nome do pacote instalado sem versao, obter ultima versao
		elif [ -f "$sigtmp"  ]; then

			PACKAGE=$(basename $sigtmp)

			# Tentar encontrar o pacote FQDN contendo os arquivos
			FQDN=""; EXT=""; FILENAME=""
			if [ -f "$FULLLIBDIR/$PACKAGE.zip" ]; then FQDN="$FULLLIBDIR/$PACKAGE.zip"; EXT="zip"; FILENAME="$PACKAGE.zip"; fi
			if [ -f "$FULLLIBDIR/$PACKAGE.tgz" ]; then FQDN="$FULLLIBDIR/$PACKAGE.tgz"; EXT="tgz"; FILENAME="$PACKAGE.tgz"; fi
			if [ -f "$FULLLIBDIR/$PACKAGE.txz" ]; then FQDN="$FULLLIBDIR/$PACKAGE.txz"; EXT="txz"; FILENAME="$PACKAGE.txz"; fi

			# arquivo em sig ja e' o nome base
			BASENAME="$PACKAGE"

			# Nome do arquivo com assinaturas
			MD5LISTFILE="$SIG_DIR/$PACKAGE"

			# Lista de arquivos do pacote
			PKGLIST="$FULLBASEDIR/$BASENAME"

		else
			# Alienigena
			iabort "remove:param" "Parametro desconhecido '$PACKAGE', arquivo nao encontrado"
		fi

		# Nome simples do pacote
		APPNAME=$(echo $BASENAME | cut -f1 -d'-')

		#echo "FQDN: $FQDN"

		# Arquivo com lista de registros a serem processados (vamos filtrar os .new)
		PKGFILELIST="$ROOT/tmp/rxpkg-list-$BASENAME"
		PKGFILELISTUNIQUE="$ROOT/tmp/fxpkg-listu-$BASENAME"

		# Acessar pasta ROOT
		cd "$ROOT/" || iabort "remove:cd" "Erro ao entrar no diretorio '$ROOT/'"

		# **
		lineclear -n -r -w 80
		echoc -c red -n -l "Pacote "
		echoc -c yellow -n -l "[$BASENAME] "
		echoc -c red -l -n "Obtendo itens"
		usleep 500000

		# Obter lista de arquivos de assinatura
		cat $MD5LISTFILE | \
			egrep -v '\.new$' | \
			egrep -v '/$' | \
			egrep -v '\.new$' | \
			sed 's#\ /#\ ./#g' | \
			awk '{print $2}' > $PKGFILELIST

		# Obter lista de arquivos do pacote
		if [ -f "$PKGLIST" ]; then cat "$PKGLIST" >> $PKGFILELIST; fi

		# Juntar listas sem duplicacoes
		sort -u "$PKGFILELIST" > $PKGFILELISTUNIQUE

		FILECOUNT=$(wc -l $PKGFILELISTUNIQUE | awk '{print $1}')

		# **
		lineclear -n -r -w 80
		echoc -c red -n -l "Pacote "
		echoc -c yellow -n -l "[$BASENAME] "
		echoc -c red -l -n "Itens: $FILECOUNT"
		sleep 1

		# Remover com loading
		cat $PKGFILELISTUNIQUE | while read xfile; do
			dn=$(dirname "$xfile")

			# remover arquivo
			rm -f "$xfile" 2>/dev/null

			# pasta e superiores, se estiverem vazias
			rmdir -p "$dn" 2>/dev/null

			# linha para loading
			#- echo "$xfile"
			echo "."

		done | shloading -s 2 -l "Removendo" -t "$BASENAME" -m "$FILECOUNT" -c -n #-d 5000

		# remover arquivo de assinaturas
		if [ -f "$PKGLIST" ]; then rm -f "$PKGLIST"; fi
		rm -f "$PKGFILELISTUNIQUE" "$PKGFILELIST" 2>/dev/null

		# Remocao completa: remover reposito e assinaturas
		if [ "$MODE" = "full" ]; then
			rm -f "$MD5LISTFILE" 2>/dev/null
			if [ -f "$FQDN" ]; then rm -f "$FQDN" 2>/dev/null; fi
		fi

		# Executar evento de remocao do pacote
		# executar evento ondelete-APPNAME.sh
		_repair_script="$FULLLEVDIR/ondelete-$APPNAME.sh"
		_repair_script_loc="$EVDIR/ondelete-$APPNAME.sh"
		_event_script_exec "$_repair_script" "$_repair_script_loc"

		# **
		lineclear -n -r -w 80
		echoc -c red -n -l "Pacote "
		echoc -c yellow -n -l "[$BASENAME] "
		echoc -c red "removido"

	done

















