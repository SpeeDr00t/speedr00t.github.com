#include <stdio.h>
#include <string.h>

void main() {

  char password[128];
  char cleartext[128];
  int	 i;

  // input the sniffed hex values here
  // Encrypted example of the 'aaaaa' password
  password[0]=0xca;
  password[1]=0xab;
  password[2]=0xcb;
  password[3]=0xa8;
  password[4]=0xca;
  password[5]='\0';

	cleartext[0]=0xca-password[0]+0x61;
	for (i=1;i<strlen(password);i++) 
	  cleartext[i] = password[i-1] ^ password[i] ^ i-1;
	
	cleartext[strlen(password)]='\0';

	printf("password is %s \n",cleartext);

}
