#!/bin/sh

. /etc/setup/vars.sh
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/etc/setup"

	# Funcoes
	_delfile(){ rm -f "$1" 2>/dev/null; }

	# codigo de retorno
	STDNO=0

	# acao pos-menu principal
	ACTION=none

#----------------------------------------------------- scripts pre-instalacao

	cd "/etc/setup"
	for ss in ??-*; do
		cd "/etc/setup"
		/bin/sh "$ss"; STDNO="$?"
		# tudo certo
		if [ "$STDNO" = "0" ]; then continue; fi
		# problema
		/bin/sh /etc/setup/failure.sh
		break
	done

#----------------------------------------------------- instalador

	if [ "$STDNO" = "0" ]; then

		# Menu principal
		while [ 0 ]; do
			_delfile "/tmp/menu-main-choice"
			dialog --title "$DISTRO_TITLE" \
			--menu \
			"Bem-vindo ao Slackmini.\nEscolha uma opcao e tecle ENTER.\n" 10 56 9 \
				"INSTALAR"			"Instalar o Slackmini neste servidor" \
				"REBOOT"			"Reiniciar o servidor" \
				"SAIR"				"Sair do instalador e usar o shell" 2> /tmp/menu-main-choice; RET="$?"

			#--	"REPARAR"			"Reparar uma instalacao danificada neste servidor" \

			if [ ! $RET = 0 ]; then echo "Falha no menu. Tente novamente"; sleep 1; continue; fi
			MAINSELECT=$(cat /tmp/menu-main-choice)

			# Executar script de acordo com a escolha
			#
			# INSTALAR
			#
			if [ "$MAINSELECT" = "INSTALAR" ]; then
				# encontrar pacotes
				sh /etc/setup/installer-source-iso.sh; STDNO="$?"

				# encontrar discos, formatar e montar
				if [ "$STDNO" = "0" ]; then sh /etc/setup/installer-hdd-prepare.sh format; STDNO="$?"; fi

				# instalar pacotes
				if [ "$STDNO" = "0" ]; then sh /etc/setup/installer-pkg-install.sh; STDNO="$?"; fi

				# ativar boot lilo e fstab
				if [ "$STDNO" = "0" ]; then sh /etc/setup/installer-boot-install.sh; STDNO="$?"; fi

				# finalizar a instalacao
				if [ "$STDNO" = "0" ]; then sh /etc/setup/installer-finish.sh; fi

				# tudo certo
				if [ "$STDNO" = "0" ]; then ACTION=reboot; break; fi

				# Erro no instalador
				logit "Erro $STDNO no instalador."
				ACTION=shell
				break

			fi

			# REPARAR
			if [ "$MAINSELECT" = "REPARAR" ]; then
				sh /etc/setup/installer-repair.sh repair; STDNO="$?"
				ACTION=reboot
			fi

			# REBOOT
			if [ "$MAINSELECT" = "REBOOT" ]; then
				ACTION=reboot
				break
			fi

			# SAIR para o shell
			if [ "$MAINSELECT" = "SAIR" ]; then
				ACTION=shell
				break
			fi

			# O modo de instalacao/recuperacao informa o STDNO, verificar
			if [ "$STDNO" -ge "10" ]; then
				# Erro grave, abortar
				dialog --title "$DISTRO_TITLE" --infobox "Erro fatal.\n\nCODIGO DO ERRO: $STDNO.\n\nUm erro fatal abortou a instalacao. Reiniciando." 10 40
				ACTION=reboot
				break
			fi

		done
		# fim menu principal

	fi

#----------------------------------------------------- encerrar

	if [ "$ACTION" = "shell" ]; then STDNO=7; fi
	if [ "$ACTION" = "reboot" ]; then

		# finalizar
		/bin/sh /etc/setup/finish.sh

		# reiniciar
		/bin/sh /etc/setup/reboot.sh

		STDNO=0
	fi

	exit $STDNO
















