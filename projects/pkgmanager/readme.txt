
# Gerenciador de pacotes

Comandos:

	fxpkg - verificar pacote instalado procurando por inconsistencias, caso haja alguma ele avisara, com a opcao --repair ele pode reinstalar o pacote corrompido

	rxpkg - remover pacote instalado, informe o nome do pacote

	ixpkg - instalar pacote, informe o caminho do arquivo que deseja instalar

	uxpkg - atualizar pacote (ou pacotes)

	sxpkg - listar pacotes e seus repositorios

	expkg - Executar eventos de boot e shutdown dos pacotes

Pastas:

	/var/log/packages/
		Contem os arquivos com o nome dos pacotes instalados, seus conteudos sao a lista de pacotes que eles instalaram

	/var/log/packages/.sig/
		Contem os arquivos com o nome dos pacotes instalados, seus conteudos sao a lista de MD5 dos arquivos, sao utlizados pelo fxpkg

	/var/lib/packages/.events/
		Scripts de eventos para cada pacote
			doinst-APPNAME.sh 		- script de instalador executado pelo ixpkg
			onboot-APPNAME.sh 		- script de execucao durante o boot
			onshutdown-APPNAME.sh 	- script de execucao durante o desligamento
			ondelete-APPNAME.sh		- script de execucao durante a desinstalacao do pacote
			onrepair-APPNAME.sh		- script de execucao durante a reparacao do pacote (arquivos corrompidos detectados)

	/var/lib/packages/
		Contem os pacotes que foram instalados, cada arquivo e' o pacote original.
		Todo arquivo deve possuir seu equivalente com extencao .md5,
			exemplo: baselibs-1.0.txz deve possuir um arquivo baselibs.1.0.md5, o conteudo deve ser 32 bytes do MD5 do arquivo
			para comparacao com update. Quando o arquivo txz existir, o md5 deve ser comparado e atualizado.
			O md5 sera usado para comparacao com versao remota (deteccao de update)

Arquivos remotos no site
	
	Dados de distribuicoes
		downloads.slackmini.com.br/packages/V.N/

			Onde V e' a versao principa, N e' a sub-versao

			Arquivos:
				-> index.md5			Lista de MD5 e nome completo dos pacotes, exemplo:
										b1dc7292b66c26482d49da6a0e10d45d kernel-1.0.txz

				-> upgrade.sh			Script para realizar upgrade para a proxima versao



