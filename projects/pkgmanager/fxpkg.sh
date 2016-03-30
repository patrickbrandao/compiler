#!/bin/sh

#
# Verificar integridade do pacote
#

	# ajuda de como usar
	_usage() {
		echo
		echoc -c white -l -n 'Use: '; echoc -c green -l -n 'fxpkg '; echoc -c cyan -n '[opcoes]'; echoc -c yellow ' <arquivo-do-pacote>'
		echoc -c gray        "    fxpkg e' usado para verificar se algum arquivo do pacote foi corrompido"
		echo
		echoc -c cyan -l     '    Opcoes:'
		echoc -c cyan -l -n  '	      --root DIR';     echoc -c gray '       - Informe o diretorio root (no lugar de /)'
		echoc -c cyan -l -n  '	      --repair  ';     echoc -c gray '       - Reparar, instalar pacote novamente'
		echoc -c cyan -l -n  '	      --test    ';     echoc -c gray '       - Modo teste (padrao), apenas verificar'
		echoc -c cyan -l -n  '	      --all     ';     echoc -c gray '       - Analisar todos os pacotes instalados'
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

	# Modo: check or repair
	MODE=check
	NEEDREPAIR=0
	CHECKALL=0

# Processar argumentos
	while [ 0 ]; do
		# Ajuda
		if [ "$1" = "-h" -o "$1" = "--h" -o "$1" = "--help" ]; then _usage; fi
		# Modos
		if [ "$1" = "-c" -o "$1" = "--check" -o "$1" = "check" ]; then MODE=check; shift; continue; fi
		if [ "$1" = "-x" -o "$1" = "--repair" -o "$1" = "repair" ]; then MODE=repair; shift; continue; fi
		if [ "$1" = "-n" -o "$1" = "--no-repair" -o "$1" = "norepair" ]; then MODE=check; shift; continue; fi
		# Verificar tudo
		if [ "$1" = "-a" -o "$1" = "--all" -o "$1" = "-all" -o "$1" = "all" ]; then CHECKALL=1; shift; continue; fi
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
	# Sem argumentos restantes
	if [ "x$@" = "x" -a "$CHECKALL" = "0" ]; then _usage; fi

# Caminhos

	# Diretorio de base para logs e nomes de arquivos instalados
	FULLBASEDIR="$ROOT/$BASEDIR"
	[ -d "$FULLBASEDIR" ] || mkdir -p "$FULLBASEDIR" || iabort "check:mkdir" "Erro ao criar diretorio '$FULLBASEDIR'"

	# Diretorio de repositorio
	FULLLIBDIR="$ROOT/$LIBDIR"
	[ -d "$FULLLIBDIR" ] || mkdir -p "$FULLLIBDIR" || iabort "check:mkdir" "Erro ao criar diretorio '$FULLLIBDIR'"

	# Diretorio de eventos
	FULLLEVDIR="$ROOT/$EVDIR"
	[ -d "$FULLLEVDIR" ] || mkdir -p "$FULLLEVDIR" || iabort "install:mkdir" "Erro ao criar diretorio '$FULLLEVDIR'"

	# diretorios com assinaturas md5
	SIG_DIR=$FULLBASEDIR/.sigs

	# ROOT nao pode ser vazio
	if [ "x$ROOT" = "x" ]; then ROOT="/"; fi

# Pasta temporaria
	mkdir -p "$ROOT/tmp" 2>/dev/null

# Lista de alvos
	LIST=""
	if [ "$CHECKALL" = "1" ]; then

		# obter lista de pacotes
		LIST=$(cd SIG_DIR && ls -1 2>/dev/null)

	else
		# usar parametros
		LIST="$*"
	fi

# Processar parametros alvos (nome de pacotes relativos ou fqdn)
	HERE=$(pwd)
	for PACKAGE in $LIST ; do

		# diretorio onde o comando esta sendo executado
		cd $HERE || iabort "check:cd" "Erro ao entrar no diretorio '$HERE'"

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
			[ -f "$FQDN" ] || iabort "check:file" "Arquivo '$FQDN' nao encontrado"

			# Obter extencao do arquivo
			EXT="$(echo $PACKAGE | rev | cut -f 1 -d . | rev)"
			[ "$EXT" = "tgz" -o "$EXT" = "txz" -o "$EXT" = "zip" ] || iabort "check:extension" "Tipo de arquivo '$EXT' desconhecido"


			# Obter nome do arquivo (sem pasta)
			FILENAME=$(basename "$PACKAGE")

			# Nome sem extensao
			BASENAME=$(basename "$FILENAME" .$EXT)

			# Nome do arquivo com assinaturas
			MD5LISTFILE="$SIG_DIR/$BASENAME"

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

		else
			# Alienigena
			iabort "check:param" "Parametro desconhecido '$PACKAGE', arquivo nao encontrado"
		fi

		# Nome simples do pacote
		APPNAME=$(echo $BASENAME | cut -f1 -d'-')

		#echo "FQDN: $FQDN"

		# Arquivo com lista de registros a serem processados (vamos filtrar os .new)
		TMPMD5F="$ROOT/tmp/fxpkg-list-$BASENAME"
		TMPFAIL="$ROOT/tmp/fxpkg-failed-$BASENAME"
		TMPRES="$ROOT/tmp/fxpkg-result-$BASENAME"


		# Acessar pasta ROOT
		cd "$ROOT/" || iabort "check:cd" "Erro ao entrar no diretorio '$ROOT/'"

		# **
		lineclear -n -r -w 80
		echoc -c green -n -l "Pacote "
		echoc -c cyan -n -l "[$BASENAME] "
		echoc -c green -l -n "Obtendo assinaturas "
		cat $MD5LISTFILE | \
			egrep -v '\.news$' | \
			egrep -v '\.sets$' | \
			egrep -v '\.deletes$' | \
			egrep -v '/$' | \
			sed 's#\ /#\ ./#g' \
				> $TMPMD5F
		FILECOUNT=$(cat $TMPMD5F | wc -l)
		usleep 500000

		# **

		lineclear -n -r -w 80
		echoc -c green -n -l "Pacote "
		echoc -c cyan -n -l "[$BASENAME] "
		echoc -c green -n -l "$FILECOUNT itens, analisando..."

		md5sum -c $TMPMD5F 2>/dev/null > $TMPRES
		usleep 500000

		# Remove arquivos OK da lista
		cat "$TMPRES" | egrep -v 'OK$' > $TMPFAIL

		#**
		ERRCOUNT=$(wc -l $TMPFAIL | awk '{print $1}')

		if [ "$ERRCOUNT" = "0" ]; then 
			# nenhuma corrupcao
			#**
			lineclear -n -r -w 80
			echoc -c green -n -l "Pacote "
			echoc -c cyan -n -l "[$BASENAME] "
			echoc -c green -l -n "operacional."
			usleep 500000
			echo
			continue
		else
			# deu merda
			lineclear -n -r -w 80
			echoc -c cyan -n -l "[$BASENAME] "; echoc -c red -l " Arquivos corrompidos: $ERRCOUNT"
			logger "fxpkg: pacote $BASENAME com $ERRCOUNT arquivos corrompidos"
			NEEDREPAIR=1
			# Processar lista de falhas
			cat $TMPFAIL | while read F; do
				## for f in $(cat $TMPFAIL); do
				fn=$(echo $F | cut -f1 -d:)
				fe=$(echo $F | cut -f2 -d:); fe=$(echo $fe)
				#**
				echoc -c cyan -n -l "[$BASENAME] "; echoc -c red -l " Modificado: $fn - $fe"
			done
		fi

		# Remover arquivos temporarios
		rm -f "$TMPMD5F" "$TMPRES" "$TMPFAIL" 2>/dev/null

		# modo verificacao, ignorar e analisar proximo
		if [ "$MODE" = "check" ]; then continue; fi

		# modo reparo, precisa ser reparado		
		if [ "$NEEDREPAIR" = "1" -a "x$FQDN" != "x" ]; then
			# reinstalar
			echoc -c cyan -n -l "[$BASENAME] "; echoc -c yellow -l " Reparando instalacao"
			logger "fxpkg: reparando pacote $FQDN"
			ixpkg --no-check --root "$ROOT" "$FQDN"

			# executar evento onrepair-APPNAME.sh
			_repair_script="$FULLLEVDIR/onrepair-$APPNAME.sh"
			_repair_script_loc="$EVDIR/onrepair-$APPNAME.sh"
			_event_script_exec "$_repair_script" "$_repair_script_loc"

		fi

	done




















