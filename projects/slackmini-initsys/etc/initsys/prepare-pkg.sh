#!/bin/sh

	# - primeiro instalar pacotes na fila
	/usr/sbin/expkg "bootinstall"

	# - segundo executar scripts de eventos necessarios pelos pacotes
	/usr/sbin/expkg "bootevents"
	
