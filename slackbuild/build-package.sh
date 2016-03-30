#!/bin/sh

#
# Script para construir pacote do setor
# os setores sao pastas dentro de /compiler/slackbuild/
# 
# Cada pasta deve conter os elementos:
#     exemplo/
#             - packages.dat : arquivo contendo o nome dos pacotes que serao compilados,
#                              exemplo 'tar', o script que gera o pacote devera ser 'pkg-tar.sh'
#
#             - pkg-XXXXX.sh : script construtor do pacote, so recompilara caso o trabalho nao esteja pronto,
#                              a pasta com o trabalho pronto fica em /tmp/exemplo-pkg-XXXXXX/ com o arquivo .done,
#                              apague essa pasta ou o arquivo .done para recompilar o pacote
#
#
# Parametros:
#		$1 				- nome do pacote mestre
#		only=NAME 		- apenas o pacote NAME
#		new 			- compila apenas pacotes novos ou alterados
#		duptest 		- testa arquivos duplicados entre pacotes
#		force/renew 	- apaga tudo e compila novamente
#		develop 		- compila pacotes mas nao gera pacote final (para desenvolvimento apenas)
#
#


. /compiler/conf.sh


	# lista de arquivos que contem a relacao de arquivos .new
	NEWSLIST=""

	# lista de diretorios com os pacotes prontos
	RESULTDIRS=""
	RESULTREGS=""

	# variaveis passadas por argumento
	PROJECTNAME=""
	CMD=""
	FORCE=0
	DEVELOP=0
	RENEW=0
	ONLY=""
	NOPKG=0

	# Compilar um pacote
	_make_pkg(){
		locPKG="$1"

		# caminho do script
		SPKG="$HERE/pkg-$locPKG.sh"

		# pasta com resultados dos pacotes
		RPKG="/tmp/$MYNAMEIS-pkg-$locPKG"
		DFLAG="/tmp/$MYNAMEIS-pkg-$locPKG/.done"

		# incrementar lista de pacotes
		RESULTDIRS="$RESULTDIRS $RPKG"
		RESULTREGS="$RESULTREGS $locPKG:$RPKG"

		# Arquivo com lista de news em cache (arquivo resultado final)
		NEWSFILE="/tmp/news-$MYNAMEIS-$locPKG"
		NEWSTEMP="/tmp/news-temp-$MYNAMEIS-$locPKG"

		# parametros passados ao sub-script
		SUBARG=""

		# Limpar pasta?
		CLSPKGDIR=0

		# pular caso seja algum comando de teste
		if [ "$CMD" = "duptest" ]; then return; fi

		# Verificar se o md5 do script mudou, pois isso ajuda muito
		# durante o desenvolvimento de um novo script ou edicao de um existente
		scriptmd5=$(getmd5sum "$SPKG")
		spatchmd5=$(strmd5 "$SPKG"); spatchmd5="/tmp/script-sig-$spatchmd5"
		storedmd5=$(head -1 "$spatchmd5" 2>/dev/null)
		if [ "x$storedmd5" = "x" ]; then storedmd5="empty-md5"; fi

		# se o md5 do script atual for diferente do md5 anterior, apagar a pasta do pacote e refazer tudo
		if [ "$storedmd5" = "$scriptmd5" ]; then
			# script e' o mesmo
			true
		else
			# script mudou
			logit2 ":: Script atualizado: $SPKG" "$scriptmd5"
			echo "$scriptmd5" > $spatchmd5

			# apagar projeto em cache
			CLSPKGDIR=1
		fi

		# remover flag para forcar recompilacao
		if [ "$FORCE" = "1" ]; then
			logit "Pacote: $PKG, modo FORCE ATIVO, removendo .done"
			CLSPKGDIR=1
		fi

		# LIMPAR?
		if [ "$CLSPKGDIR" = "1" ]; then
			logit2 "Removendo pasta do cache de compilacao:" "$RPKG"
			clsdir "$RPKG"
		fi

		# pacote ja foi compilado
		if [ -f "$DFLAG" ]; then
			logit2 "*** Concluido (em cache):" "$locPKG"
			return
		fi

		# Executar script do construtor
		[ -f "$SPKG" ] || abort "SUB-SCRIPT AUSENTE: $SPKG"

		# lista de novos arquivos opcionais (inicialmente vazia)
		rm -f "$NEWSFILE" "$NEWSTEMP" 2>/dev/null

		# executar comiplador do pacote
		sh $SPKG "$RPKG" "$NEWSTEMP" $SUBARG; r="$?"
		if [ "$r" = "0" ]; then
			# terminou com sucesso
			# verificar se o pacote sinalizou que terminou o trabalho
			if [ ! -f "$DFLAG" ]; then abort "SUB-SCRIPT NAO SINALIZOU CONCLUCAO ($DFLAG): $SPKG"; fi

			# o projeto declarou news?
			if [ -f "$NEWSTEMP" ]; then cp "$NEWSTEMP" "$NEWSFILE"; fi

		else

			# bugou
			echo
			echoc -c red  -l "Erro $r ao executar: "
			echoc -c cyan -l "sh $SPKG '$RPKG' '$NEWSFILE'"
			abort "SUB-SCRIPT FALHOU: $SPKG"


		fi
	}

	# processar argumentos
	for arg in $@; do
		if [ "$arg" = "pkgname" -o "$arg" = "name" ]; then CMD=pkgname; continue; fi
		if [ "$arg" = "path" -o "$arg" = "fqdn" ]; then CMD=pkgfqdn; continue; fi
		if [ "$arg" = "dup" -o "$arg" = "duptest" -o "$arg" = "dups" ]; then CMD=duptest; continue; fi 		# verificar arquivos duplicados entre projetos
		if [ "$arg" = "-f" -o "$arg" = "force" -o "$arg" = "renew" ]; then FORCE=1; continue; fi 			# deletar tudo e fazer novamente
		if [ "$arg" = "-d" -o "$arg" = "dev" -o "$arg" = "develop" ]; then DEVELOP=1; continue; fi 			# deleta pacote principal, recria mas nao salva
		if [ "$arg" = "-n" -o "$arg" = "new" -o "$arg" = "renew" ]; then RENEW=1; continue; fi 				# recriar pacote principal apenas
		if [ "$arg" = "-P" -o "$arg" = "nopkg" ]; then NOPKG=1; continue; fi 								# nao criar pacote (apenas executar scripts)

		# parametros de valor
		argn=$(echo $arg | cut -f1 -d= -s)
		argp=$(echo $arg | cut -f2 -d= -s)
		if [ "$argn" = "only" ]; then ONLY="$argp"; continue; fi
		PROJECTNAME="$arg"
	done
	PROJECTNAME=$(echo $PROJECTNAME | sed 's#[^a-z0-9._-]##g')

	# nome da pasta que deve ser compilada
	PKGDIR="/compiler/slackbuild/$PROJECTNAME"
	PKGIDX="$PKGDIR/packages.dat"

	# verificar existencia do projeto
	if [ "x$PROJECTNAME" = "x" ]; then abort "Informe no primeiro parametro o nome do projeto a compilar"; fi
	if [ ! -d "$PKGDIR" ]; then abort "Pasta do projeto nao existe: '$PKGDIR'"; fi
	if [ ! -f "$PKGIDX" ]; then abort "Projeto nao possui um indice de pacotes ($PKGIDX)"; fi

	# carregar lista de pacotes do projeto
	PKGLIST=$(cat "$PKGIDX" | egrep -v '^[^a-z0-9]?[#;]')
	#	egrep -v '^#' | egrep -v '^#' | egrep -v '^;')
	if [ "x$PKGLIST" = "x" ]; then abort "O projeto possui uma lista de pacotes vazia"; fi

	# Criar as variaveis para construir o projeto
	MYNAMEIS=$PROJECTNAME
	TMPDST=/tmp/$MYNAMEIS
	PKG=$TMPDST
	HERE=/compiler/slackbuild/$MYNAMEIS

	# nome do pacote final
	PKGVERSION="$DISTRO_VERSION"			# versao da distribuicao
	PKGNAME=$MYNAMEIS-$PKGVERSION.txz		# nome do pacote do projeto (contendo todos os pacotes dele)
	PKGFQDN="$SYSBASE/$PKGNAME"				# caminho completo para o arquivo pronto

	# somente 1 pacote
	if [ "x$ONLY" != "x" ]; then _make_pkg "$argp"; exit; fi

	# informar nome do pacotes gerado por esse script
	if [ "$CMD" = "pkgname" ]; then echo "$PKGNAME"; exit; fi
	if [ "$CMD" = "pkgfqdn" ]; then echo "$PKGFQDN"; exit; fi

	# fazer analise de assinaturas de todos os scripts do pacote para ver
	# se algum script foi alterado, o que resultaria na necessidade de reconstruir o pacote
	# e o ISO/Pendrive
	PKGCHANGED=0
	SCRIPTSMD5=""
	DONELISTMD5=""
	for PKG in $PKGLIST; do
		_script="$HERE/pkg-$PKG.sh"
		_tmpdir="/tmp/$MYNAMEIS-pkg-$PKG"

		# se faltar a pasta com resultados do sub-pacote:
		if [ ! -d "$_tmpdir" ]; then
			logit2 "**** Diretorio ausente:" "$_tmpdir"
			PKGCHANGED=1
			continue
		fi

		# se faltar flag de sub-pacote pronto
		if [ ! -f "$_tmpdir/.done" ]; then
			logit2 "**** Flag ausente:" "$_tmpdir/.done"
			PKGCHANGED=2
			continue
		fi

		# se nao existir script do sub-pacote
		if [ ! -f "$_script" ]; then
			logit2 "**** Script ausente:" "$_script"
			PKGCHANGED=3
			continue
		fi

		# assinatura de scripts
		_scriptmd5=$(getmd5sum "$_script")
		SCRIPTSMD5="$SCRIPTSMD5$_scriptmd5"

		# assinatura de pacotes prontos
		# (caso mude, foi recompilado unitariamente e o pacote deve ser reconstruido)
		_donemd5=$(getmd5sum "$_tmpdir/.done")
		DONELISTMD5="$DONELISTMD5$_donemd5"

	done

	# Adicionar md5 da lista de pacotes
	IDXMD5=$(getmd5sum $PKGIDX)
	SCRIPTSMD5="$SCRIPTSMD5$IDXMD5"

	# se o pacote nao esta criado em cache
	if [ ! -f "$PKGFQDN" ]; then
		logit2 "**** Pacote ausente:" "$PKGFQDN"
		PKGCHANGED=4
	fi

	# diretorio de uniao dos pacotes nao existe
	[ -d "$TMPDST" ] || PKGCHANGED=5

	# verificar md5 anterior dos scripts
	PKGSIGFILE="/tmp/scripts-$MYNAMEIS.md5"
	PKGMD5=$(head -1 "$PKGSIGFILE" 2>/dev/null)
	if [ "$PKGMD5" = "$SCRIPTSMD5" ]; then
		#logit2 "- Cache de scripts" "OK"
		true
	else
		#logit2 "- Cache de scripts" "ERR - alteracao detectada"
		PKGCHANGED=6
	fi

	# verificar md5 anterior de assinaturas prontas
	DONESIGFILE="/tmp/dones-$MYNAMEIS.md5"
	DONESMD5=$(head -1 "$DONESIGFILE" 2>/dev/null)
	if [ "$DONESMD5" = "$DONELISTMD5" ]; then
		#logit2 "- Cache de pkt prontos" "OK"
		true
	else
		#logit2 "- Cache de pkt prontos" "ERR - alteracao detectada"
		#logit2 "DONESMD5....:" "$DONESMD5"
		#logit2 "DONELISTMD5.:" "$DONELISTMD5"
		PKGCHANGED=7
	fi
	# modo new ou force
	[ "$RENEW" = "1" ] && PKGCHANGED=8
	[ "$FORCE" = "1" ] && PKGCHANGED=9
	[ "$DEVELOP" = "1" ] && PKGCHANGED=10

	# evitar re-trabalho
	if [ "$FORCE" = "1" -o "$DEVELOP" = "1" -o "$RENEW" = "1" ]; then rm -f "$PKGFQDN" 2>/dev/null; fi
	if [ "$CMD" != "duptest" ]; then
		if [ "$PKGCHANGED" = "0" ]; then
			okquit "Pacote $PKGFQDN ja esta pronto, remova-o para compilar novamente"
		fi
	fi
	logit2 "Assinatura de pacote em cache:" "$PKGCHANGED"

#***************************------------------------ CONSTRUIR PACOTES DO PROJETO --------------------*********************************

	# limpar output (PROBLEMA: pacotes como do kernel serao prejudicados - SEM CACHE DE COMPILADO)
	#logit2 "Limpando diretorio de trabalho" "(evitar disco cheio, aguarde)"
	#clsdir "$OUTPUTDIR"

	# Preparar pasta vazia
	clsdir "$TMPDST"
	cdfolder $HERE
	for PKG in $PKGLIST; do
		# palavra magica
		# - nao gerar pacote
		if [ "$PKG" = "@nopkg" ]; then NOPKG=1; continue; fi
		# - forcar geracao de pacotes
		if [ "$PKG" = "@force" ]; then FORCE=1; continue; fi

		# Pacote
		_make_pkg "$PKG"
	done

	# nao gerar pacote, parar aqui
	if [ "$NOPKG" = "1" ]; then exit; fi

#***************************------------------------ ANALISE DE DUPLICACAO --------------------*********************************
#
#
#	logit2 "RESULTREGS:" "$RESULTREGS";exit

	# Dups
	/compiler/projects/myscripts/duptester.sh $RESULTDIRS || abort "Incapaz de criar o pacote, duplicacoes encontradas."

	# Reunir todos os pacotes
	# 1 - conferir arquivos duplicados
	# 2 - concatenar tudo
	makedir "$TMPDST/install"
	for rreg in $RESULTREGS; do
		pkgname=$(strcut -s "$rreg" -n 1)
		pkgdir=$(strcut -s "$rreg" -n 2)
		pkgdoi="$pkgdir/install/doinst.sh"
		pkgvinst="$TMPDST/install/doinst-$pkgname.sh"

		echoc -c cyan "CONCATENANDO PROJETOS :: $pkgdir"

		# Verificar doinst.sh
		if [ -f "$pkgdoi" ]; then
			# Copiar adicionando nome.
			vitalcp "$pkgdoi" "$pkgvinst"
			chmod +x "$pkgvinst"
			logita "$pkgname: Instalador $pkgvinst"
		fi

		# copiar doinst local para focalizado
		rsync -rap $pkgdir/ $TMPDST/
	done

	# nao exist '/install/doinst.sh' geral.
	rm -f "$TMPDST/install/doinst.sh" 2>/dev/null

	logit2 "Diretorio final:" "$TMPDST"

	# Juntar arquivos .new, .sets, .deletes
	# - limpar
	echo -n > "$TMPDST/install/news"
	echo -n > "$TMPDST/install/sets"
	echo -n > "$TMPDST/install/deletes"
	# - Consolidar (unir)
	for PKG in $PKGLIST; do
		_newsfile="/tmp/news-$MYNAMEIS-$PKG"
		_setsfile="/tmp/sets-$MYNAMEIS-$PKG"
		_deletesfile="/tmp/deletes-$MYNAMEIS-$PKG"

		# - NEWS
		if [ -f "$_newsfile" ]; then
			logit2 "$PKG -> NEWS-FILE:" "$_newsfile"
			cat "$_newsfile" >> "$TMPDST/install/news"
		fi

		# - SETS
		if [ -f "$_setsfile" ]; then
			logit2 "$PKG -> SETS-FILE:" "$_setsfile"
			cat "$_setsfile" >> "$TMPDST/install/sets"
		fi

		# - DELETES
		if [ -f "$_deletesfile" ]; then
			logit2 "$PKG -> SETS-FILE:" "$_deletesfile"
			cat "$_deletesfile" >> "$TMPDST/install/deletes"
		fi
	done
	# - sem arquivos vazios
	[ -s "$TMPDST/install/news" ] || rm -f "$TMPDST/install/news" 2>/dev/null
	[ -s "$TMPDST/install/sets" ] || rm -f "$TMPDST/install/sets" 2>/dev/null
	[ -s "$TMPDST/install/deletes" ] || rm -f "$TMPDST/install/deletes" 2>/dev/null


#--------------------------------------------------- FECHAR PACOTE

	# (apenas apos terminar de compilar tudo)
	# - salvar nova assinatura de scripts 
	echo "$SCRIPTSMD5" > $PKGSIGFILE

	# - salvar nova assinatura de pacotes prontos
	#   ** Temos que ler as assinaturas novamente, pois mudaram apos recompilacoes
	DONELISTMD5=""
	for PKG in $PKGLIST; do
		_tmpdir="/tmp/$MYNAMEIS-pkg-$PKG"

		# ignorar falhas
		if [ ! -d "$_tmpdir" ]; then continue; fi
		if [ ! -f "$_tmpdir/.done" ]; then continue; fi

		_donemd5=$(getmd5sum "$_tmpdir/.done")
		DONELISTMD5="$DONELISTMD5$_donemd5"
	done
	echo "$DONELISTMD5" > $DONESIGFILE


	# EMPACOTAR
	logit "Empacotando..."

	# Obter newsfile - cadastro de arquivos novos
	if [ "x$NEWSLIST" != "x" ]; then

		# garantir existencia do diretorio install
		idir="$TMPDST/install"
		mkdir -p "$idir"

		# Unificar todos os novos arquivos opcionais
		nfile="$idir/news"
		cat $NEWSLIST > $nfile

	fi


	if [ "$DEVELOP" = "1" ]; then
		rm -f "$PKGFQDN"
		echo
		echoc -c green -l " :: MODO DESENVOLVIMENTO ::"
		echoc -c green    " ::    Pacote removido   ::"
		echo
		exit

	fi

	# fazer pacote .txz
	closepkg "$PKGFQDN" "$TMPDST" no

	logitp "CONCLUIDO: $MYNAMEIS em $TMPDST"











