#include <stdio.h>
#include <monetary.h>

int main(int argc, char* argv[]){
char buff[51];
char *bux=buff;
int res;

res=strfmon(bux, 50, argv[1], "0");
return 0;
}
