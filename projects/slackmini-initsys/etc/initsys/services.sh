#!/bin/sh

#
# Script para iniciar/parar servicos
#
# Autor: Patrick Brandao <patrickbrandao@gmail.com>
#
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/initsys"

# Variaveis
	RUNLEVEL="3"
	MODE=""
	SERVICENAME=""
	ACTION="help"
	PBYTE=""

# Run an init script:
	_execute() {
		case "$1" in
		*.sh)
			/bin/sh "$@"
			;;
		*)
			"$@"
			;;
		esac
	}
	_execute_service(){
		_es_script="/etc/init.d/$1"
		_es_action="$2"
		if [ -x "$_es_script" ]; then
			$_es_script "$ACTION"
		fi
	}

# Processar argumentos
	[ "$0" = "service" ] && MODE=service
	for arg in $@; do
		if [ "$arg" = "init" ]; then
			PBYTE="@"
			MODE="init"
			continue
		fi
		if [ "$arg" = "shutdown" ]; then
			PBYTE="&"
			MODE="shutdown"
			continue
		fi
		if [ -x "/etc/init.d/$arg" ]; then
			MODE=service
			SERVICENAME="$arg"
			continue
		fi
		[ "$arg" = "stop" -o "$arg" = "start" -o "$arg" = "restart" -o "$arg" = "status" ] && ACTION="$arg"
		[ "$arg" = "1" -o "$arg" = "2" -o "$arg" = "3" -o "$arg" = "4" -o "$arg" = "5" -o "$arg" = "6" ] && RUNLEVEL="$arg"
	done

# Nada informado o modo
	if [ "x$MODE" = "x" ]; then
		logit  "Gestao de servicos"
		logit -n "Informe o nome do servico seguido por "; echoc -c "yellow" "stop/start"
		exit
	fi

# Por modo
	# Modo servico
	if [ "x$MODE" = "xservice" ]; then
		# Servico especifico
		_execute_service "$SERVICENAME" "$ACTION"
		exit
	fi


# Modo geral?
	# Modo de boot? Rodar start em todos os servicos ativos
	if [ "x$MODE" = "xinit" -o "x$MODE" = "xshutdown" ]; then
		
		# modo init
		[ "x$MODE" = "xinit" ] && ACTION=start
		[ "x$MODE" = "xshutdown" ] && ACTION=stop
		
		cd /etc/init.d || exit 9

		# Analisar prioridades
		SLIST=""
		for _script in *; do
			if [ -x "$_script" ]; then
				_sprio=$(egrep -m1 "^#$PBYTE[0-9]{1,2}$" $_script | cut -f2 -d'@')
				[ "x$_sprio" = "x" ] && _sprio=99
				SLIST="$SLIST $_sprio:$_script"
			fi
		done

		# sem servicos
		[ "x$SLIST" = "x" ] && exit

		# ordenar
		SLIST=$(for x in $SLIST; do echo $x; done | sort -n | cut -f2 -d:)

		# executar
		for _svc in $SLIST; do
			_execute_service "$_svc" "$ACTION"
		done

	fi














