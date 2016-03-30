#include <stdio.h>
#include <string.h>
#include <stdlib.h>



void help_is_maclinux(){
	printf("\n");
	printf("is_maclinux\n");
	printf("Verifica se os parametros estao no formato de um endereco MAC do linux\n");
	printf("Formato aceito: XX:XX:XX:XX:XX:XX\n");
	printf("\n");
	printf("Use: is_maclinux (mac-address) [mac-address] [mac-address] [...]\n");
	printf("\n");
	exit(1);
}

int main_is_maclinux(const char *progname, const int argc, const char **argv){
	int i = 0;
    if(argc<2) help_is_maclinux();

	int r = is_maclinux(argv[i]);
	return r;

}



















