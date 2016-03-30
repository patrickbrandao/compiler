
#
#       ******************* LEIA OS FONTES **********************
#

Pacotes principais
		
	- baseapps
		aplicativos de uso geral

	- baseutils
		utilitarios e ferramentas

	- basenet
		binarios e programas de rede (iproute2, ifconfig, traceroute, ping, etc...)

	- baselinux
		base do linux: diretorios principais, bibliotecas e arquivos vitais (evitar enchear, parte do initrd)

	- outside
		Pacotes que compilam programas que nao vao participar da distribuicao final, mas que fabricam
		bibliotecas e binarios vitais para a compilacao ou construcao de pacotes oficiais

Programas extras

	basefront
		Aplicacoes principais para front-end com o usuario

	basenetapps
		Aplicacoes de rede

	basedb
		Aplicacoes do banco de dados

	basetools
		Ferramentas


Instrucoes

	1 - compiler alguns pacotes que sao necessarios para os scripts compiladores seguintes:
		# /compiler/projects/toolbox/_make.sh
		# /compiler/projects/myscripts/_make.sh

	2 - compile os pacotes principais, alguns deles podem afetar o
		sistema atual (glibc, openssl, opensshd) e causar desconexao, volte e continue.

		# /compiler/slackbuild/make.sh

	3 - os pacotes serao gerados em /compiler/packages/

	4 - faca upload para o site

/usr/lib64/libstdc++.so.6.0.21


/lib64/libdb-4.4.so
/lib64/libgpm.so.2.1.0
/lib64/libpcre.so.1.2.6
/lib64/libpcreposix.so.0.0.3
/lib64/libpopt.so.0.0.0
/usr/lib64/libglib-2.0.so.0.4600.2
/usr/lib64/libmm.so.14.0.22
/usr/lib64/libmpfr.so.4.1.3
/usr/lib64/libstdc++.so.6.0.21
/usr/lib64/libusb-1.0.so.0.1.0










