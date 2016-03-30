#!/bin/sh


	# Configure ISA Plug-and-Play devices:
	[ -f /etc/isapnp.conf ] && ifexecrun "Iniciando ISA-PNP" "/sbin/isapnp" "/etc/isapnp.conf"

	