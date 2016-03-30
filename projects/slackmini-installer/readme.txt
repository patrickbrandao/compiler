
Scripts com prefixos numerados 00 a 99 a serem executados para instalar o sistema.
Devem ser executados na ordem.

Qualquer script que falhar deve cancelar a instalacao e chamar failure.sh

Pasta de destino: /etc/setup/


Arquivos utilizados durante a instalacao, o conteudo desses arquivos irao guiar a instalacao

	/tmp/method			:: Metodo de instalacao
							ISO - instalando pelo CD/DVD
							USB - instalando pelo PENDRIVE/Memoria Flash/Memoria SD
							HDD - instalando do disco
							NET - instalando pela rede (internet)
	/tmp/isodev			:: dispositivo em /dev com o sistema de arquivos de instalacao (ISO, USB, HDD, etc...)
	/tmp/idev			:: dispositivo em /dev com os sistema de arquivos destinatario (IDE, SATA, SAS, SCSI, FLASH)
	/tmp/partitions		:: lista de particoes (ID:tipo:/dev/xxxx:mount), ID da particao, tipo: extX ou swap, ponto de montagem
	/tmp/srcdir			:: diretorio onde os arquivos (pacotes) estao dispostos (arquivos .txz e .md5)
	/tmp/pkglist		:: lista de pacotes a serem instalados (arquivos .txz)

	/tmp/pdn-dir		:: Diretorio de montagem do sistema ISO (dvd/cd)
	/tmp/root-dir		:: Diretorio de montagem do sistema final -> /
	/tmp/boot-dir 		:: Diretorio de montagem do sistema final -> /boot
	/tmp/store-dir		:: Diretorio de montagem do sistema final -> /storage

	/tmp/swap-dev		:: Particao (/dev/xxxx) da SWAP
	/tmp/root-dev		:: Particao (/dev/xxxx) do root (/)
	/tmp/boot-dev		:: Particao (/dev/xxxx) do root (/boot)
	/tmp/store-dev		:: Particao (/dev/xxxx) do storage (/storage)


Outros arquivos:
	inittab				:: Colocar em /etc/inittab do sistema initrd, contem ordem de scripts e run-leves





Ordem dos scripts:

	1 - start.sh:
		1.1 - xx-??????.sh : scripts de pre-execucao da instalacao (licenca, boas vindas, etc...)
		1.2 - ao escolher INSTALAR:

			1.2.1 - /etc/setup/source-iso.sh
			1.2.2 - /etc/setup/hdd-prepare.sh
			1.2.3 - /etc/setup/pkg-install.sh
			1.2.4 - /etc/setup/boot-install.sh










