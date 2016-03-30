
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void help_str_repeat(){
	printf("Use: str_repeat (string) (num)\n");
	exit(1);
}

//int main(const int argc, const char **argv){
int main_str_repeat(const char *progname, const int argc, const char **argv){
	register int i = 0;
    int rcount = 1;
	char *string = NULL;
    if(argc!=3) help_str_repeat();

    // string
    string = strdup(argv[1]);

    // number
    rcount = atoi(argv[2]);
    if(rcount < 1) rcount = 1;

    for(i=0; i < rcount; i++) printf("%s", string);
    printf("\n");
	return 0;
}



















