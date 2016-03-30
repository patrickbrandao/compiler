#!/bin/sh



	# Testar se a particao ROOT e somente leitura
	READWRITE=no
	if touch /fsrwtestfile 2>/dev/null; then
		rm -f /fsrwtestfile
		READWRITE=yes
	else
		logit "Testing root filesystem status:  read-only filesystem"
	fi

	# Verificar se o final de forcar foi solicitado antes de desligar da ultima vez
	if [ -r /etc/forcefsck ]; then
		FORCEFSCK="-f"
	fi

	# Verificar sistema de arquivos ROOT (/)
	if [ ! $READWRITE = yes ]; then

		RETVAL=0
		if [ ! -r /etc/fastboot ]; then
			logit "Checking root filesystem:"
			/sbin/fsck $FORCEFSCK -C -a /
			RETVAL=$?
		fi

		# O erro 2 ou maior significa que devemos dar um reboot

		if [ $RETVAL -ge 2 ]; then

			# Um codigo de erro igual ou maior que 4 significa que
			# alguns erros nao puderam ser corrigidos. O sistema requer
			# reparacao manual e atencao do administrador.
			#
			if [ $RETVAL -ge 4 ]; then

				setcolor yellow
				echo
				echo "***********************************************************"
				echo "*** Ocorreu um erro durante a verificacao do disco.     ***"
				echo "*** Voce devera entrar no sistema e corrigir o sistema  ***"
				echo "*** de arquivos pois a situacao pode ser critica.       ***"
				echo "***                                                     ***"
				echo "*** Para cada sistema de arquivos existe um comando:    ***"
				echo "*** EXT2     -> fsck.ext2                               ***"
				echo "*** EXT3     -> fsck.ext3                               ***"
				echo "*** EXT4     -> fsck.ext4                               ***"
				echo "*** REISERFS -> fsck.reiserfs                           ***"
				echo "***********************************************************"
				echo
				setcolor

				echo "Assim que voce sair do shell, o sistema sera' reiniciado."
				echo
				PS1="repair-filesystem \#"; export PS1
				sulogin

			else # With an error code of 2 or 3, reboot the machine automatically:
				echo
				echo "*******************************************"
				echo "*** O sistema de arquivos foi algerado. ***"
				echo "*** O sistema ira' reiniciar.           ***"
				echo "*******************************************"
				echo
			fi

			# shell de debug
			if [ "a" = "b" ]; then
				export PS1='\u@\h:\w\$ '
				export PS2='> '
				export PS4='+ '
				/bin/sh

				logit "Unmounting file systems."
				/sbin/umount -a -r
				/sbin/mount -n -o remount,ro /

				logit "Rebooting system."
				sleep 2
				reboot -f
			fi

		fi

		# Remount the root filesystem in read-write mode
		logit "Remounting root device with read-write enabled."
		/sbin/mount -w -v -n -o remount /
		RWRETVAL="$?"

		if [ "$RWRETVAL" -gt "0" ] ; then
			logitr "FATAL: remount root device as read-write failed."
		fi

	else
		logit "Root filesystem already been mounted read-write. Cannot check."

	fi
	# Done checking root filesystem



